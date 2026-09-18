import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/driver.dart';
import '../models/driver_payout_account.dart';
import '../providers/drivers_provider.dart';
import '../providers/toast_provider.dart';

/// Ported from `src/screens/PartiesScreens.tsx`'s `AddEditDriverModal`, plus
/// a "Payment Accounts" section (new — see `DriverPayoutAccount`'s doc
/// comment) shown once the driver exists, letting the transporter record
/// which of the driver's own bank accounts/UPI IDs freight gets paid into.
class AddEditDriverScreen extends ConsumerStatefulWidget {
  const AddEditDriverScreen({super.key, this.driverId});

  final String? driverId;

  @override
  ConsumerState<AddEditDriverScreen> createState() => _AddEditDriverScreenState();
}

class _AddEditDriverScreenState extends ConsumerState<AddEditDriverScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _vehicleNumberCtrl;
  late final TextEditingController _licenseNumberCtrl;
  final _payoutBankNameCtrl = TextEditingController();
  final _payoutAccountNumberCtrl = TextEditingController();
  final _payoutIfscCtrl = TextEditingController();
  final _payoutUpiCtrl = TextEditingController();
  final _extraVehicleCtrl = TextEditingController();

  Driver? get _existing {
    if (widget.driverId == null) return null;
    for (final d in ref.read(driversProvider)) {
      if (d.id == widget.driverId) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    _vehicleNumberCtrl = TextEditingController(text: existing?.vehicleNumber ?? '');
    _licenseNumberCtrl = TextEditingController(text: existing?.licenseNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _licenseNumberCtrl.dispose();
    _payoutBankNameCtrl.dispose();
    _payoutAccountNumberCtrl.dispose();
    _payoutIfscCtrl.dispose();
    _payoutUpiCtrl.dispose();
    _extraVehicleCtrl.dispose();
    super.dispose();
  }

  void _handleAddVehicle() {
    ref.read(driversProvider.notifier).addVehicleNumber(driverId: widget.driverId!, vehicleNumber: _extraVehicleCtrl.text);
    _extraVehicleCtrl.clear();
  }

  void _handleAddPayoutAccount() {
    final bankName = _payoutBankNameCtrl.text.trim();
    final accountNumber = _payoutAccountNumberCtrl.text.trim();
    final upiId = _payoutUpiCtrl.text.trim();

    if ((bankName.isEmpty || accountNumber.isEmpty) && upiId.isEmpty) {
      ref.read(toastProvider.notifier).show('Enter a bank name + account number, or a UPI ID', ToastType.warning);
      return;
    }

    ref.read(driversProvider.notifier).addPayoutAccount(
          driverId: widget.driverId!,
          bankName: bankName.isNotEmpty ? bankName : null,
          accountNumber: accountNumber.isNotEmpty ? accountNumber : null,
          ifscCode: _payoutIfscCtrl.text.trim().isNotEmpty ? _payoutIfscCtrl.text.trim().toUpperCase() : null,
          upiId: upiId.isNotEmpty ? upiId : null,
        );

    _payoutBankNameCtrl.clear();
    _payoutAccountNumberCtrl.clear();
    _payoutIfscCtrl.clear();
    _payoutUpiCtrl.clear();
  }

  void _handleSubmit() {
    if (_nameCtrl.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).show('Driver name is required', ToastType.warning);
      return;
    }
    if (_vehicleNumberCtrl.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).show('Vehicle number is required', ToastType.warning);
      return;
    }

    ref.read(driversProvider.notifier).saveDriver(
          id: widget.driverId,
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          vehicleNumber: _vehicleNumberCtrl.text.toUpperCase(),
          licenseNumber: _licenseNumberCtrl.text.toUpperCase(),
        );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            Text(widget.driverId != null ? 'Edit Driver' : 'Register Truck Driver', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Driver Name *'),
              TextField(controller: _nameCtrl, decoration: _decoration(hint: 'e.g. Gurdeep Singh')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Mobile Phone *'),
                        TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: _decoration(hint: '+91 98721 44512')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Vehicle Truck No. *'),
                        TextField(
                          controller: _vehicleNumberCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          decoration: _decoration(hint: 'MH-04-GP-8841'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Driving License (DL) Number'),
              TextField(
                controller: _licenseNumberCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: _decoration(hint: 'MH0420120045211'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Save Driver Details'),
                ),
              ),
            ],
          ),
        ),
        if (widget.driverId != null) ...[
          const SizedBox(height: 12),
          _VehiclesCard(
            driverId: widget.driverId!,
            vehicleCtrl: _extraVehicleCtrl,
            onAdd: _handleAddVehicle,
          ),
          const SizedBox(height: 12),
          _PayoutAccountsCard(
            driverId: widget.driverId!,
            bankNameCtrl: _payoutBankNameCtrl,
            accountNumberCtrl: _payoutAccountNumberCtrl,
            ifscCtrl: _payoutIfscCtrl,
            upiCtrl: _payoutUpiCtrl,
            onAdd: _handleAddPayoutAccount,
          ),
        ],
      ],
    );
  }
}

class _VehiclesCard extends ConsumerWidget {
  const _VehiclesCard({
    required this.driverId,
    required this.vehicleCtrl,
    required this.onAdd,
  });

  final String driverId;
  final TextEditingController vehicleCtrl;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(driversProvider);
    final driver = drivers.where((d) => d.id == driverId).firstOrNull;
    if (driver == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vehicles', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const Text(
            'This driver\'s trucks — picked from when booking an order.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          for (final v in driver.allVehicleNumbers)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      v == driver.vehicleNumber ? '$v (primary)' : v,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (v != driver.vehicleNumber)
                    InkWell(
                      onTap: () => ref.read(driversProvider.notifier).removeVehicleNumber(driverId: driverId, vehicleNumber: v),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: vehicleCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: _decoration(hint: 'e.g. TN38BK5521'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 14), label: const Text('Add')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutAccountsCard extends ConsumerWidget {
  const _PayoutAccountsCard({
    required this.driverId,
    required this.bankNameCtrl,
    required this.accountNumberCtrl,
    required this.ifscCtrl,
    required this.upiCtrl,
    required this.onAdd,
  });

  final String driverId;
  final TextEditingController bankNameCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController ifscCtrl;
  final TextEditingController upiCtrl;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(driversProvider);
    final driver = drivers.where((d) => d.id == driverId).firstOrNull;
    final accounts = driver?.payoutAccounts ?? const <DriverPayoutAccount>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Accounts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const Text(
            'Which bank account or UPI ID to pay this driver\'s freight into.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          for (final a in accounts)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  InkWell(
                    onTap: () => ref.read(driversProvider.notifier).removePayoutAccount(driverId: driverId, accountId: a.id),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          if (accounts.isEmpty) const Text('No payment accounts added yet.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(child: TextField(controller: bankNameCtrl, decoration: _decoration(hint: 'Bank Name'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: accountNumberCtrl, decoration: _decoration(hint: 'Account Number'))),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ifscCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: _decoration(hint: 'IFSC Code (optional)'),
          ),
          const SizedBox(height: 8),
          const Text('— OR —', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextField(controller: upiCtrl, decoration: _decoration(hint: 'UPI ID, e.g. driver@ybl')),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Payment Account'),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
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

InputDecoration _decoration({String? hint}) => InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    );
