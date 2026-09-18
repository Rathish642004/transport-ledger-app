import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/seed_data.dart';
import 'package:flutter_app/models/enums.dart';
import 'package:flutter_app/models/expense_record.dart';
import 'package:flutter_app/providers/companies_provider.dart';
import 'package:flutter_app/providers/customers_provider.dart';
import 'package:flutter_app/providers/drivers_provider.dart';
import 'package:flutter_app/providers/expenses_provider.dart';
import 'package:flutter_app/providers/profile_provider.dart';
import 'package:flutter_app/providers/toast_provider.dart';
import 'package:flutter_app/storage/hive_boxes.dart';
import 'package:flutter_app/storage/storage_keys.dart';

import '../test_helpers/hive_test_env.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    // ProfileNotifier.build() reads the box directly, so it must be seeded.
    await profileBox.put(StorageKeys.singleValueKey, initialProfile);
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  group('CompaniesNotifier.saveCompany', () {
    test('adds a new company with zeroed aggregate stats', () {
      final company = container.read(companiesProvider.notifier).saveCompany(
            name: 'New Co',
            contactPerson: 'A',
            phone: '111',
            address: 'addr',
            city: 'city',
          );
      expect(company.id, isNotEmpty);
      expect(company.totalOrders, 0);
      expect(container.read(companiesProvider), contains(company));
    });

    test('editing preserves aggregate stats untouched by the form', () {
      final created = container.read(companiesProvider.notifier).saveCompany(
            name: 'New Co',
            contactPerson: 'A',
            phone: '111',
            address: 'addr',
            city: 'city',
          );
      // Simulate a prior payment having bumped totalReceived/outstandingBalance.
      container.read(companiesProvider.notifier).applyPaymentReceived('New Co', 300);
      final afterPayment = container.read(companiesProvider).firstWhere((c) => c.id == created.id);
      expect(afterPayment.totalReceived, 300);

      final edited = container.read(companiesProvider.notifier).saveCompany(
            id: created.id,
            name: 'New Co Renamed',
            contactPerson: 'B',
            phone: '222',
            address: 'addr2',
            city: 'city2',
          );
      expect(edited.id, created.id);
      expect(edited.name, 'New Co Renamed');
      expect(edited.totalReceived, 300); // untouched by the edit form
    });
  });

  group('CustomersNotifier.saveCustomer', () {
    test('adds then edits by id', () {
      final created = container.read(customersProvider.notifier).saveCustomer(
            name: 'New Cust',
            contactPerson: 'A',
            phone: '111',
            deliveryAddress: 'addr',
            city: 'city',
          );
      final edited = container.read(customersProvider.notifier).saveCustomer(
            id: created.id,
            name: 'New Cust Renamed',
            contactPerson: 'B',
            phone: '222',
            deliveryAddress: 'addr2',
            city: 'city2',
          );
      expect(edited.id, created.id);
      expect(edited.name, 'New Cust Renamed');
    });
  });

  group('DriversNotifier.saveDriver', () {
    test('upper-cases the vehicle number only when adding', () {
      final created = container.read(driversProvider.notifier).saveDriver(
            name: 'New Driver',
            phone: '111',
            vehicleNumber: 'tn00x0000',
          );
      expect(created.vehicleNumber, 'TN00X0000');

      final edited = container.read(driversProvider.notifier).saveDriver(
            id: created.id,
            name: 'New Driver',
            phone: '111',
            vehicleNumber: 'tn11y1111', // lower-case on edit is passed through as-is
          );
      expect(edited.vehicleNumber, 'tn11y1111');
    });
  });

  group('DriversNotifier payout accounts', () {
    test('addPayoutAccount appends a bank-based account with a derived label', () {
      final driver = container.read(driversProvider.notifier).saveDriver(
            name: 'Payout Test Driver',
            phone: '111',
            vehicleNumber: 'TN00X0000',
          );

      container.read(driversProvider.notifier).addPayoutAccount(
            driverId: driver.id,
            bankName: 'SBI',
            accountNumber: '12345',
            ifscCode: 'SBIN0001',
          );

      final updated = container.read(driversProvider).firstWhere((d) => d.id == driver.id);
      expect(updated.payoutAccounts, hasLength(1));
      expect(updated.payoutAccounts.single.label, 'SBI - 12345');
    });

    test('addPayoutAccount with only a UPI ID labels the account with it', () {
      final driver = container.read(driversProvider.notifier).saveDriver(
            name: 'UPI Driver',
            phone: '111',
            vehicleNumber: 'TN00X0001',
          );

      container.read(driversProvider.notifier).addPayoutAccount(driverId: driver.id, upiId: 'driver@ybl');

      final updated = container.read(driversProvider).firstWhere((d) => d.id == driver.id);
      expect(updated.payoutAccounts.single.label, 'driver@ybl');
    });

    test('removePayoutAccount removes only the targeted account', () {
      final notifier = container.read(driversProvider.notifier);
      final driver = notifier.saveDriver(name: 'Two Accounts Driver', phone: '111', vehicleNumber: 'TN00X0002');
      notifier.addPayoutAccount(driverId: driver.id, upiId: 'first@ybl');
      notifier.addPayoutAccount(driverId: driver.id, upiId: 'second@ybl');
      final toRemove = container.read(driversProvider).firstWhere((d) => d.id == driver.id).payoutAccounts.first;

      notifier.removePayoutAccount(driverId: driver.id, accountId: toRemove.id);

      final updated = container.read(driversProvider).firstWhere((d) => d.id == driver.id);
      expect(updated.payoutAccounts, hasLength(1));
      expect(updated.payoutAccounts.single.label, 'second@ybl');
    });
  });

  test('ExpensesNotifier.addExpense assigns id/expenseNumber', () {
    final expense = container.read(expensesProvider.notifier).addExpense(
          const ExpenseRecord(
            id: '',
            expenseNumber: '',
            date: '2026-01-01',
            category: ExpenseCategory.fuel,
            amount: 500,
            paidTo: 'Pump',
            paymentMethod: PaymentMethod.cash,
            notes: '',
          ),
        );
    expect(expense.id, isNotEmpty);
    expect(expense.expenseNumber, startsWith('EXP-2026-'));
    expect(container.read(expensesProvider), contains(expense));
  });

  test('ProfileNotifier.updateProfile persists and updates state', () {
    final original = container.read(profileProvider);
    final updated = original.copyWith(businessName: 'Renamed Transport Co');

    container.read(profileProvider.notifier).updateProfile(updated);

    expect(container.read(profileProvider).businessName, 'Renamed Transport Co');
  });

  group('ToastNotifier', () {
    test('show appends a toast and dismiss removes it by id', () {
      container.read(toastProvider.notifier).show('Hello', ToastType.info);
      expect(container.read(toastProvider), hasLength(1));

      final id = container.read(toastProvider).first.id;
      container.read(toastProvider.notifier).dismiss(id);
      expect(container.read(toastProvider), isEmpty);
    });
  });
}
