import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../data/seed_data.dart';
import '../models/backup_sync_state.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/driver.dart';
import '../models/driver_payment_record.dart';
import '../models/expense_record.dart';
import '../models/hive_registrar.g.dart';
import '../models/order.dart';
import '../models/payment_receipt.dart';
import '../models/transporter_profile.dart';
import 'ordered_box.dart';
import 'storage_keys.dart';

/// Opens every Hive box the app needs and seeds first-launch sample data.
///
/// Boxes are keyed by each record's own `id` field (so `put`/`delete` map
/// directly onto the array operations `LedgerContext.tsx` does on plain
/// JS arrays). `profile` and `backupSettings` are single-value boxes keyed by
/// [StorageKeys.singleValueKey].
Future<void> initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapters();

  await Future.wait([
    Hive.openBox<Order>(StorageKeys.orders),
    Hive.openBox<Company>(StorageKeys.companies),
    Hive.openBox<Customer>(StorageKeys.customers),
    Hive.openBox<Driver>(StorageKeys.drivers),
    Hive.openBox<PaymentReceipt>(StorageKeys.payments),
    Hive.openBox<DriverPaymentRecord>(StorageKeys.driverPayments),
    Hive.openBox<ExpenseRecord>(StorageKeys.expenses),
    Hive.openBox<TransporterProfile>(StorageKeys.profile),
    Hive.openBox<BackupSyncState>(StorageKeys.backup),
    Hive.openBox<List>(StorageKeys.ordersOrder),
    Hive.openBox<List>(StorageKeys.paymentsOrder),
  ]);

  await seedIfEmpty();
}

/// First-launch seeding, and the "Reset to Sample Data" action in Settings.
Future<void> seedIfEmpty() async {
  if (ordersBox.isEmpty) {
    ordersOrderedIndex.write(initialOrders);
  }
  if (companiesBox.isEmpty) {
    await companiesBox.putAll({for (final c in initialCompanies) c.id: c});
  }
  if (customersBox.isEmpty) {
    await customersBox.putAll({for (final c in initialCustomers) c.id: c});
  }
  if (driversBox.isEmpty) {
    await driversBox.putAll({for (final d in initialDrivers) d.id: d});
  }
  if (paymentsBox.isEmpty) {
    paymentsOrderedIndex.write(initialPaymentReceipts);
  }
  if (driverPaymentsBox.isEmpty) {
    await driverPaymentsBox.putAll({for (final p in initialDriverPayments) p.id: p});
  }
  if (expensesBox.isEmpty) {
    await expensesBox.putAll({for (final e in initialExpenses) e.id: e});
  }
  if (profileBox.isEmpty) {
    await profileBox.put(StorageKeys.singleValueKey, initialProfile);
  }
  if (backupBox.isEmpty) {
    await backupBox.put(StorageKeys.singleValueKey, initialBackupSettings);
  }
}

/// Replaces box contents from a parsed backup file — `restoreBackupFromJSON`
/// in `LedgerContext.tsx:932-951`. [orders] is always replaced (the source
/// validates it's present before calling this at all); every other
/// collection is left untouched when its corresponding backup field is
/// absent, matching the source's `if (parsed.X) setX(parsed.X)` guards.
Future<void> replaceAllFromBackup({
  required List<Order> orders,
  List<Company>? companies,
  List<Customer>? customers,
  List<Driver>? drivers,
  List<PaymentReceipt>? payments,
  List<DriverPaymentRecord>? driverPayments,
  List<ExpenseRecord>? expenses,
  TransporterProfile? profile,
}) async {
  await ordersOrderedIndex.clear();
  ordersOrderedIndex.write(orders);

  if (companies != null) {
    await companiesBox.clear();
    await companiesBox.putAll({for (final c in companies) c.id: c});
  }
  if (customers != null) {
    await customersBox.clear();
    await customersBox.putAll({for (final c in customers) c.id: c});
  }
  if (drivers != null) {
    await driversBox.clear();
    await driversBox.putAll({for (final d in drivers) d.id: d});
  }
  if (payments != null) {
    await paymentsOrderedIndex.clear();
    paymentsOrderedIndex.write(payments);
  }
  if (driverPayments != null) {
    await driverPaymentsBox.clear();
    await driverPaymentsBox.putAll({for (final p in driverPayments) p.id: p});
  }
  if (expenses != null) {
    await expensesBox.clear();
    await expensesBox.putAll({for (final e in expenses) e.id: e});
  }
  if (profile != null) {
    await profileBox.put(StorageKeys.singleValueKey, profile);
  }
}

