import 'enums.dart';

/// Mirrors `src/types.ts` `BackupSyncState`. Stored as a single-value box entry.
class BackupSyncState {
  const BackupSyncState({
    this.googleAccount,
    required this.isConnected,
    required this.autoBackupEnabled,
    required this.backupFrequency,
    this.lastBackupDate,
    required this.syncStatus,
    required this.totalLocalRecordsCount,
  });

  final String? googleAccount;
  final bool isConnected;
  final bool autoBackupEnabled;
  final BackupFrequency backupFrequency;
  final String? lastBackupDate;
  final SyncStatus syncStatus;
  final int totalLocalRecordsCount;

  BackupSyncState copyWith({
    String? googleAccount,
    bool? isConnected,
    bool? autoBackupEnabled,
    BackupFrequency? backupFrequency,
    String? lastBackupDate,
    SyncStatus? syncStatus,
    int? totalLocalRecordsCount,
  }) {
    return BackupSyncState(
      googleAccount: googleAccount ?? this.googleAccount,
      isConnected: isConnected ?? this.isConnected,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      syncStatus: syncStatus ?? this.syncStatus,
      totalLocalRecordsCount: totalLocalRecordsCount ?? this.totalLocalRecordsCount,
    );
  }

  factory BackupSyncState.fromJson(Map<String, dynamic> json) {
    return BackupSyncState(
      googleAccount: json['googleAccount'] as String?,
      isConnected: json['isConnected'] as bool,
      autoBackupEnabled: json['autoBackupEnabled'] as bool,
      backupFrequency: BackupFrequency.fromJson(json['backupFrequency'] as String),
      lastBackupDate: json['lastBackupDate'] as String?,
      syncStatus: SyncStatus.fromJson(json['syncStatus'] as String),
      totalLocalRecordsCount: (json['totalLocalRecordsCount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'googleAccount': googleAccount,
        'isConnected': isConnected,
        'autoBackupEnabled': autoBackupEnabled,
        'backupFrequency': backupFrequency.toJson(),
        'lastBackupDate': lastBackupDate,
        'syncStatus': syncStatus.toJson(),
        'totalLocalRecordsCount': totalLocalRecordsCount,
      };
}
