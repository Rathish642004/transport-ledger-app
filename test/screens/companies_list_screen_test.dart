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

  Future<GoRouter> pumpCompanies(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;
    router.push('/companies');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('lists all 4 companies with due balances', (tester) async {
    await pumpCompanies(tester);

    expect(find.text('PRABHU SPINNING MILLS PRIVATE LIMITED'), findsOneWidget);
    expect(find.text('SRI SHANMUGAVEL MILLS PRIVATE LIMITED'), findsOneWidget);
    expect(find.text('SOUNDARARAJA MILLS LIMITED'), findsOneWidget);
    expect(find.text('PREMIER SPG & WVG MILLS'), findsOneWidget);
    // Derived live from seed orders (companyId comp-1, billPayer Company):
    // ord-kst-161 (6000, paid) + ord-kst-162 (5500, unpaid) + ord-kst-163
    // (6000, unpaid) = 17500 billed, 6000 received, 11500 outstanding.
    expect(find.text('₹11,500'), findsOneWidget);
    expect(find.text('3 Orders • 175 Bags Dispatched'), findsOneWidget);
  });

  testWidgets('search filters by name', (tester) async {
    await pumpCompanies(tester);

    await tester.enterText(find.byType(TextField), 'soundararaja');
    await tester.pumpAndSettle();

    expect(find.text('SOUNDARARAJA MILLS LIMITED'), findsOneWidget);
    expect(find.text('PRABHU SPINNING MILLS PRIVATE LIMITED'), findsNothing);
  });

  testWidgets('Add Company navigates to the add form and saving creates a new company', (tester) async {
    await pumpCompanies(tester);

    await tester.tap(find.text('Add Company'));
    await tester.pumpAndSettle();

    expect(find.text('Add New Company'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'New Test Traders');
    await tester.enterText(find.byType(TextField).at(2), '9999900000');
    await tester.enterText(find.byType(TextField).at(3), 'Plot 1, Test Estate');
    await tester.enterText(find.byType(TextField).at(4), 'Surat');
    await tester.pumpAndSettle();

    final before = companiesBox.length;
    await tester.tap(find.text('Save Company Profile'));
    await tester.pumpAndSettle();

    expect(companiesBox.length, before + 1);
    expect(companiesBox.values.any((c) => c.name == 'New Test Traders'), isTrue);
    expect(find.text('Transport Companies'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // flush saveCompany's toast timer
  });

  testWidgets('validation blocks an empty name with a warning toast', (tester) async {
    await pumpCompanies(tester);

    await tester.tap(find.text('Add Company'));
    await tester.pumpAndSettle();

    final before = companiesBox.length;
    await tester.tap(find.text('Save Company Profile'));
    await tester.pumpAndSettle();

    expect(companiesBox.length, before);
    expect(find.text('Company name is required'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });
}
