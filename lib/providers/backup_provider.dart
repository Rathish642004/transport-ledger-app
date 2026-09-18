import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:workmanager/workmanager.dart';

import '../models/backup_sync_state.dart';
import '../models/bank_account.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/driver.dart';
import '../models/driver_payment_record.dart';
import '../models/enums.dart';
import '../models/expense_record.dart';
import '../models/ledger_transaction.dart';
import '../models/order.dart';
import '../models/payment_receipt.dart';
import '../models/transporter_profile.dart';
import '../services/backup_background_task.dart';
import '../services/drive_backup_client.dart';
import '../storage/hive_boxes.dart' as hive;
import '../storage/storage_keys.dart';
import '../utils/formatters.dart';
import 'all_transactions_provider.dart';
import 'banks_provider.dart';
import 'companies_provider.dart';
import 'customers_provider.dart';
import 'driver_payments_provider.dart';
import 'drivers_provider.dart';
import 'expenses_provider.dart';
import 'orders_provider.dart';
import 'payments_provider.dart';
import 'profile_provider.dart';
import 'toast_provider.dart';

String _csvNum(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

/// Real Drive client by default; overridden with a fake in tests (see
/// `test/providers/backup_provider_test.dart`) since the real one needs a
/// device, a Google account, and the OAuth client in the
/// `transport-ledger-c3580` project — none of which `flutter test` has.
final driveBackupClientProvider = Provider<DriveBackupClient>((ref) => GoogleDriveBackupClient());

Duration _workmanagerFrequency(BackupFrequency f) => switch (f) {
      BackupFrequency.daily => const Duration(days: 1),
      BackupFrequency.weekly => const Duration(days: 7),
      BackupFrequency.monthly => const Duration(days: 30),
    };

/// Owns both local export/import (`exportBackupJSON`/`exportLedgerCSV`/
/// `restoreBackupFromJSON`, ported from `LedgerContext.tsx:883-954`) and
/// **real** Google Drive backup — a deliberate improvement over the source,
/// whose `triggerGoogleDriveBackup`/`connectGoogleDrive` are a pure 1.4s
/// `setTimeout` simulation with no OAuth or Drive API call anywhere
/// (`isConnected` is hardcoded `true` in `mockData.ts` and never
/// reassigned). The design doc's stated goal is "Working Google Drive
/// backup/sync (the React version only simulates this)", so this builds the
/// real thing via `google_sign_in` + `googleapis` against the OAuth client
/// provisioned in the `transport-ledger-c3580` Firebase/Google Cloud
/// project.
///
/// The actual Drive calls live behind [driveBackupClientProvider] so this
/// notifier's state machine (connecting → syncing → synced/error, toasts,
/// provider invalidation) is unit-testable with a fake client; only the real
/// [GoogleDriveBackupClient] implementation itself — the literal OAuth
/// handshake and HTTP calls — is unverified here (no device/account
/// available in this environment; see its doc comment).
class BackupNotifier extends Notifier<BackupSyncState> {
  @override
  BackupSyncState build() => hive.backupBox.get(StorageKeys.singleValueKey)!;

  void _commit(BackupSyncState next) {
    hive.backupBox.put(StorageKeys.singleValueKey, next);
    state = next;
  }

  String _googleDriveConnectionError(Object error) {
    if (error is GoogleSignInException && error.code == GoogleSignInExceptionCode.clientConfigurationError) {
      return 'Google Drive is not configured for this app build. Ask the app '
          'owner to add a Web OAuth client and the app signing SHA-1, then '
          'download a new google-services.json.';
    }
    return 'Could not connect to Google Drive. Please try again.';
  }

  /// Signs in, authorizes `drive.appdata`, and immediately runs a first
  /// sync — matching the source's one-click "Connect Drive" UX, where
  /// connecting and backing up were literally the same action.
  Future<void> connectGoogleDrive() async {
    try {
      final email = await ref.read(driveBackupClientProvider).connect();
      _commit(state.copyWith(isConnected: true, googleAccount: email));
      await syncNow();
    } catch (error) {
      ref.read(toastProvider.notifier).show(
        _googleDriveConnectionError(error),
        ToastType.error,
      );
    }
  }

  /// Onboarding's "Connect Google Drive" (`OnboardingScreen`) — like
  /// [connectGoogleDrive] but doesn't call [syncNow]: there's nothing to
  /// back up yet since no profile has been entered. Instead it pulls down
  /// any existing appDataFolder backup (a reinstall or a new device), which
  /// may restore a profile and skip the manual setup step entirely. Returns
  /// whether the connection itself succeeded — the caller checks
  /// `hive.profileBox` afterwards to see whether a restore supplied one.
  Future<bool> connectForOnboarding() async {
    try {
      final client = ref.read(driveBackupClientProvider);
      final email = await client.connect();
      _commit(state.copyWith(isConnected: true, googleAccount: email));
      final backupJson = await client.downloadBackup();
      if (backupJson != null) {
        await restoreBackupFromJSON(backupJson);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnectGoogleDrive() async {
    await ref.read(driveBackupClientProvider).disconnect();
    await setAutoBackupEnabled(false);
    _commit(state.copyWith(isConnected: false, syncStatus: SyncStatus.never));
    ref.read(toastProvider.notifier).show('Disconnected from Google Drive', ToastType.info);
  }

  /// The "Sync Now" button — also what a fresh "Connect" runs once.
  Future<void> syncNow() async {
    _commit(state.copyWith(syncStatus: SyncStatus.syncing));
    try {
      final payload = hive.buildBackupPayload();
      await ref.read(driveBackupClientProvider).uploadBackup(jsonEncode(payload));
      _commit(state.copyWith(
        lastBackupDate: formatBackupTimestamp(DateTime.now()),
        syncStatus: SyncStatus.synced,
        totalLocalRecordsCount: hive.totalLocalRecordsCount(),
      ));
      ref.read(toastProvider.notifier).show('Successfully backed up all ledger data to Google Drive');
    } catch (_) {
      _commit(state.copyWith(syncStatus: SyncStatus.pending));
      ref.read(toastProvider.notifier).show('Google Drive backup failed. Check your connection and try again.', ToastType.error);
    }
  }

  /// Downloads the Drive backup file and runs it through the same
  /// parse/validate path as a local file restore. Additive vs. the source
  /// (which has no Drive restore UI at all) — the design doc's Drive-sync
  /// goal and the implementation plan both call for it explicitly.
  Future<bool> restoreFromDrive() async {
    try {
      final content = await ref.read(driveBackupClientProvider).downloadBackup();
      if (content == null) {
        ref.read(toastProvider.notifier).show('No Google Drive backup found yet', ToastType.warning);
        return false;
      }
      return await restoreBackupFromJSON(content);
    } catch (_) {
      ref.read(toastProvider.notifier).show('Failed to download backup from Google Drive', ToastType.error);
      return false;
    }
  }

  /// Toggles the `workmanager` periodic sync alongside the persisted
  /// setting — Android enforces a 15-minute floor on periodic work, but
  /// every [BackupFrequency] option here (daily/weekly/monthly) is already
  /// far above that, so no clamping is actually needed in practice.
  /// Scheduling failures (including "no platform implementation", e.g.
  /// under `flutter test`, which has no real WorkManager) are swallowed —
  /// background auto-sync is a bonus on top of manual "Sync Now", not
  /// something that should ever block or crash a settings change.
  Future<void> _scheduleOrCancel(bool enabled, BackupFrequency frequency) async {
    try {
      if (enabled) {
        await Workmanager().registerPeriodicTask(
          backupTaskName,
          backupTaskName,
          frequency: _workmanagerFrequency(frequency),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          constraints: Constraints(networkType: NetworkType.connected),
        );
      } else {
        await Workmanager().cancelByUniqueName(backupTaskName);
      }
    } catch (_) {
      // See doc comment above.
    }
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    _commit(state.copyWith(autoBackupEnabled: enabled));
    await _scheduleOrCancel(enabled, state.backupFrequency);
  }

  Future<void> setBackupFrequency(BackupFrequency frequency) async {
    _commit(state.copyWith(backupFrequency: frequency));
    if (state.autoBackupEnabled) {
      await _scheduleOrCancel(true, frequency);
    }
  }

  Future<void> exportBackupJSON() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/TransportLedger_Backup_${getTodayDateString()}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(hive.buildBackupPayload()));

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Transport Ledger Backup'));
    ref.read(toastProvider.notifier).show('Ledger JSON backup downloaded', ToastType.info);
  }

  /// Not wired to any button — matches the source, where `exportLedgerCSV`
  /// is defined on the context but never invoked from `SettingsScreen.tsx`
  /// or anywhere else. Ported for parity per the implementation plan anyway.
  Future<void> exportLedgerCSV() async {
    final transactions = ref.read(allTransactionsProvider);
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Party,Order Number,Debit/Credit,Amount,Status,Notes');
    for (final t in transactions) {
      final party = t.partyName.replaceAll('"', '""');
      final notes = t.notes.replaceAll('"', '""');
      buffer.writeln('${t.date},${t.partyType.label},"$party",${t.orderNumber ?? ''},${t.type.label},${_csvNum(t.amount)},${t.paymentStatus},"$notes"');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Transport_Ledger_Statement_${getTodayDateString()}.csv');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Transport Ledger Statement'));
    ref.read(toastProvider.notifier).show('Ledger exported to CSV', ToastType.info);
  }

  void _invalidateAll() {
    ref.invalidate(ordersProvider);
    ref.invalidate(companiesProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(driversProvider);
    ref.invalidate(paymentsProvider);
    ref.invalidate(driverPaymentsProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(banksProvider);
  }

  /// Returns `true` on success, matching the source's `boolean` return (used
  /// by the caller to know whether the restore succeeded).
  Future<bool> restoreBackupFromJSON(String jsonData) async {
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (_) {
      ref.read(toastProvider.notifier).show('Failed to parse backup JSON file', ToastType.error);
      return false;
    }

    final rawOrders = parsed['orders'];
    if (rawOrders is! List) {
      ref.read(toastProvider.notifier).show('Invalid backup file format', ToastType.error);
      return false;
    }

    List<T>? mapList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = parsed[key];
      if (raw is! List) return null;
      return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    await hive.replaceAllFromBackup(
      orders: rawOrders.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList(),
      companies: mapList('companies', Company.fromJson),
      customers: mapList('customers', Customer.fromJson),
      drivers: mapList('drivers', Driver.fromJson),
      payments: mapList('payments', PaymentReceipt.fromJson),
      driverPayments: mapList('driverPayments', DriverPaymentRecord.fromJson),
      expenses: mapList('expenses', ExpenseRecord.fromJson),
      profile: parsed['profile'] != null ? TransporterProfile.fromJson(parsed['profile'] as Map<String, dynamic>) : null,
      banks: mapList('banks', BankAccount.fromJson),
    );
    _invalidateAll();

    ref.read(toastProvider.notifier).show('Ledger restored successfully from backup file');
    return true;
  }

}

final backupProvider = NotifierProvider<BackupNotifier, BackupSyncState>(BackupNotifier.new);
