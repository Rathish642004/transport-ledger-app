import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/company.dart';
import '../providers/companies_provider.dart';
import '../providers/toast_provider.dart';

/// Ported from `src/screens/PartiesScreens.tsx`'s `AddEditCompanyModal`.
///
/// The source form has no GSTIN/PAN toggle beyond a single GSTIN field, and
/// never renders a PAN input at all — `pan` is only ever round-tripped from
/// `existing?.pan`, never edited here. We match that: no PAN field, and
/// `saveCompany` is called without a `pan` argument so `CompaniesNotifier`'s
/// `copyWith(pan: null)` preserves whatever the company already had.
class AddEditCompanyScreen extends ConsumerStatefulWidget {
  const AddEditCompanyScreen({super.key, this.companyId});

  final String? companyId;

  @override
  ConsumerState<AddEditCompanyScreen> createState() => _AddEditCompanyScreenState();
}

class _AddEditCompanyScreenState extends ConsumerState<AddEditCompanyScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactPersonCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _gstinCtrl;

  Company? get _existing {
    if (widget.companyId == null) return null;
    for (final c in ref.read(companiesProvider)) {
      if (c.id == widget.companyId) return c;
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
    _addressCtrl = TextEditingController(text: existing?.address ?? '');
    _cityCtrl = TextEditingController(text: existing?.city ?? '');
    _gstinCtrl = TextEditingController(text: existing?.gstin ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_nameCtrl.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).show('Company name is required', ToastType.warning);
      return;
    }

    ref.read(companiesProvider.notifier).saveCompany(
          id: widget.companyId,
          name: _nameCtrl.text,
          contactPerson: _contactPersonCtrl.text,
          phone: _phoneCtrl.text,
          email: _emailCtrl.text,
          address: _addressCtrl.text,
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
            Text(widget.companyId != null ? 'Edit Company' : 'Add New Company', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Company Name *'),
              TextField(controller: _nameCtrl, decoration: _decoration(hint: 'e.g. Shree Balaji PolyFab Pvt Ltd')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Contact Person'),
                        TextField(controller: _contactPersonCtrl, decoration: _decoration(hint: 'e.g. Arvind Aggarwal')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Phone *'),
                        TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: _decoration(hint: '+91 98251 11204')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Address *'),
              TextField(controller: _addressCtrl, decoration: _decoration(hint: 'Plot 48, GIDC Industrial Estate, Sachin')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('City & State *'),
                        TextField(controller: _cityCtrl, decoration: _decoration(hint: 'Surat, Gujarat')),
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
                          decoration: _decoration(hint: '24AABCS7821H1ZQ'),
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
                  label: const Text('Save Company Profile'),
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
