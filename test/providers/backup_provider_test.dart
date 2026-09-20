import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/enums.dart';
import 'package:flutter_app/providers/backup_provider.dart';
import 'package:flutter_app/providers/companies_provider.dart';
import 'package:flutter_app/providers/orders_provider.dart';
import 'package:flutter_app/providers/toast_provider.dart';
import 'package:flutter_app/services/drive_backup_client.dart';
import 'package:flutter_app/storage/hive_boxes.dart';

import '../test_helpers/hive_test_env.dart';

/// A fake [DriveBackupClient] — lets `BackupNotifier`'s state machine
/// (connecting → syncing → synced/error, provider invalidation on restore)
/// be verified without a real device, Google account, or network call. The
/// real `GoogleDriveBackupClient` is exercised only by `flutter build apk`
/// compiling; see its doc comment.
class _FakeDriveBackupClient implements DriveBackupClient {
  bool failConnect = false;
  bool failUpload = false;
  bool failDownload = false;
  String? storedBackup;
  String email = 'trucker@example.com';

  @override
  Future<String> connect() async {
    if (failConnect) throw StateError('sign-in failed');
    return email;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> uploadBackup(String jsonContent) async {
    if (failUpload) throw StateError('upload failed');
    storedBackup = jsonContent;
  }

  @override
  Future<String?> downloadBackup() async {
    if (failDownload) throw StateError('download failed');
    return storedBackup;
  }

  @override
  Future<bool> trySilentUpload(String jsonContent) async {
    if (failUpload) return false;
    storedBackup = jsonContent;
    return true;
  }
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;
  late _FakeDriveBackupClient fakeDrive;

  setUp(() async {
    tempDir = await openTestHive();
    await seedIfEmpty();
    fakeDrive = _FakeDriveBackupClient();
    container = ProviderContainer(overrides: [driveBackupClientProvider.overrideWithValue(fakeDrive)]);
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  group('connectGoogleDrive', () {
    test('on success, connects and immediately runs a first sync', () async {
      await container.read(backupProvider.notifier).connectGoogleDrive();

      final state = container.read(backupProvider);
      expect(state.isConnected, isTrue);
      expect(state.googleAccount, 'trucker@example.com');
      expect(state.syncStatus, SyncStatus.synced);
      expect(fakeDrive.storedBackup, isNotNull);
      expect(container.read(toastProvider).last.message, 'Successfully backed up all ledger data to Google Drive');
    });

    test('on failure, stays disconnected and shows an error toast', () async {
      fakeDrive.failConnect = true;

      await container.read(backupProvider.notifier).connectGoogleDrive();

      final state = container.read(backupProvider);
      expect(state.isConnected, isFalse);
      expect(container.read(toastProvider).last.type, ToastType.error);
    });
  });

  group('syncNow', () {
    test('uploads a backup payload covering all 5 seed orders and updates sync state', () async {
      await container.read(backupProvider.notifier).syncNow();

      final state = container.read(backupProvider);
      expect(state.syncStatus, SyncStatus.synced);
      expect(state.totalLocalRecordsCount, 5 + 3 + 5); // orders + payments + expenses
      expect(state.lastBackupDate, isNotNull);

      final uploaded = jsonDecode(fakeDrive.storedBackup!) as Map<String, dynamic>;
      expect((uploaded['orders'] as List).length, 5);
    });

    test('on upload failure, sets syncStatus to pending and shows an error toast', () async {
      fakeDrive.failUpload = true;

      await container.read(backupProvider.notifier).syncNow();

      expect(container.read(backupProvider).syncStatus, SyncStatus.pending);
      expect(container.read(toastProvider).last.type, ToastType.error);
    });
  });

  test('disconnectGoogleDrive clears the connection and turns off auto-backup', () async {
    await container.read(backupProvider.notifier).connectGoogleDrive();
    await container.read(backupProvider.notifier).setAutoBackupEnabled(true);

    await container.read(backupProvider.notifier).disconnectGoogleDrive();

    final state = container.read(backupProvider);
    expect(state.isConnected, isFalse);
    expect(state.autoBackupEnabled, isFalse);
    expect(state.syncStatus, SyncStatus.never);
  });

  group('restoreFromDrive', () {
    test('downloads and restores a previously-synced backup', () async {
      await container.read(backupProvider.notifier).syncNow(); // seeds fakeDrive.storedBackup

      // Simulate the Drive copy being ahead: 1 order only.
      fakeDrive.storedBackup = jsonEncode({
        'orders': [ordersBox.values.first.toJson()],
      });

      final ok = await container.read(backupProvider.notifier).restoreFromDrive();

      expect(ok, isTrue);
      expect(container.read(ordersProvider).length, 1);
    });

    test('with no Drive backup yet, warns and leaves data untouched', () async {
      final companiesBefore = container.read(companiesProvider);

      final ok = await container.read(backupProvider.notifier).restoreFromDrive();

      expect(ok, isFalse);
      expect(container.read(toastProvider).last.type, ToastType.warning);
      expect(container.read(companiesProvider), companiesBefore);
    });
  });

  test('restoreBackupFromJSON replaces orders/companies and leaves omitted collections untouched', () async {
    final companiesBefore = container.read(companiesProvider);

    final backupJson = jsonEncode({
      'orders': [
        {
          ...ordersBox.values.first.toJson(),
          'id': 'ord-restored-1',
          'orderNumber': 'RESTORED/1',
        },
      ],
    });

    final ok = await container.read(backupProvider.notifier).restoreBackupFromJSON(backupJson);

    expect(ok, isTrue);
    final orders = container.read(ordersProvider);
    expect(orders.length, 1);
    expect(orders.single.id, 'ord-restored-1');
    // `companies` was absent from the backup payload, so it's untouched.
    expect(container.read(companiesProvider), companiesBefore);
  });

  test('restoreBackupFromJSON rejects a payload with no orders array', () async {
    final notifier = container.read(backupProvider.notifier);
    final ok = await notifier.restoreBackupFromJSON(jsonEncode({'companies': []}));

    expect(ok, isFalse);
    expect(container.read(toastProvider).last.message, 'Invalid backup file format');
    expect(container.read(toastProvider).last.type, ToastType.error);
  });

  test('restoreBackupFromJSON rejects malformed JSON', () async {
    final ok = await container.read(backupProvider.notifier).restoreBackupFromJSON('not json{{{');

    expect(ok, isFalse);
    expect(container.read(toastProvider).last.message, 'Failed to parse backup JSON file');
  });

}
