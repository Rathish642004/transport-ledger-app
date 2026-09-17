import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/main.dart';
import 'package:flutter_app/storage/hive_boxes.dart';

import '../test_helpers/hive_test_env.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await openTestHive();
    await seedIfEmpty();
  });

  tearDown(() async {
    await closeTestHive(tempDir);
  });

  Future<GoRouter> pumpReceivePayment(WidgetTester tester, {String? query}) async {
    tester.view.physicalSize = const Size(900, 3400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;
    router.push('/receive-payment${query != null ? '?$query' : ''}');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('linking to a specific order pre-fills payer, balance due, and amount', (tester) async {
    await pumpReceivePayment(tester, query: 'orderId=ord-kst-162');

    // ord-kst-162: billPayer Company, totalCustomerBill 5500, amountReceived 0.
    expect(find.text('Order #KST/27/162'), findsOneWidget);
    expect(find.text('₹5,500'), findsWidgets); // gross bill + balance due
    final amountField = tester.widget<TextField>(find.widgetWithText(TextField, '5500'));
    expect(amountField.controller?.text, '5500');
  });

  testWidgets('submitting records the payment, updates the order, and navigates to Order Details', (tester) async {
    await pumpReceivePayment(tester, query: 'orderId=ord-kst-162');

    await tester.tap(find.text('Confirm & Record ₹5,500'));
    await tester.pumpAndSettle();

    expect(paymentsBox.values.any((p) => p.orderId == 'ord-kst-162' && p.amountReceived == 5500), isTrue);
    final updatedOrder = ordersBox.get('ord-kst-162')!;
    expect(updatedOrder.amountReceived, 5500);
    expect(updatedOrder.paymentStatus.jsonValue, 'Paid');
    expect(find.text('KST/27/162'), findsWidgets); // landed on OrderDetailsScreen

    await tester.pump(const Duration(seconds: 4)); // flush receivePayment's toast timer
  });

  testWidgets('validation blocks a zero amount with a warning toast', (tester) async {
    await pumpReceivePayment(tester);

    await tester.enterText(find.widgetWithText(TextField, '25000'), '0');
    await tester.pumpAndSettle();

    final before = paymentsBox.length;
    await tester.tap(find.textContaining('Confirm & Record'));
    await tester.pumpAndSettle();

    expect(paymentsBox.length, before);
    expect(find.text('Please enter a valid amount received'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('selecting "General Payment (Unlinked)" then submitting records against ord-general', (tester) async {
    await pumpReceivePayment(tester);

    // Default selection is the first available order (matches the source's
    // `initialOrderId || availableOrders[0]?.id || ''`) — explicitly switch
    // to the unlinked option via the dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('-- General Payment (Unlinked) --').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '25000'), '1000');
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Confirm & Record'));
    await tester.pumpAndSettle();

    expect(paymentsBox.values.any((p) => p.orderId == 'ord-general' && p.amountReceived == 1000), isTrue);

    await tester.pump(const Duration(seconds: 4));
  });
}
