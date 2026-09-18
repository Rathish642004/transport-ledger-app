import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/customer.dart';
import '../providers/customers_provider.dart';
import '../providers/toast_provider.dart';

/// Ported from `src/screens/PartiesScreens.tsx`'s `AddEditCustomerModal`.
class AddEditCustomerScreen extends ConsumerStatefulWidget {
  const AddEditCustomerScreen({super.key, this.customerId});

  final String? customerId;

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactPersonCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _deliveryAddressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _gstinCtrl;

  Customer? get _existing {
    if (widget.customerId == null) return null;
    for (final c in ref.read(customersProvider)) {
      if (c.id == widget.customerId) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _contactPersonCtrl = TextEditingController(text: existing?.contactPerson ?? '');
    _phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    _emailCtrl = TextEditingController(text: existing?.email ?? '');
    _deliveryAddressCtrl = TextEditingController(text: existing?.deliveryAddress ?? '');
    _cityCtrl = TextEditingController(text: existing?.city ?? '');
    _gstinCtrl = TextEditingController(text: existing?.gstin ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    _cityCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_nameCtrl.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).show('Customer name is required', ToastType.warning);
      return;
    }

    ref.read(customersProvider.notifier).saveCustomer(
          id: widget.customerId,
          name: _nameCtrl.text,
          contactPerson: _contactPersonCtrl.text,
          phone: _phoneCtrl.text,
          email: _emailCtrl.text,
          deliveryAddress: _deliveryAddressCtrl.text,
          city: _cityCtrl.text,
          gstin: _gstinCtrl.text.toUpperCase(),
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
            Text(widget.customerId != null ? 'Edit Customer' : 'Add Destination Customer', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Customer / Trading Name *'),
              TextField(controller: _nameCtrl, decoration: _decoration(hint: 'e.g. Laxmi Trading Corporation')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Contact Person'),
                        TextField(controller: _contactPersonCtrl, decoration: _decoration(hint: 'e.g. Haresh Bhai')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Phone *'),
                        TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: _decoration(hint: '+91 98202 33411')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Delivery Destination Address *'),
              TextField(controller: _deliveryAddressCtrl, decoration: _decoration(hint: 'Gala No. 42-44, APMC Grain Market, Sector 19')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('City *'),
                        TextField(controller: _cityCtrl, decoration: _decoration(hint: 'Vashi, Navi Mumbai')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('GSTIN'),
                        TextField(
                          controller: _gstinCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontFamily: 'monospace'),
                          decoration: _decoration(hint: '27AABFL9918K1ZV'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0369A1), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Save Customer'),
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
