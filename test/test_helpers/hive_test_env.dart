import 'dart:io';

import 'package:hive_ce/hive_ce.dart';

import 'package:flutter_app/models/backup_sync_state.dart';
import 'package:flutter_app/models/bank_account.dart';
import 'package:flutter_app/models/company.dart';
import 'package:flutter_app/models/customer.dart';
import 'package:flutter_app/models/expense_record.dart';
import 'package:flutter_app/models/hive_registrar.g.dart';
import 'package:flutter_app/models/order.dart';
import 'package:flutter_app/models/payment_receipt.dart';
import 'package:flutter_app/models/transporter_profile.dart';
import 'package:flutter_app/storage/storage_keys.dart';

bool _adaptersRegistered = false;

/// Opens every box under a fresh temp directory using plain `Hive.init` (no
/// Flutter path_provider binding needed), for tests that exercise providers
/// backed by real Hive boxes. Call [closeTestHive] with the returned
/// directory in `tearDown`.
Future<Directory> openTestHive() async {
  final tempDir = await Directory.systemTemp.createTemp('tl_provider_test_');
  Hive.init(tempDir.path);
  if (!_adaptersRegistered) {
    Hive.registerAdapters();
    _adaptersRegistered = true;
  }
  await Future.wait([
    Hive.openBox<Order>(StorageKeys.orders),
    Hive.openBox<Company>(StorageKeys.companies),
    Hive.openBox<Customer>(StorageKeys.customers),
    Hive.openBox<PaymentReceipt>(StorageKeys.payments),
    Hive.openBox<ExpenseRecord>(StorageKeys.expenses),
    Hive.openBox<TransporterProfile>(StorageKeys.profile),
    Hive.openBox<BackupSyncState>(StorageKeys.backup),
    Hive.openBox<BankAccount>(StorageKeys.banks),
    Hive.openBox<List>(StorageKeys.ordersOrder),
    Hive.openBox<List>(StorageKeys.paymentsOrder),
  ]);
  return tempDir;
}

/// Closes Hive and removes the temp directory. Both steps are guarded with a
/// short timeout: a test that left a fake-clock `Timer` pending (e.g. an
/// un-flushed `ToastNotifier.show` 3.8s auto-dismiss) can otherwise make
/// `Hive.close()`/directory deletion hang the whole suite for the default
/// 10-minute test timeout — a test-infrastructure quirk, not a real app bug
/// (verified: the actual test body always completes fine; only this
/// teardown step hangs). Swallowing a timeout here just risks a leaked temp
/// dir, which is harmless.
Future<void> closeTestHive(Directory tempDir) async {
  try {
    await Hive.close().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Ignore — see doc comment above.
  }
  try {
    await tempDir.delete(recursive: true).timeout(const Duration(seconds: 5));
  } catch (_) {
    // Ignore — see doc comment above.
  }
}
