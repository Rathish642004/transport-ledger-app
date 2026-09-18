import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/bank_account.dart';
import '../providers/banks_provider.dart';
import '../providers/toast_provider.dart';
import '../router/app_router.dart';

/// New screen — not in the React source. Add/edit form for the
/// transporter's own [BankAccount]s.
class AddEditBankScreen extends ConsumerStatefulWidget {
  const AddEditBankScreen({super.key, this.bankAccountId});

  final String? bankAccountId;

  @override
  ConsumerState<AddEditBankScreen> createState() => _AddEditBankScreenState();
}

class _AddEditBankScreenState extends ConsumerState<AddEditBankScreen> {
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountHolderNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _ifscCodeCtrl;
  late final TextEditingController _branchNameCtrl;
  late final TextEditingController _upiIdCtrl;

  BankAccount? get _existing {
    if (widget.bankAccountId == null) return null;
    for (final b in ref.read(banksProvider)) {
      if (b.id == widget.bankAccountId) return b;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    _bankNameCtrl = TextEditingController(text: existing?.bankName ?? '');
    _accountHolderNameCtrl = TextEditingController(text: existing?.accountHolderName ?? '');
    _accountNumberCtrl = TextEditingController(text: existing?.accountNumber ?? '');
    _ifscCodeCtrl = TextEditingController(text: existing?.ifscCode ?? '');
    _branchNameCtrl = TextEditingController(text: existing?.branchName ?? '');
    _upiIdCtrl = TextEditingController(text: existing?.upiId ?? '');
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountHolderNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCodeCtrl.dispose();
    _branchNameCtrl.dispose();
    _upiIdCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_bankNameCtrl.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).show('Bank name is required', ToastType.warning);
      return;
    }
    if (_accountNumberCtrl.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).show('Account number is required', ToastType.warning);
      return;
    }

    ref.read(banksProvider.notifier).saveBankAccount(
          id: widget.bankAccountId,
          bankName: _bankNameCtrl.text,
          accountHolderName: _accountHolderNameCtrl.text,
          accountNumber: _accountNumberCtrl.text,
          ifscCode: _ifscCodeCtrl.text.toUpperCase(),
          branchName: _branchNameCtrl.text,
          upiId: _upiIdCtrl.text.isEmpty ? null : _upiIdCtrl.text,
        );

    context.go(AppRoutes.banks);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            Text(widget.bankAccountId != null ? 'Edit Bank Account' : 'Add Bank Account', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Bank Name *'),
              TextField(controller: _bankNameCtrl, decoration: _decoration(hint: 'e.g. State Bank of India')),
              const SizedBox(height: 10),
              const _FieldLabel('Account Holder Name'),
              TextField(controller: _accountHolderNameCtrl, decoration: _decoration(hint: 'e.g. Kalavathi Selvaraj')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Account Number *'),
                        TextField(controller: _accountNumberCtrl, style: const TextStyle(fontFamily: 'monospace'), decoration: _decoration(hint: '36288475312')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('IFSC Code'),
                        TextField(
                          controller: _ifscCodeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontFamily: 'monospace'),
                          decoration: _decoration(hint: 'SBIN0008160'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Branch Name'),
              TextField(controller: _branchNameCtrl, decoration: _decoration(hint: 'e.g. Thadicombu Branch, Dindigul')),
              const SizedBox(height: 10),
              const _FieldLabel('UPI ID (optional)'),
              TextField(controller: _upiIdCtrl, decoration: _decoration(hint: 'e.g. 36288475312@sbi')),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0369A1), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Save Bank Account'),
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
