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

  Future<void> pumpBillPreview(WidgetTester tester, String orderId) async {
    tester.view.physicalSize = const Size(900, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    (app.routerConfig! as GoRouter).push('/orders/$orderId/bill');
    await tester.pumpAndSettle();
  }

  testWidgets('renders the bill with LR number, parties, goods line, and amount in words', (tester) async {
    await pumpBillPreview(tester, 'ord-kst-162');

    expect(find.textContaining('KALAVATHI SELVARAJ TRANSPORT'), findsWidgets); // header + signature line
    expect(find.text('PRABHU SPINNING MILLS PRIVATE LIMITED'), findsWidgets);
    expect(find.text('ECO JUTE P LTD'), findsWidgets);
    // Vehicle number is rendered inside a Text.rich span (VEHICLE NO: + value).
    expect(find.textContaining('TN30Y4407', findRichText: true), findsWidgets);
    expect(find.text('55 BAGS'), findsOneWidget);
    expect(find.textContaining('RUPEES', findRichText: true), findsOneWidget); // amount-in-words line
  });

  testWidgets('shows "Order record not found" for an unknown id', (tester) async {
    await pumpBillPreview(tester, 'nonexistent-id');
    expect(find.text('Order record not found'), findsOneWidget);
  });

  testWidgets('toggling to Ledger & Profit shows the margins breakdown panel', (tester) async {
    await pumpBillPreview(tester, 'ord-kst-162');

    expect(find.text('Trip Ledger & Margins Breakdown'), findsNothing);
    await tester.tap(find.text('Ledger & Profit'));
    await tester.pumpAndSettle();

    expect(find.text('Trip Ledger & Margins Breakdown'), findsOneWidget);
    // driverFreight 4200 + otherTransportExpense 200 = 4400
    expect(find.text('₹4,400'), findsOneWidget);
  });

  testWidgets('deleting from the toolbar removes the order and returns to the Orders list', (tester) async {
    await pumpBillPreview(tester, 'ord-kst-162');

    await tester.tap(find.byTooltip('Delete this Order'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Transport Order'), findsOneWidget);

    await tester.tap(find.text('Yes, Delete Order'));
    await tester.pumpAndSettle();

    expect(ordersBox.containsKey('ord-kst-162'), isFalse);
    expect(find.text('Showing 4 orders'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // flush deleteOrder's toast timer
  });
}
