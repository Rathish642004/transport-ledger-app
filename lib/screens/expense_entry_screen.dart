import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../models/expense_record.dart';
import '../providers/banks_provider.dart';
import '../providers/drivers_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/toast_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';

const _categories = [
  ExpenseCategory.fuel,
  ExpenseCategory.loadingLabour,
  ExpenseCategory.unloadingLabour,
  ExpenseCategory.tollTax,
  ExpenseCategory.rtoPolice,
  ExpenseCategory.vehicleMaintenance,
  ExpenseCategory.weighbridgeKaanta,
  ExpenseCategory.otherTransport,
];

/// Ported from `src/screens/ExpenseEntryScreen.tsx`.
///
/// The source's `addExpense` call passes `expenseDate`/`description`/
/// `receiptAttachment`, but `ExpenseRecord`'s actual fields are `date`/
/// `notes`/`receiptAttachmentName` — a naming mismatch that would silently
/// drop that data in the original (also missing the required `paidTo`
/// entirely, and passing a `driverId` the type doesn't even have). Mapped to
/// the obviously-intended fields here rather than reproducing data loss;
/// `paidTo` has no form field in the source either, so it's left empty —
/// faithful to what the form actually collects, not a real fix to that gap.
/// The driver selector, like in the source, doesn't affect what's saved
/// (`ExpenseRecord` has no `driverId` field).
class ExpenseEntryScreen extends ConsumerStatefulWidget {
  const ExpenseEntryScreen({super.key, this.orderId});

  final String? orderId;

  @override
  ConsumerState<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends ConsumerState<ExpenseEntryScreen> {
  ExpenseCategory _category = ExpenseCategory.loadingLabour;
  late final TextEditingController _amountCtrl;
  late String _expenseDate;
  late String _selectedOrderId;
  late final TextEditingController _vehicleNumberCtrl;
  late String _driverId;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  late final TextEditingController _descriptionCtrl;
  String _receiptAttachment = '';
  String? _bankAccountId;

  @override
  void initState() {
    super.initState();
    final drivers = ref.read(driversProvider);
    _amountCtrl = TextEditingController();
    _expenseDate = getTodayDateString();
    _selectedOrderId = widget.orderId ?? '';
    _vehicleNumberCtrl = TextEditingController();
    _driverId = drivers.isNotEmpty ? drivers.first.id : '';
    _descriptionCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _handleOrderChange(String orderId, List<dynamic> orders) {
    setState(() {
      _selectedOrderId = orderId;
      for (final o in orders) {
        if (o.id == orderId) {
          _vehicleNumberCtrl.text = o.vehicleNumber as String;
          _driverId = o.driverId as String;
          break;
        }
      }
    });
  }

  Future<void> _pickAttachment() async {
    final file = await FilePicker.pickFile();
    if (file != null) {
      setState(() => _receiptAttachment = file.name);
    }
  }

  void _handleSubmit() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ref.read(toastProvider.notifier).show('Please enter a valid expense amount', ToastType.warning);
      return;
    }

    ref.read(expensesProvider.notifier).addExpense(
          ExpenseRecord(
            id: '',
            expenseNumber: '',
            date: _expenseDate,
            category: _category,
            amount: amount,
            vehicleNumber: _vehicleNumberCtrl.text.toUpperCase(),
            orderId: _selectedOrderId.isNotEmpty ? _selectedOrderId : null,
            paidTo: '',
            paymentMethod: _paymentMethod,
            notes: _descriptionCtrl.text,
            receiptAttachmentName: _receiptAttachment.isNotEmpty ? _receiptAttachment : null,
            bankAccountId: _bankAccountId,
          ),
        );

    if (_selectedOrderId.isNotEmpty) {
      context.pushReplacement(AppRoutes.orderDetailsPath(_selectedOrderId));
    } else {
      context.pushReplacement(AppRoutes.ledger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final drivers = ref.watch(driversProvider);
    final banks = ref.watch(banksProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OPERATIONAL OUTFLOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFBE123C))),
                    const Text('Record Transport Expense', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long, color: Color(0xFFBE123C)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Expense Category *'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in _categories)
                    _CategoryPill(
                      label: cat.jsonValue,
                      selected: _category == cat,
                      onTap: () => setState(() => _category = cat),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Expense Amount (₹) *'),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4C0519)),
                decoration: _decoration(hint: '1500').copyWith(
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFB7185), width: 2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFB7185), width: 2)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Date'),
                        _DateField(value: _expenseDate, onChanged: (d) => setState(() => _expenseDate = d)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Paid Via'),
                        DropdownButtonFormField<PaymentMethod>(
                          isExpanded: true,
                          initialValue: _paymentMethod,
                          decoration: _decoration(),
                          items: const [
                            DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash in Hand', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: PaymentMethod.upi, child: Text('UPI / GPay')),
                            DropdownMenuItem(value: PaymentMethod.bankTransfer, child: Text('Bank Transfer', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: PaymentMethod.cheque, child: Text('Cheque')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _paymentMethod = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Linked Transport Trip / Order'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: orders.any((o) => o.id == _selectedOrderId) ? _selectedOrderId : '',
                decoration: _decoration(),
                items: [
                  const DropdownMenuItem(value: '', child: Text('-- General Operational Expense --', overflow: TextOverflow.ellipsis)),
                  for (final o in orders)
                    DropdownMenuItem(value: o.id, child: Text('${o.orderNumber} - ${o.numberOfBags} Bags (${o.vehicleNumber})', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => _handleOrderChange(v ?? '', orders),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Vehicle Truck No.'),
                        TextField(controller: _vehicleNumberCtrl, textCapitalization: TextCapitalization.characters, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold), decoration: _decoration()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Driver'),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: drivers.any((d) => d.id == _driverId) ? _driverId : '',
                          decoration: _decoration(),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('-- Optional --')),
                            for (final d in drivers) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) => setState(() => _driverId = v ?? ''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _FieldLabel('Paid From Bank Account'),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.banksEdit),
                    child: const Text('+ Add Bank', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: banks.any((b) => b.id == _bankAccountId) ? _bankAccountId : null,
                decoration: _decoration(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('-- Cash / Not linked --', overflow: TextOverflow.ellipsis)),
                  for (final b in banks)
                    DropdownMenuItem(value: b.id, child: Text('${b.bankName} • ${b.accountNumber}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _bankAccountId = v),
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Description / Remarks'),
              TextField(controller: _descriptionCtrl, maxLines: 2, decoration: _decoration()),
              const SizedBox(height: 10),
              const _FieldLabel('Receipt / Voucher Photo'),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.description_outlined, size: 14),
                    label: Text(_receiptAttachment.isNotEmpty ? 'Change Photo' : 'Attach Receipt / Bill'),
                  ),
                  if (_receiptAttachment.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(child: Text('✓ $_receiptAttachment', style: const TextStyle(color: Color(0xFF047857), fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('Save Expense of ${formatINR(double.tryParse(_amountCtrl.text) ?? 0)}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1F2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFFFB7185) : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? const Color(0xFF9F1239) : const Color(0xFF334155))),
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

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(value) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(getTodayDateString(picked));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
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
