import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/bank_account.dart';
import 'package:flutter_app/models/driver_payout_account.dart';
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

  Future<GoRouter> pumpPayDriver(WidgetTester tester, {String? query}) async {
    tester.view.physicalSize = const Size(900, 3400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;
    router.push('/pay-driver${query != null ? '?$query' : ''}');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('linking to a specific order pre-fills driver, freight, and balance', (tester) async {
    // ord-kst-162: driver drv-1 (K. Selvaraj), driverFreight 4200, driverPaidAmount 3000 -> balance 1200.
    await pumpPayDriver(tester, query: 'orderId=ord-kst-162&driverId=drv-1');

    expect(find.text('K. Selvaraj'), findsWidgets);
    expect(find.text('₹1,200'), findsWidgets); // balance payable + amount field
    final amountField = tester.widget<TextField>(find.widgetWithText(TextField, '1200'));
    expect(amountField.controller?.text, '1200');
  });

  testWidgets('submitting records the driver payment, updates the order, and navigates to Order Details', (tester) async {
    await pumpPayDriver(tester, query: 'orderId=ord-kst-162&driverId=drv-1');

    await tester.tap(find.textContaining('Confirm Driver Payment of'));
    await tester.pumpAndSettle();

    expect(driverPaymentsBox.values.any((p) => p.orderId == 'ord-kst-162' && p.amountPaid == 1200), isTrue);
    final updatedOrder = ordersBox.get('ord-kst-162')!;
    expect(updatedOrder.driverExpense.driverPaidAmount, 4200);
    expect(updatedOrder.driverExpense.driverPaymentStatus.jsonValue, 'Paid in Full');
    expect(find.text('KST/27/162'), findsWidgets); // landed on OrderDetailsScreen

    final updatedDriver = driversBox.get('drv-1')!;
    expect(updatedDriver.totalAmountPaid, 29400 + 1200);

    await tester.pump(const Duration(seconds: 4)); // flush payDriver's toast timer
  });

  testWidgets('pre-selects the driver\'s own first payout account, and lets it be changed', (tester) async {
    driversBox.put(
      'drv-1',
      driversBox.get('drv-1')!.copyWith(payoutAccounts: [
        const DriverPayoutAccount(id: 'acct-1', label: 'first@ybl', upiId: 'first@ybl'),
        const DriverPayoutAccount(id: 'acct-2', label: 'second@ybl', upiId: 'second@ybl'),
      ]),
    );
    banksBox.put('bank-1', const BankAccount(id: 'bank-1', bankName: 'SBI', accountHolderName: 'Owner', accountNumber: '111', ifscCode: 'SBIN0001', branchName: 'HQ'));

    await pumpPayDriver(tester, query: 'orderId=ord-kst-162&driverId=drv-1');

    expect(find.text('first@ybl'), findsOneWidget); // pre-selected as the driver's first account

    await tester.tap(find.byKey(const Key('driverPayoutAccountDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('second@ybl').last);
    await tester.pumpAndSettle();

    expect(find.text('second@ybl'), findsOneWidget);

    await tester.tap(find.textContaining('Confirm Driver Payment of'));
    await tester.pumpAndSettle();

    // ord-kst-162 already has seeded driver payments, so disambiguate by the
    // bank account (only this new submission sets one).
    final saved = driverPaymentsBox.values.firstWhere((p) => p.orderId == 'ord-kst-162' && p.bankAccountId == 'bank-1');
    expect(saved.driverPayoutAccountId, 'acct-2');

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('validation blocks a zero amount with a warning toast', (tester) async {
    await pumpPayDriver(tester, query: 'orderId=ord-kst-162&driverId=drv-1');

    await tester.enterText(find.widgetWithText(TextField, '1200'), '0');
    await tester.pumpAndSettle();

    final before = driverPaymentsBox.length;
    await tester.tap(find.textContaining('Confirm Driver Payment'));
    await tester.pumpAndSettle();

    expect(driverPaymentsBox.length, before);
    expect(find.text('Please enter a valid payment amount'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });
}
