import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/driver.dart';
import '../providers/drivers_provider.dart';
import '../providers/toast_provider.dart';
import '../router/app_router.dart';

/// Ported from `src/screens/PartiesScreens.tsx`'s `AddEditDriverModal`.
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
    super.dispose();
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

    context.go(AppRoutes.drivers);
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

InputDecoration _decoration({String? hint}) => InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    );
