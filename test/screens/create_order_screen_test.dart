import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('creating a new order (defaults, no edits) saves it and navigates to Bill Preview', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('NEW LR TRANSPORT BOOKING'), findsOneWidget);

    final before = ordersBox.length;
    await tester.tap(find.text('Save & Generate Official Bill'));
    await tester.pumpAndSettle();

    expect(ordersBox.length, before + 1);
    expect(find.text('Standard Bill'), findsOneWidget); // real BillPreviewScreen's toolbar
    await tester.pump(const Duration(seconds: 4)); // flush createOrder's toast timer
  });

  testWidgets('opening every accordion section renders without overflow, and each closes the previous one', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Section 1 starts open.
    expect(find.text('LR Number *'), findsOneWidget);

    await tester.tap(find.text('Section 2: Bill Summary & Additional Charges'));
    await tester.pumpAndSettle();
    expect(find.text('LR Number *'), findsNothing); // section 1 closed
    expect(find.text('Total Customer Bill Amount:'), findsOneWidget);

    await tester.tap(find.text('Section 3: Driver Freight & Advance Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Total Customer Bill Amount:'), findsNothing);
    expect(find.text('Driver Balance to be Settled:'), findsOneWidget);

    await tester.tap(find.text('Section 4: Billing, TDS & Bank Terms'));
    await tester.pumpAndSettle();
    expect(find.text('Driver Balance to be Settled:'), findsNothing);
    expect(find.text('Who will pay the transport bill? *'), findsOneWidget);

    // No RenderFlex overflow anywhere in this pass (tester.takeException
    // would otherwise surface it at tearDown).
  });

  testWidgets('editing an existing order pre-fills fields and calls updateOrder, not createOrder', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.local_shipping_outlined)); // Orders tab
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first); // first card is ord-kst-162
    await tester.pumpAndSettle();

    expect(find.text('EDIT TRANSPORT LR / BILL'), findsOneWidget);
    expect(find.text('KST/27/162'), findsWidgets); // LR field is pre-filled

    final countBefore = ordersBox.length;
    await tester.tap(find.text('Update & View Bill'));
    await tester.pumpAndSettle();

    expect(ordersBox.length, countBefore); // no new order created
    expect(find.text('Standard Bill'), findsOneWidget); // landed on BillPreviewScreen
    await tester.pump(const Duration(seconds: 4)); // flush updateOrder's toast timer
  });

  testWidgets('changing bags/rate recalculates transportation charges and total bill', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '55'), '10');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Section 2: Bill Summary & Additional Charges'));
    await tester.pumpAndSettle();

    // 10 bags * 100/bag (default rate) = 1000.
    expect(find.text('Total Customer Bill Amount:'), findsOneWidget);
    expect(find.textContaining('₹1,000'), findsWidgets);
  });

  testWidgets('validation blocks saving with zero bags and shows a warning toast', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '55'), '0');
    await tester.pumpAndSettle();

    final before = ordersBox.length;
    await tester.tap(find.text('Save & Generate Official Bill'));
    await tester.pumpAndSettle();

    expect(ordersBox.length, before); // nothing saved
    expect(find.text('Please enter a valid bag quantity'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // flush the toast's auto-dismiss timer
  });
}