/// Clears all boxes and re-seeds from [seedIfEmpty] — "Reset to Sample Data".
Future<void> resetToSampleData() async {
  await Future.wait([
    ordersOrderedIndex.clear(),
    companiesBox.clear(),
    customersBox.clear(),
    driversBox.clear(),
    paymentsOrderedIndex.clear(),
    driverPaymentsBox.clear(),
    expensesBox.clear(),
    profileBox.clear(),
    backupBox.clear(),
  ]);
  await seedIfEmpty();
}

Box<Order> get ordersBox => Hive.box<Order>(StorageKeys.orders);
Box<Company> get companiesBox => Hive.box<Company>(StorageKeys.companies);
Box<Customer> get customersBox => Hive.box<Customer>(StorageKeys.customers);
Box<Driver> get driversBox => Hive.box<Driver>(StorageKeys.drivers);
Box<PaymentReceipt> get paymentsBox => Hive.box<PaymentReceipt>(StorageKeys.payments);
Box<DriverPaymentRecord> get driverPaymentsBox =>
    Hive.box<DriverPaymentRecord>(StorageKeys.driverPayments);
Box<ExpenseRecord> get expensesBox => Hive.box<ExpenseRecord>(StorageKeys.expenses);
Box<TransporterProfile> get profileBox => Hive.box<TransporterProfile>(StorageKeys.profile);
Box<BackupSyncState> get backupBox => Hive.box<BackupSyncState>(StorageKeys.backup);

Box<List> get ordersOrderBox => Hive.box<List>(StorageKeys.ordersOrder);
Box<List> get paymentsOrderBox => Hive.box<List>(StorageKeys.paymentsOrder);

/// Keeps [ordersBox]'s display order stable (newest-first) across restarts —
/// see `OrderedBoxIndex`'s doc comment for why plain box order can't do this.
OrderedBoxIndex<Order> get ordersOrderedIndex => OrderedBoxIndex<Order>(
      dataBox: ordersBox,
      orderBox: ordersOrderBox,
      orderKey: StorageKeys.singleValueKey,
      idOf: (o) => o.id,
    );

/// Same as [ordersOrderedIndex], for [paymentsBox].
OrderedBoxIndex<PaymentReceipt> get paymentsOrderedIndex => OrderedBoxIndex<PaymentReceipt>(
      dataBox: paymentsBox,
      orderBox: paymentsOrderBox,
      orderKey: StorageKeys.singleValueKey,
      idOf: (p) => p.id,
    );

/// Same shape as `exportBackupJSON` in `LedgerContext.tsx:883-897`. Reads
/// straight from the boxes (not via Riverpod providers) so it works
/// identically from the main isolate (local export, manual Drive sync) and
/// from the `workmanager` background isolate (periodic Drive sync), which
/// has no `ProviderContainer`.
Map<String, dynamic> buildBackupPayload() => {
      'app': 'Transport Ledger',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profileBox.get(StorageKeys.singleValueKey)!.toJson(),
      'orders': ordersOrderedIndex.read().map((o) => o.toJson()).toList(),
      'companies': companiesBox.values.map((c) => c.toJson()).toList(),
      'customers': customersBox.values.map((c) => c.toJson()).toList(),
      'drivers': driversBox.values.map((d) => d.toJson()).toList(),
      'payments': paymentsOrderedIndex.read().map((p) => p.toJson()).toList(),
      'driverPayments': driverPaymentsBox.values.map((p) => p.toJson()).toList(),
      'expenses': expensesBox.values.map((e) => e.toJson()).toList(),
    };

/// `orders.length + payments.length + driverPayments.length +
/// expenses.length`, matching `triggerGoogleDriveBackup`'s
/// `totalLocalRecordsCount` in `LedgerContext.tsx:874`.
int totalLocalRecordsCount() =>
    ordersBox.length + paymentsBox.length + driverPaymentsBox.length + expensesBox.length;
