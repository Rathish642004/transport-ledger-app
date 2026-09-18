import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/backup_sync_state.dart';
import '../models/enums.dart';
import '../providers/backup_provider.dart';
import '../providers/profile_provider.dart';
import '../router/app_router.dart';

/// Ported from `src/screens/SettingsScreen.tsx`. [initialTab] is accepted
/// for interface parity with the router (`?tab=gdrive_backup`, matching the
/// `gdrive_backup` `ActiveScreen` variant in `LedgerContext.tsx`) but —
/// verified against `App.tsx:68-69` — both `settings` and `gdrive_backup`
/// render the exact same `<SettingsScreen />` with no props, so it's
/// deliberately unused here, same as `ReportsScreen.initialTab`.
///
/// Three intentional differences from the source:
/// - The Google Drive card wires up *real* sync (`BackupNotifier`) instead
///   of the source's fake timer — see that class's doc comment.
/// - "Project Source Code (.ZIP)" is dropped: it downloads
///   `/transport-ledger.zip`, an artifact of the React app's own web
///   hosting. There is no equivalent for a native Android app to download
///   its own source from — nothing to port.
/// - A "Bank Accounts" tile is added at the top, linking to `BanksListScreen`
///   — the new "Banks" feature's one entry point. (Companies/Customers/
///   Drivers tiles briefly lived here too, but that duplicated the Ledger's
///   own tabs for the same data; removed — see `_ManageRow`'s doc comment.)
/// - The source's single "Bank Details for Invoices & NEFT" fields
///   (`profile.bankName`/`accountNumber`/`ifscCode`/`upiId`) are dropped from
///   this form now that `BankAccount`s (plural, via the "Banks" tile above)
///   are the real place to manage bank accounts — keeping both would just
///   be two disconnected, confusing sources of "the" bank details.
///   `BillPreviewScreen` now sources the printed bill's bank details from
///   the first `BankAccount` on file instead of these profile fields.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _gstinCtrl;
  late final TextEditingController _panCtrl;
  late final TextEditingController _termsCtrl;

  bool _savedSuccess = false;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _businessNameCtrl = TextEditingController(text: profile.businessName);
    _ownerNameCtrl = TextEditingController(text: profile.ownerName);
    _phoneCtrl = TextEditingController(text: profile.phone);
    _emailCtrl = TextEditingController(text: profile.email);
    _addressCtrl = TextEditingController(text: profile.address);
    _cityCtrl = TextEditingController(text: profile.city);
    _pincodeCtrl = TextEditingController(text: profile.pincode);
    _gstinCtrl = TextEditingController(text: profile.gstin);
    _panCtrl = TextEditingController(text: profile.pan);
    _termsCtrl = TextEditingController(text: profile.termsAndConditions);
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    _gstinCtrl.dispose();
    _panCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  /// The source's `handleSaveProfile` builds a plain object literal missing
  /// `tagline`/`state`/`accountName` (all present in `TransporterProfile`,
  /// and `tagline`/`state` are non-optional there) — those 3 fields have no
  /// form inputs at all, so every save silently wipes them
  /// (`SettingsScreen.tsx:57-73` vs. `types.ts:206-225`; Vite doesn't
  /// type-check on build, so this never surfaces). Fixed here by starting
  /// from the current profile via `copyWith` and only overriding the fields
  /// this form actually edits, so the un-editable ones survive a save.
  void _handleSaveProfile() {
    final current = ref.read(profileProvider);
    ref.read(profileProvider.notifier).updateProfile(current.copyWith(
          businessName: _businessNameCtrl.text,
          ownerName: _ownerNameCtrl.text,
          phone: _phoneCtrl.text,
          email: _emailCtrl.text,
          address: _addressCtrl.text,
          city: _cityCtrl.text,
          pincode: _pincodeCtrl.text,
          gstin: _gstinCtrl.text.toUpperCase(),
          pan: _panCtrl.text.toUpperCase(),
          termsAndConditions: _termsCtrl.text,
        ));
    setState(() => _savedSuccess = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _savedSuccess = false);
    });
  }

  Future<void> _handleConnect() async {
    setState(() => _connecting = true);
    await ref.read(backupProvider.notifier).connectGoogleDrive();
    if (mounted) setState(() => _connecting = false);
  }

  Future<void> _handleRestoreFile() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
    if (file?.path == null) return;
    final content = await File(file!.path!).readAsString();
    await ref.read(backupProvider.notifier).restoreBackupFromJSON(content);
  }

  @override
  Widget build(BuildContext context) {
    final backup = ref.watch(backupProvider);
    final syncing = backup.syncStatus == SyncStatus.syncing;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('CONFIGURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
        const Text('Settings & Cloud Backup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const _ManageRow(),
        const SizedBox(height: 12),
        _GoogleDriveCard(
          backup: backup,
          connecting: _connecting,
          syncing: syncing,
          onConnect: _handleConnect,
          onSyncNow: () => ref.read(backupProvider.notifier).syncNow(),
          onDisconnect: () => ref.read(backupProvider.notifier).disconnectGoogleDrive(),
          onAutoBackupChanged: (v) => ref.read(backupProvider.notifier).setAutoBackupEnabled(v),
          onFrequencyChanged: (f) => ref.read(backupProvider.notifier).setBackupFrequency(f),
          onExportFile: () => ref.read(backupProvider.notifier).exportBackupJSON(),
          onRestoreFile: _handleRestoreFile,
          onRestoreFromDrive: () => ref.read(backupProvider.notifier).restoreFromDrive(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.apartment, size: 16, color: Color(0xFF0369A1)),
                      SizedBox(width: 6),
                      Text('Transporter Business Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  if (_savedSuccess)
                    const Row(
                      children: [
                        Icon(Icons.check, size: 14, color: Color(0xFF047857)),
                        SizedBox(width: 4),
                        Text('Saved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                      ],
                    ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              const _FieldLabel('Business Name'),
              TextField(controller: _businessNameCtrl, decoration: _decoration()),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [const _FieldLabel('Proprietor Name'), TextField(controller: _ownerNameCtrl, decoration: _decoration())],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [const _FieldLabel('Phone'), TextField(controller: _phoneCtrl, decoration: _decoration())],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Address'),
              TextField(controller: _addressCtrl, decoration: _decoration()),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [const _FieldLabel('City'), TextField(controller: _cityCtrl, decoration: _decoration())],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [const _FieldLabel('Pincode'), TextField(controller: _pincodeCtrl, decoration: _decoration())],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('GSTIN'),
                        TextField(controller: _gstinCtrl, textCapitalization: TextCapitalization.characters, style: const TextStyle(fontFamily: 'monospace'), decoration: _decoration()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('PAN Number'),
                        TextField(controller: _panCtrl, textCapitalization: TextCapitalization.characters, style: const TextStyle(fontFamily: 'monospace'), decoration: _decoration()),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Invoice Terms & Conditions'),
                    TextField(controller: _termsCtrl, maxLines: 2, decoration: _decoration()),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0369A1), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _handleSaveProfile,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Just "Banks" now — Companies/Customers/Drivers used to be tiles here too,
/// but that put them in two places at once (here, and as their own Ledger
/// tabs, which is where their per-party financials and now an Edit action
/// already live — see `ledger_screen.dart`). Removed to leave the Ledger as
/// the one place to browse and edit them; "Banks" stays here since it has
/// no Ledger-tab equivalent.
class _ManageRow extends StatelessWidget {
  const _ManageRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(AppRoutes.banks),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF0369A1)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Bank Accounts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _GoogleDriveCard extends StatelessWidget {
  const _GoogleDriveCard({
    required this.backup,
    required this.connecting,
    required this.syncing,
    required this.onConnect,
    required this.onSyncNow,
    required this.onDisconnect,
    required this.onAutoBackupChanged,
    required this.onFrequencyChanged,
    required this.onExportFile,
    required this.onRestoreFile,
    required this.onRestoreFromDrive,
  });

  final BackupSyncState backup;
  final bool connecting;
  final bool syncing;
  final VoidCallback onConnect;
  final VoidCallback onSyncNow;
  final VoidCallback onDisconnect;
  final ValueChanged<bool> onAutoBackupChanged;
  final ValueChanged<BackupFrequency> onFrequencyChanged;
  final VoidCallback onExportFile;
  final VoidCallback onRestoreFile;
  final VoidCallback onRestoreFromDrive;

  @override
  Widget build(BuildContext context) {
    final bool isConnected = backup.isConnected;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.cloud_outlined, size: 16, color: Color(0xFF0369A1)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Google Drive Backup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(
                      isConnected ? 'Connected as ${backup.googleAccount ?? "your account"}' : 'Not linked to Google Drive',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isConnected)
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0369A1)),
                  onPressed: connecting ? null : onConnect,
                  child: connecting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Connect Drive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                OutlinedButton.icon(
                  onPressed: syncing ? null : onSyncNow,
                  icon: syncing
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 14, color: Color(0xFF047857)),
                  label: Text(syncing ? 'Syncing...' : 'Sync Now', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                ),
            ],
          ),
          if (isConnected) ...[
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            Row(
              children: [
                const Text('Auto-Backup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Switch(value: backup.autoBackupEnabled, onChanged: onAutoBackupChanged),
                if (backup.autoBackupEnabled)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<BackupFrequency>(
                        value: backup.backupFrequency,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0C4A6E)),
                        items: BackupFrequency.values.map((f) => DropdownMenuItem(value: f, child: Text(f.jsonValue))).toList(),
                        onChanged: (f) {
                          if (f != null) onFrequencyChanged(f);
                        },
                      ),
                    ),
                  )
                else
                  const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero),
                  onPressed: onDisconnect,
                  child: const Text('Disconnect', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ),
              ],
            ),
          ],
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportFile,
                    icon: const Icon(Icons.download, size: 14, color: Color(0xFF0369A1)),
                    label: const Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRestoreFile,
                    icon: const Icon(Icons.upload, size: 14, color: Color(0xFF059669)),
                    label: const Text('Restore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (isConnected) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Restore from Drive',
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(10)),
                      onPressed: onRestoreFromDrive,
                      child: const Icon(Icons.cloud_download_outlined, size: 16, color: Color(0xFF0369A1)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
    );
  }
}

InputDecoration _decoration() => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    );
