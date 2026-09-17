import 'dart:convert';

import 'package:workmanager/workmanager.dart';

import '../models/enums.dart';
import '../storage/hive_boxes.dart' as hive;
import '../storage/storage_keys.dart';
import '../utils/formatters.dart';
import 'drive_backup_client.dart';

/// Unique name workmanager registers the periodic Drive-backup task under.
const backupTaskName = 'transport_ledger_drive_backup';

/// Entry point for the `workmanager` background isolate — registered once in
/// `main.dart` via `Workmanager().initialize(backupCallbackDispatcher)`.
///
/// This is the least verifiable code in the app: it runs headless, in a
/// fresh isolate, only when Android decides to fire the periodic work
/// request (a real device, backgrounded, 15+ minutes — not something
/// `flutter test` or a single manual run can exercise). It is written
/// defensively for that reason: every failure mode falls through to `return
/// true` (task considered "done", not "retry") except an unexpected crash,
/// since a silently-unavailable Drive session is an expected, common case
/// (e.g. before the user ever connects Drive) rather than a transient error
/// worth WorkManager's retry/backoff.
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backupTaskName) return true;

    try {
      await hive.initHive();
      final backupState = hive.backupBox.get(StorageKeys.singleValueKey);
      if (backupState == null || !backupState.autoBackupEnabled || !backupState.isConnected) {
        return true;
      }

      final payload = hive.buildBackupPayload();
      final ok = await GoogleDriveBackupClient().trySilentUpload(jsonEncode(payload));
      if (ok) {
        hive.backupBox.put(
          StorageKeys.singleValueKey,
          backupState.copyWith(
            lastBackupDate: formatBackupTimestamp(DateTime.now()),
            syncStatus: SyncStatus.synced,
            totalLocalRecordsCount: hive.totalLocalRecordsCount(),
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  });
}
