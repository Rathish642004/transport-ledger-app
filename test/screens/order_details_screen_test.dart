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

  Future<void> pumpOrderDetails(WidgetTester tester, String orderId) async {
    tester.view.physicalSize = const Size(900, 3400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    (app.routerConfig! as GoRouter).push('/orders/$orderId');
    await tester.pumpAndSettle();
  }

  testWidgets('shows order header, charge breakdown, and profit summary from seed data', (tester) async {
    await pumpOrderDetails(tester, 'ord-kst-162');

    expect(find.text('KST/27/162'), findsWidgets);
    expect(find.textContaining('Booked on'), findsOneWidget);
    // bill: 55 bags * ₹100/bag = 5500 (gross bill, and net receivable since no TDS).
    expect(find.text('₹5,500'), findsWidgets);
    // expenses: transportation 4400 -> profit 1100.
    expect(find.text('₹1,100'), findsWidgets);
  });

  testWidgets('shows "Order not found" for an unknown id', (tester) async {
    await pumpOrderDetails(tester, 'nonexistent-id');
    expect(find.text('Order not found'), findsOneWidget);
  });

  testWidgets('Mark Completed changes the order status', (tester) async {
    await pumpOrderDetails(tester, 'ord-kst-163'); // seed status is Booked

    expect(find.text('Change Status: Booked'), findsOneWidget);
    await tester.tap(find.text('Mark Completed'));
    await tester.pumpAndSettle();

    expect(ordersBox.get('ord-kst-163')!.orderStatus.jsonValue, 'Completed');
    expect(find.text('Change Status: Completed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // flush updateOrderStatus's toast timer
  });

  testWidgets('quick-add note field adds a note and clears itself', (tester) async {
    await pumpOrderDetails(tester, 'ord-kst-162');

    await tester.enterText(find.widgetWithText(TextField, 'Add a quick note or trip update...'), 'Quick trip update');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final updated = ordersBox.get('ord-kst-162')!;
    expect(updated.notes, contains('Quick trip update'));

    final fieldText = tester.widget<TextField>(find.widgetWithText(TextField, '').first).controller?.text;
    expect(fieldText, isNot(contains('Quick trip update')));

    await tester.pump(const Duration(seconds: 4)); // flush addOrderNote's toast timer
  });

  testWidgets('delete from the danger zone removes the order and returns to the Orders list', (tester) async {
    await pumpOrderDetails(tester, 'ord-kst-162');

    await tester.ensureVisible(find.text('Delete Order').last);
    await tester.tap(find.text('Delete Order').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete Transport Order'), findsOneWidget);
    await tester.tap(find.text('Yes, Delete Order'));
    await tester.pumpAndSettle();

    expect(ordersBox.containsKey('ord-kst-162'), isFalse);
    expect(find.text('Showing 4 orders'), findsOneWidget); // back on Orders list

    await tester.pump(const Duration(seconds: 4)); // flush deleteOrder's toast timer
  });
}
