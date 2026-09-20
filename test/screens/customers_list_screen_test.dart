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

  Future<GoRouter> pumpCustomers(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;
    router.push('/customers');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('lists all 4 customers with due balances', (tester) async {
    await pumpCustomers(tester);

    expect(find.text('ECO JUTE P LTD'), findsOneWidget);
    expect(find.text('FASHION PROCESS MILL'), findsOneWidget);
    expect(find.text('SRI MURUGAN TEXTILES & SIZING'), findsOneWidget);
    expect(find.text('RAJALAKSHMI WEAVING MILLS'), findsOneWidget);
    // Every seed order is billed to the Company, not the Customer, so each
    // customer's receivable ledger is empty — this is the fix for the bug
    // where a customer-billed order's receivable used to double-count onto
    // the company too; here it correctly shows nothing is owed by customers.
    expect(find.text('₹0'), findsNWidgets(4));
    expect(find.text('0 Orders • 0 Bags Received'), findsNWidgets(4));
  });

  testWidgets('search filters by city', (tester) async {
    await pumpCustomers(tester);

    await tester.enterText(find.byType(TextField), 'erode');
    await tester.pumpAndSettle();

    expect(find.text('SRI MURUGAN TEXTILES & SIZING'), findsOneWidget);
    expect(find.text('ECO JUTE P LTD'), findsNothing);
  });

  testWidgets('Add Customer navigates to the add form and saving creates a new customer', (tester) async {
    await pumpCustomers(tester);

    await tester.tap(find.text('Add Customer'));
    await tester.pumpAndSettle();

    expect(find.text('Add Destination Customer'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'New Test Mills');
    await tester.enterText(find.byType(TextField).at(2), '9999900000');
    await tester.enterText(find.byType(TextField).at(3), 'Gala 1, Test Market');
    await tester.enterText(find.byType(TextField).at(4), 'Vashi');
    await tester.pumpAndSettle();

    final before = customersBox.length;
    await tester.tap(find.text('Save Customer'));
    await tester.pumpAndSettle();

    expect(customersBox.length, before + 1);
    expect(customersBox.values.any((c) => c.name == 'New Test Mills'), isTrue);
    expect(find.text('Destination Customers'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // flush saveCustomer's toast timer
  });

  testWidgets('validation blocks an empty name with a warning toast', (tester) async {
    await pumpCustomers(tester);

    await tester.tap(find.text('Add Customer'));
    await tester.pumpAndSettle();

    final before = customersBox.length;
    await tester.tap(find.text('Save Customer'));
    await tester.pumpAndSettle();

    expect(customersBox.length, before);
    expect(find.text('Customer name is required'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });
}
