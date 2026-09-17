import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/seed_data.dart';
import 'package:flutter_app/storage/hive_boxes.dart';
import 'package:flutter_app/storage/storage_keys.dart';

import '../test_helpers/hive_test_env.dart';

/// Uses plain `Hive.init` (no Flutter path_provider binding needed) against a
/// temp directory, then opens boxes under the same [StorageKeys] names the
/// app uses — so `ordersBox`/`seedIfEmpty`/`resetToSampleData` from
/// `storage/hive_boxes.dart` work against it exactly as they would at runtime.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await openTestHive();
  });

  tearDown(() async {
    await closeTestHive(tempDir);
  });

  test('order round-trips through a real Hive box, including nested fields', () async {
    final order = initialOrders.first;
    await ordersBox.put(order.id, order);

    final reread = ordersBox.get(order.id)!;
    expect(reread.toJson(), order.toJson());
  });

  test('seedIfEmpty populates every box from seed data', () async {
    await seedIfEmpty();

    expect(ordersBox.length, initialOrders.length);
    expect(companiesBox.length, initialCompanies.length);
    expect(customersBox.length, initialCustomers.length);
    expect(driversBox.length, initialDrivers.length);
    expect(paymentsBox.length, initialPaymentReceipts.length);
    expect(driverPaymentsBox.length, initialDriverPayments.length);
    expect(expensesBox.length, initialExpenses.length);
    expect(profileBox.get(StorageKeys.singleValueKey)!.toJson(), initialProfile.toJson());
    expect(backupBox.get(StorageKeys.singleValueKey)!.toJson(), initialBackupSettings.toJson());

    expect(ordersBox.get('ord-kst-162')!.orderNumber, 'KST/27/162');
  });

  test('seedIfEmpty does not overwrite existing data', () async {
    await seedIfEmpty();
    await ordersBox.delete('ord-kst-162');

    await seedIfEmpty();

    expect(ordersBox.containsKey('ord-kst-162'), isFalse);
    expect(ordersBox.length, initialOrders.length - 1);
  });

  test('resetToSampleData clears local changes and reseeds from scratch', () async {
    await seedIfEmpty();
    await ordersBox.put('extra-order', initialOrders.first.copyWith(id: 'extra-order'));
    await ordersBox.delete('ord-kst-162');

    await resetToSampleData();

    expect(ordersBox.length, initialOrders.length);
    expect(ordersBox.containsKey('extra-order'), isFalse);
    expect(ordersBox.containsKey('ord-kst-162'), isTrue);
  });
}
