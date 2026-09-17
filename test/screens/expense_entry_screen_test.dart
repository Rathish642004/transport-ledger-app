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

  Future<GoRouter> pumpExpenseEntry(WidgetTester tester, {String? query}) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;
    router.push('/expense${query != null ? '?$query' : ''}');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('saving with defaults records the expense with correctly-mapped fields', (tester) async {
    await pumpExpenseEntry(tester);

    final before = expensesBox.length;
    await tester.tap(find.textContaining('Save Expense of'));
    await tester.pumpAndSettle();

    expect(expensesBox.length, before + 1);
    final saved = expensesBox.values.firstWhere((e) => e.amount == 1500);
    // Regression check for the source's field-name mismatch
    // (expenseDate/description/receiptAttachment vs date/notes/receiptAttachmentName).
    expect(saved.date, isNotEmpty);
    expect(saved.notes, 'Hamali paid to 4 labourers for unloading 500 bags');
    expect(saved.category.jsonValue, 'Loading Labour');
    expect(find.text('Showing 5 orders'), findsNothing); // sanity: didn't land on Orders

    await tester.pump(const Duration(seconds: 4)); // flush addExpense's toast timer
  });

  testWidgets('linking to an order via the initial orderId does NOT auto-fill vehicle/driver '
      '(matches the source: only the dropdown onChange does that), and saving navigates to Order Details', (tester) async {
    await pumpExpenseEntry(tester, query: 'orderId=ord-kst-160');

    // Vehicle stays at the hardcoded default — the source only auto-fills
    // vehicle/driver from `handleOrderChange`, which the initial `orderId`
    // prop never triggers.
    expect(find.text('MH-04-GP-8841'), findsOneWidget);

    await tester.tap(find.textContaining('Save Expense of'));
    await tester.pumpAndSettle();

    final saved = expensesBox.values.firstWhere((e) => e.orderId == 'ord-kst-160');
    expect(saved.vehicleNumber, 'MH-04-GP-8841');
    expect(find.text('KST/27/160'), findsWidgets); // landed on OrderDetailsScreen

    await tester.pump(const Duration(seconds: 4)); // flush addExpense's toast timer
  });

  testWidgets('validation blocks a zero amount with a warning toast', (tester) async {
    await pumpExpenseEntry(tester);

    await tester.enterText(find.widgetWithText(TextField, '1500'), '0');
    await tester.pumpAndSettle();

    final before = expensesBox.length;
    await tester.tap(find.textContaining('Save Expense of'));
    await tester.pumpAndSettle();

    expect(expensesBox.length, before);
    expect(find.text('Please enter a valid expense amount'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // flush toast timer, if any tests follow
  });
}
