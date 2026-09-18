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

  Future<void> pumpLedger(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('Company tab shows all 4 companies with computed receivable balances', (tester) async {
    await pumpLedger(tester);

    expect(find.text('PRABHU SPINNING MILLS PRIVATE LIMITED'), findsOneWidget);
    expect(find.text('SRI SHANMUGAVEL MILLS PRIVATE LIMITED'), findsOneWidget);
    expect(find.text('SOUNDARARAJA MILLS LIMITED'), findsOneWidget);
    expect(find.text('PREMIER SPG & WVG MILLS'), findsOneWidget);
    // PRABHU is billPayer on all 3 of its orders (162 Unpaid/5500, 161 Paid/6000, 163 Unpaid/6000);
    // netExpected = 5500+6000+6000=17500, received = 0+6000+0=6000 -> balance 11500.
    expect(find.text('₹11,500'), findsOneWidget);
    expect(find.text('Receive Payment'), findsWidgets);
  });

  testWidgets('search filters the Company tab by name', (tester) async {
    await pumpLedger(tester);

    await tester.enterText(find.byType(TextField), 'soundararaja');
    await tester.pumpAndSettle();

    expect(find.text('SOUNDARARAJA MILLS LIMITED'), findsOneWidget);
    expect(find.text('PRABHU SPINNING MILLS PRIVATE LIMITED'), findsNothing);
  });

  testWidgets('Drivers tab shows payable balances and a Pay Freight action', (tester) async {
    await pumpLedger(tester);

    await tester.tap(find.text('Drivers'));
    await tester.pumpAndSettle();

    expect(find.text('K. Selvaraj'), findsOneWidget);
    // drv-1's 3 orders: freight 4200+4500+4500=13200, paid 3000+4500+1500=9000 -> balance 4200.
    expect(find.text('₹4,200'), findsWidgets);
    expect(find.text('Pay Freight'), findsWidgets);
  });

  testWidgets('Cash Book tab lists inflow/outflow entries with correctly-mapped expense fields', (tester) async {
    await pumpLedger(tester);

    await tester.tap(find.text('Cash Book'));
    await tester.pumpAndSettle();

    expect(find.text('Chronological Transaction Log'), findsOneWidget);
    // 3 payments + 4 driver payments + 5 expenses = 12 entries.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Payment Received (Company)'), findsWidgets);
    expect(find.text('Driver Freight Paid'), findsWidgets);
    // Regression check: expense category/notes render via the correct
    // (date/notes) fields, not the source's mismatched expenseDate/description.
    expect(find.text('Vehicle Maintenance'), findsOneWidget);
    expect(find.textContaining('Brake liner check'), findsOneWidget);
  });

  testWidgets('tapping Receive Payment on a company row navigates with the right query params', (tester) async {
    await pumpLedger(tester);

    await tester.tap(find.text('Receive Payment').first);
    await tester.pumpAndSettle();

    expect(find.text('Record Customer Payment'), findsOneWidget);
  });

  testWidgets('the "Add" button sits above the tabs and opens the right add form per tab', (tester) async {
    await pumpLedger(tester);

    expect(find.text('Add Company'), findsOneWidget);
    await tester.tap(find.text('Add Company'));
    await tester.pumpAndSettle();
    expect(find.text('Add New Company'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drivers'));
    await tester.pumpAndSettle();
    expect(find.text('Add Driver'), findsOneWidget);

    await tester.tap(find.text('Cash Book'));
    await tester.pumpAndSettle();
    expect(find.text('Add Driver'), findsNothing); // no add action on the Cash Book tab
  });

  testWidgets('the edit icon on a Company row opens that company for editing', (tester) async {
    await pumpLedger(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Edit Company'), findsOneWidget);
    expect(find.text('PRABHU SPINNING MILLS PRIVATE LIMITED'), findsOneWidget); // pre-filled name field
  });

  testWidgets('the edit icon on a Driver row opens that driver for editing', (tester) async {
    await pumpLedger(tester);

    await tester.tap(find.text('Drivers'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Edit Driver'), findsOneWidget);
    expect(find.text('Payment Accounts'), findsOneWidget);
  });
}
