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

  testWidgets('linking to a specific company pre-fills its outstanding balance and open orders', (tester) async {
    await pumpReceivePayment(tester, query: 'partyType=Company&partyId=comp-1');

    // comp-1 (PRABHU SPINNING MILLS): ord-kst-161 paid in full (6000/6000),
    // ord-kst-162 (5500, unpaid) and ord-kst-163 (6000, unpaid) still open ->
    // outstanding = 5500 + 6000 = 11500.
    expect(find.text('₹11,500'), findsWidgets);
    final amountField = tester.widget<TextField>(find.widgetWithText(TextField, '11500'));
    expect(amountField.controller?.text, '11500');
    expect(find.textContaining('KST/27/162'), findsOneWidget);
    expect(find.textContaining('KST/27/163'), findsOneWidget);
  });

  testWidgets('submitting the full due amount pays off every open order for that party (FIFO)', (tester) async {
    await pumpReceivePayment(tester, query: 'partyType=Company&partyId=comp-1');

    await tester.tap(find.text('Confirm & Record ₹11,500'));
    await tester.pumpAndSettle();

    expect(paymentsBox.values.any((p) => p.partyId == 'comp-1' && p.amountReceived == 11500), isTrue);
    expect(ordersBox.get('ord-kst-162')!.paymentStatus.jsonValue, 'Paid');
    expect(ordersBox.get('ord-kst-163')!.paymentStatus.jsonValue, 'Paid');

    await tester.pump(const Duration(seconds: 4)); // flush receivePayment's toast timer
  });

  testWidgets('a partial payment settles the oldest open order first and leaves the newer one open', (tester) async {
    await pumpReceivePayment(tester, query: 'partyType=Company&partyId=comp-1');

    // Only enough to cover the older order (ord-kst-162, orderDate 09-11),
    // not the newer one (ord-kst-163, orderDate 09-14).
    await tester.enterText(find.widgetWithText(TextField, '11500'), '5500');
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Confirm & Record'));
    await tester.pumpAndSettle();

    expect(ordersBox.get('ord-kst-162')!.paymentStatus.jsonValue, 'Paid');
    expect(ordersBox.get('ord-kst-163')!.paymentStatus.jsonValue, 'Unpaid');

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('overpaying leaves the extra as unallocated credit', (tester) async {
    await pumpReceivePayment(tester, query: 'partyType=Company&partyId=comp-1');

    await tester.enterText(find.widgetWithText(TextField, '11500'), '12000');
    await tester.pumpAndSettle();

    expect(find.textContaining('Unallocated'), findsOneWidget);
    expect(find.text('₹500'), findsWidgets);

    await tester.tap(find.textContaining('Confirm & Record'));
    await tester.pumpAndSettle();

    final receipt = paymentsBox.values.firstWhere((p) => p.partyId == 'comp-1' && p.amountReceived == 12000);
    expect(receipt.unallocatedAmount, 500);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('validation blocks a zero amount with a warning toast', (tester) async {
    await pumpReceivePayment(tester, query: 'partyType=Company&partyId=comp-1');

    await tester.enterText(find.widgetWithText(TextField, '11500'), '0');
    await tester.pumpAndSettle();

    final before = paymentsBox.length;
    await tester.tap(find.textContaining('Confirm & Record'));
    await tester.pumpAndSettle();

    expect(paymentsBox.length, before);
    expect(find.text('Please enter a valid amount received'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });
}
