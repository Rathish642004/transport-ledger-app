import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/transporter_profile.dart';
import '../providers/backup_provider.dart';
import '../router/app_router.dart';
import '../storage/hive_boxes.dart' as hive;
import '../storage/storage_keys.dart';
import '../theme/app_theme.dart';

/// First-run gate — the router (`app_router.dart`'s `redirect`) sends every
/// navigation here whenever `profileBox` is empty, and away from here once
/// it isn't. Two steps: optionally connect Google Drive (which restores an
/// existing backup for a reinstall/new device, if one exists), then collect
/// the business profile the rest of the app assumes always exists
/// (`profileProvider.build()`, `buildBackupPayload`, bill printing, ...).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { welcome, profile }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  bool _connecting = false;
  String? _error;

  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _businessNameCtrl,
      _ownerNameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _addressCtrl,
      _cityCtrl,
      _pincodeCtrl,
      _gstinCtrl,
      _panCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _connectDrive() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    final connected = await ref.read(backupProvider.notifier).connectForOnboarding();
    if (!mounted) return;
    setState(() => _connecting = false);
    if (!connected) {
      setState(() => _error = 'Could not connect to Google Drive. You can try again or continue without it.');
      return;
    }
    if (hive.profileBox.isNotEmpty) {
      // A backup was found and restored, and it included a profile — the
      // user is reinstalling / switching devices, not starting fresh.
      context.go(AppRoutes.dashboard);
    } else {
      setState(() => _step = _Step.profile);
    }
  }

  void _continueWithoutDrive() {
    setState(() {
      _error = null;
      _step = _Step.profile;
    });
  }

  Future<void> _saveProfile() async {
    if (_businessNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Business name is required.');
      return;
    }
    const blank = TransporterProfile(
      businessName: '',
      tagline: '',
      ownerName: '',
      phone: '',
      email: '',
      address: '',
      city: '',
      state: '',
      pincode: '',
      gstin: '',
      pan: '',
      bankName: '',
      accountNumber: '',
      ifscCode: '',
      branchName: '',
      upiId: '',
      termsAndConditions: '',
    );
    final profile = blank.copyWith(
      businessName: _businessNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim().toUpperCase(),
      pan: _panCtrl.text.trim().toUpperCase(),
    );
    await hive.profileBox.put(StorageKeys.singleValueKey, profile);

    // If Drive was connected in the previous step, push this brand-new
    // profile up right away instead of waiting for the next manual/periodic
    // sync — mirrors what a normal "Connect" from Settings already does.
    if (ref.read(backupProvider).isConnected) {
      unawaited(ref.read(backupProvider.notifier).syncNow());
    }

    if (mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == _Step.welcome ? _buildWelcome() : _buildProfileForm(),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.local_shipping_outlined, size: 72, color: AppColors.skyPrimary),
        const SizedBox(height: 20),
        const Text(
          'Welcome to Transport Ledger',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.slate900),
        ),
        const SizedBox(height: 10),
        const Text(
          'Track orders, driver payments and billing in one place.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 40),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.skyPrimary, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _connecting ? null : _connectDrive,
          icon: _connecting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cloud_outlined, size: 18),
          label: const Text('Connect Google Drive'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Recommended if you\'ve used this app before — restores your data automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _connecting ? null : _continueWithoutDrive,
          child: const Text('Continue without Google Drive'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE11D48), fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Set up your business profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.slate900),
        ),
        const SizedBox(height: 6),
        const Text(
          'This appears on your invoices, bills and reports. You can change it later in Settings.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        const _FieldLabel('Business Name *'),
        TextField(controller: _businessNameCtrl, decoration: _decoration()),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        const _FieldLabel('Email'),
        TextField(controller: _emailCtrl, decoration: _decoration()),
        const SizedBox(height: 12),
        const _FieldLabel('Address'),
        TextField(controller: _addressCtrl, decoration: _decoration()),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('GSTIN'),
                  TextField(controller: _gstinCtrl, textCapitalization: TextCapitalization.characters, decoration: _decoration()),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('PAN Number'),
                  TextField(controller: _panCtrl, textCapitalization: TextCapitalization.characters, decoration: _decoration()),
                ],
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFFE11D48), fontSize: 12)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.skyPrimary, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _saveProfile,
          child: const Text('Get Started'),
        ),
      ],
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
