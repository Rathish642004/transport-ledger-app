import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/payment_allocation_engine.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/party_ledger.dart';
import '../models/payment_allocation.dart';
import '../models/payment_receipt.dart';
import '../providers/banks_provider.dart';
import '../providers/companies_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/party_ledger_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/toast_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';
import '../widgets/confirmation_dialog.dart';

/// Party-first payment recording: a customer or company pays one lump sum
/// covering many orders, tallied FIFO (oldest order first) rather than one
/// payment per order. [partyId]/[partyType] pre-select the party when
/// launched from a party card or order details; otherwise the first
/// available party is used.
class ReceivePaymentScreen extends ConsumerStatefulWidget {
  const ReceivePaymentScreen({super.key, this.partyType, this.partyId});

  final PayerType? partyType;
  final String? partyId;

  @override
  ConsumerState<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends ConsumerState<ReceivePaymentScreen> {
  late PayerType _payerType;
  late String _partyId;
  late final TextEditingController _amountCtrl;
  late String _paymentDate;
  late PaymentMethod _paymentMethod;
  late final TextEditingController _otherDeductionCtrl;
  late final TextEditingController _referenceCtrl;
  late final TextEditingController _notesCtrl;
  String? _bankAccountId;

  /// Orders the user wants this payment applied to — defaults to the
  /// oldest-first FIFO set that covers the entered amount, but the user can
  /// untick an older order and tick a newer one instead. Whatever ends up
  /// ticked is applied oldest-first among the selection.
  Set<String> _selectedOrderIds = {};
  bool _selectionManuallyEdited = false;

  String _partyName(PayerType type, String id) {
    if (type == PayerType.company) {
      for (final c in ref.read(companiesProvider)) {
        if (c.id == id) return c.name;
      }
    } else {
      for (final c in ref.read(customersProvider)) {
        if (c.id == id) return c.name;
      }
    }
    return '';
  }

  PartyLedger _ledger() => ledgerFor(ref.watch(partyLedgerProvider), _payerType, _partyId);

  Set<String> _defaultSelection(double amount, List<Order> openOrders) {
    final selected = <String>{};
    var remaining = amount;
    for (final o in openOrders) {
      if (remaining <= 0.01) break;
      final due = expectedReceiptFor(o) - o.amountReceived;
      if (due <= 0.01) continue;
      selected.add(o.id);
      remaining -= due;
    }
    return selected;
  }

  List<PaymentAllocation> _previewAllocations(List<Order> openOrders) {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final selectedOrders = openOrders.where((o) => _selectedOrderIds.contains(o.id)).toList();
    return allocateFifo(
      openOrders: selectedOrders,
      alreadyAllocated: {for (final o in selectedOrders) o.id: o.amountReceived},
      amount: amount,
    );
  }

  void _onAmountChanged(String value) {
    setState(() {
      if (!_selectionManuallyEdited) {
        _selectedOrderIds = _defaultSelection(double.tryParse(value) ?? 0, _ledger().openOrders);
      }
    });
  }

  void _toggleOrder(String orderId) {
    setState(() {
      _selectionManuallyEdited = true;
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _onPartyChanged(PayerType type, String id) {
    setState(() {
      _payerType = type;
      _partyId = id;
      _selectionManuallyEdited = false;
      final ledger = ledgerFor(ref.read(partyLedgerProvider), type, id);
      final amount = ledger.outstanding > 0 ? ledger.outstanding : 0.0;
      _amountCtrl.text = amount > 0 ? '${amount.round()}' : '';
      _selectedOrderIds = _defaultSelection(amount, ledger.openOrders);
    });
  }

  @override
  void initState() {
    super.initState();
    final companies = ref.read(companiesProvider);
    final customers = ref.read(customersProvider);

    _payerType = widget.partyType ?? (companies.isNotEmpty ? PayerType.company : PayerType.customer);
    if (widget.partyId != null) {
      _partyId = widget.partyId!;
    } else if (_payerType == PayerType.company) {
      _partyId = companies.isNotEmpty ? companies.first.id : '';
    } else {
      _partyId = customers.isNotEmpty ? customers.first.id : '';
    }

    final ledger = ledgerFor(ref.read(partyLedgerProvider), _payerType, _partyId);
    final amount = ledger.outstanding > 0 ? ledger.outstanding : 0.0;
    _amountCtrl = TextEditingController(text: amount > 0 ? '${amount.round()}' : '');
    _selectedOrderIds = _defaultSelection(amount, ledger.openOrders);

    _paymentDate = getTodayDateString();
    _paymentMethod = PaymentMethod.bankTransfer;
    _otherDeductionCtrl = TextEditingController(text: '0');
    _referenceCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    final banks = ref.read(banksProvider);
    _bankAccountId = banks.isNotEmpty ? banks.first.id : null;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _otherDeductionCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEditPayment(PaymentReceipt payment) async {
    final amountCtrl = TextEditingController(text: '${payment.amountReceived.round()}');
    final referenceCtrl = TextEditingController(text: payment.referenceNumber);
    final notesCtrl = TextEditingController(text: payment.notes);
    var method = payment.paymentMethod;

    final action = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Payment ${payment.receiptNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Received')),
              const SizedBox(height: 10),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: [for (final m in PaymentMethod.values) DropdownMenuItem(value: m, child: Text(m.jsonValue))],
                onChanged: (v) => setDialogState(() => method = v ?? method),
              ),
              const SizedBox(height: 10),
              TextField(controller: referenceCtrl, decoration: const InputDecoration(labelText: 'Reference Number')),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete'),
              child: const Text('Remove', style: TextStyle(color: Color(0xFFE11D48))),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop('save'), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'delete') {
      final confirmed = await showConfirmationDialog(
        context,
        title: 'Remove This Payment?',
        message: 'This reverses the amount from every order it was applied to and from ${payment.payerName}\'s balance. This cannot be undone.',
        confirmLabel: 'Remove',
        isDestructive: true,
      );
      if (confirmed) ref.read(paymentsProvider.notifier).removePayment(payment.id);
      return;
    }
    if (action != 'save') return;

    final newAmount = double.tryParse(amountCtrl.text) ?? payment.amountReceived;
    // Re-run FIFO across exactly the orders this receipt already touched,
    // excluding this receipt's own prior contribution from "already
    // allocated" so the new amount is distributed fresh across them.
    final orders = ref.read(ordersProvider);
    final touchedOrders = [
      for (final a in payment.allocations)
        for (final o in orders)
          if (o.id == a.orderId) o,
    ]..sort((a, b) {
        final byDate = a.orderDate.compareTo(b.orderDate);
        return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
      });
    final oldByOrder = {for (final a in payment.allocations) a.orderId: a.amount};
    final newAllocations = allocateFifo(
      openOrders: touchedOrders,
      alreadyAllocated: {for (final o in touchedOrders) o.id: o.amountReceived - (oldByOrder[o.id] ?? 0)},
      amount: newAmount,
    );

    ref.read(paymentsProvider.notifier).updatePayment(payment.copyWith(
          amountReceived: newAmount,
          paymentMethod: method,
          referenceNumber: referenceCtrl.text,
          notes: notesCtrl.text,
          allocations: newAllocations,
        ));
  }

  void _handleSubmit(List<Order> openOrders) {
    final amountReceived = double.tryParse(_amountCtrl.text) ?? 0;
    if (amountReceived <= 0) {
      ref.read(toastProvider.notifier).show('Please enter a valid amount received', ToastType.warning);
      return;
    }
    if (_partyId.isEmpty) {
      ref.read(toastProvider.notifier).show('Please select who is paying', ToastType.warning);
      return;
    }

    final allocations = _previewAllocations(openOrders);
    ref.read(paymentsProvider.notifier).receivePayment(
          partyId: _partyId,
          payerType: _payerType,
          payerName: _partyName(_payerType, _partyId),
          amountReceived: amountReceived,
          paymentDate: _paymentDate,
          paymentMethod: _paymentMethod,
          otherDeduction: double.tryParse(_otherDeductionCtrl.text) ?? 0,
          referenceNumber: _referenceCtrl.text,
          notes: _notesCtrl.text,
          bankAccountId: _bankAccountId,
          allocations: allocations,
        );

    context.pushReplacement(AppRoutes.ledger);
  }

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(companiesProvider);
    final customers = ref.watch(customersProvider);
    final banks = ref.watch(banksProvider);
    final payments = ref.watch(paymentsProvider);
    final ledger = _ledger();
    final openOrders = ledger.openOrders;
    final allocations = _previewAllocations(openOrders);
    final allocatedByOrder = {for (final a in allocations) a.orderId: a};
    final amountReceived = double.tryParse(_amountCtrl.text) ?? 0;
    final unallocated = amountReceived - allocations.fold(0.0, (s, a) => s + a.amount);
    final tdsInThisPayment = allocations.fold(0.0, (s, a) => s + a.tdsSettled);

    final partyHistory = _partyId.isEmpty
        ? const <PaymentReceipt>[]
        : payments.where((p) => p.partyId == _partyId && p.payerType == _payerType).toList();

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
                    Text('CASH COLLECTION ENTRY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF047857))),
                    const Text('Record a Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.credit_card, color: Color(0xFF047857)),
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
              const _FieldLabel('Who is paying? *'),
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'Company',
                      icon: Icons.business,
                      selected: _payerType == PayerType.company,
                      onTap: () => _onPartyChanged(PayerType.company, companies.isNotEmpty ? companies.first.id : ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Customer',
                      icon: Icons.local_shipping,
                      selected: _payerType == PayerType.customer,
                      onTap: () => _onPartyChanged(PayerType.customer, customers.isNotEmpty ? customers.first.id : ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Party *'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _payerType == PayerType.company
                    ? (companies.any((c) => c.id == _partyId) ? _partyId : null)
                    : (customers.any((c) => c.id == _partyId) ? _partyId : null),
                decoration: _decoration(),
                items: _payerType == PayerType.company
                    ? [for (final c in companies) DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))]
                    : [for (final c in customers) DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))],
                onChanged: (v) {
                  if (v != null) _onPartyChanged(_payerType, v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _StatBlock('Total Billed', formatINR(ledger.totalBilled), Colors.white)),
                  Expanded(child: _StatBlock('Received', formatINR(ledger.received), const Color(0xFF34D399))),
                  Expanded(child: _StatBlock('Outstanding', formatINR(ledger.outstanding), const Color(0xFFFCD34D))),
                ],
              ),
              if (ledger.unallocatedCredit > 0) ...[
                const Divider(height: 14, color: Color(0xFF1E293B)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Unallocated Credit', style: TextStyle(color: Color(0xFF7DD3FC), fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(formatINR(ledger.unallocatedCredit), style: const TextStyle(color: Color(0xFF7DD3FC), fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount Received (₹) *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  if (ledger.outstanding > 0)
                    TextButton(
                      onPressed: () {
                        _amountCtrl.text = '${ledger.outstanding.round()}';
                        _onAmountChanged(_amountCtrl.text);
                      },
                      child: Text('Pay Full Due (${formatINR(ledger.outstanding)})', style: const TextStyle(fontSize: 10)),
                    ),
                ],
              ),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF064E3B)),
                decoration: _decoration(hint: '25000').copyWith(
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                ),
                onChanged: _onAmountChanged,
              ),
              if (openOrders.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('APPLY TO ORDERS (FIFO — oldest first)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                for (final o in openOrders)
                  _OrderAllocationRow(
                    order: o,
                    checked: _selectedOrderIds.contains(o.id),
                    onToggle: () => _toggleOrder(o.id),
                    applied: allocatedByOrder[o.id]?.amount,
                  ),
                if (unallocated > 0.01) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Unallocated (becomes credit)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                        Text(formatINR(unallocated), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                      ],
                    ),
                  ),
                ],
                if (tdsInThisPayment > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TDS Settled on Closed Orders', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                        Text(formatINR(tdsInThisPayment), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Payment Date'),
                        _DateField(value: _paymentDate, onChanged: (d) => setState(() => _paymentDate = d)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Payment Method *'),
                        DropdownButtonFormField<PaymentMethod>(
                          isExpanded: true,
                          initialValue: _paymentMethod,
                          decoration: _decoration(),
                          items: const [
                            DropdownMenuItem(value: PaymentMethod.bankTransfer, child: Text('Bank Transfer (NEFT/RTGS)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: PaymentMethod.upi, child: Text('UPI (GooglePay/PhonePe)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash in Hand')),
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Other Deduction (₹)'),
                        TextField(controller: _otherDeductionCtrl, keyboardType: TextInputType.number, decoration: _decoration(hint: '0')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('UTR / Ref / Cheque No.'),
                        TextField(controller: _referenceCtrl, style: const TextStyle(fontFamily: 'monospace'), decoration: _decoration(hint: 'UTR or Cheque No')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _FieldLabel('Deposit Into Bank Account'),
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
                  const DropdownMenuItem(value: null, child: Text('-- Not linked to a bank account --', overflow: TextOverflow.ellipsis)),
                  for (final b in banks)
                    DropdownMenuItem(value: b.id, child: Text('${b.bankName} • ${b.accountNumber}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _bankAccountId = v),
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Payment Notes / Remarks'),
              TextField(controller: _notesCtrl, decoration: _decoration(hint: 'e.g. Settlement for last 3 LRs')),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => _handleSubmit(openOrders),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('Confirm & Record ${formatINR(amountReceived)}'),
                ),
              ),
            ],
          ),
        ),
        if (partyHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 6),
                    Text('PREVIOUS PAYMENTS FROM THIS PARTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                for (final h in partyHistory)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatINR(h.amountReceived), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(
                                '${formatDate(h.paymentDate)} via ${h.paymentMethod.jsonValue}'
                                '${h.referenceNumber.isNotEmpty ? ' • Ref: ${h.referenceNumber}' : ''}'
                                '${h.allocations.isNotEmpty ? ' • ${h.allocations.map((a) => a.orderNumber).join(', ')}' : ''}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(999)),
                          child: Text(h.receiptNumber, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () => _handleEditPayment(h),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OrderAllocationRow extends StatelessWidget {
  const _OrderAllocationRow({required this.order, required this.checked, required this.onToggle, required this.applied});

  final Order order;
  final bool checked;
  final VoidCallback onToggle;
  final double? applied;

  @override
  Widget build(BuildContext context) {
    final due = expectedReceiptFor(order) - order.amountReceived;
    final closed = applied != null && applied! >= due - 0.01;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: checked ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: checked ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Checkbox(value: checked, onChanged: (_) => onToggle()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${order.orderNumber} • ${formatDate(order.orderDate)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Due ${formatINR(due)}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),
            if (applied != null && applied! > 0)
              Text(
                '${formatINR(applied!)} ${closed ? '✓' : '(partial)'}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: closed ? const Color(0xFF047857) : const Color(0xFFB45309)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
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

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0369A1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF0369A1) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : const Color(0xFF334155)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF334155))),
          ],
        ),
      ),
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
