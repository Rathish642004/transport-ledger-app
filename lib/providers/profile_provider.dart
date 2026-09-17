import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transporter_profile.dart';
import '../storage/hive_boxes.dart';
import '../storage/storage_keys.dart';
import 'toast_provider.dart';

/// Mirrors `updateProfile` in `LedgerContext.tsx:851-854`. Single-value box,
/// same as `TransporterProfile` in the design doc's storage table.
class ProfileNotifier extends Notifier<TransporterProfile> {
  @override
  TransporterProfile build() => profileBox.get(StorageKeys.singleValueKey)!;

  void updateProfile(TransporterProfile profile) {
    profileBox.put(StorageKeys.singleValueKey, profile);
    state = profile;
    ref.read(toastProvider.notifier).show('Business profile & invoice settings saved');
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, TransporterProfile>(ProfileNotifier.new);
