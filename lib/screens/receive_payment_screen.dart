import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../models/order.dart';
import '../models/payment_receipt.dart';
import '../providers/banks_provider.dart';
import '../providers/companies_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/toast_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';
import '../widgets/confirmation_dialog.dart';

/// Ported from `src/screens/ReceivePaymentScreen.tsx`. [partyId] is accepted
/// (matching the resolved navigation payload shape) but — faithfully to the
/// source — never actually used by the screen; only [orderId]/[partyType]
/// seed the form.
class ReceivePaymentScreen extends ConsumerStatefulWidget {
  const ReceivePaymentScreen({super.key, this.orderId, this.partyType, this.partyId});

  final String? orderId;
  final PayerType? partyType;
  final String? partyId;

  @override
  ConsumerState<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends ConsumerState<ReceivePaymentScreen> {
  late PayerType _payerType;
  late String _selectedOrderId;
  late final TextEditingController _payerNameCtrl;
  late final TextEditingController _amountCtrl;
  late String _paymentDate;
  late PaymentMethod _paymentMethod;
  late final TextEditingController _tdsCtrl;
  late final TextEditingController _otherDeductionCtrl;
  late final TextEditingController _referenceCtrl;
  late final TextEditingController _notesCtrl;
  String? _bankAccountId;

  List<Order> _availableOrders(List<Order> orders) {
    return orders.where((o) {
      if (o.orderStatus == OrderStatus.cancelled) return false;
      final netExpected = o.billing.netExpectedReceipt != 0 ? o.billing.netExpectedReceipt : o.charges.totalCustomerBill;
      final netDue = netExpected - o.amountReceived;
      return netDue > 0 || o.id == widget.orderId;
    }).toList();
  }

  Order? _currentOrder(List<Order> orders) {
    for (final o in orders) {
      if (o.id == _selectedOrderId) return o;
    }
    return null;
  }

  double _balanceDue(Order? order) {
    if (order == null) return 0;
    final netExpected = order.billing.netExpectedReceipt != 0 ? order.billing.netExpectedReceipt : order.charges.totalCustomerBill;
    final due = netExpected - order.amountReceived;
    return due > 0 ? due : 0;
  }

  @override
  void initState() {
    super.initState();
    final orders = ref.read(ordersProvider);
    final companies = ref.read(companiesProvider);
    final available = _availableOrders(orders);

    _payerType = widget.partyType ?? PayerType.company;
    _selectedOrderId = widget.orderId ?? (available.isNotEmpty ? available.first.id : '');

    final currentOrder = _currentOrder(orders);
    final payerName = currentOrder != null
        ? (currentOrder.billing.billPayer == PayerType.company ? currentOrder.companyName : currentOrder.customerName)
        : (companies.isNotEmpty ? companies.first.name : '');
    _payerNameCtrl = TextEditingController(text: payerName);

    final balanceDue = _balanceDue(currentOrder);
    _amountCtrl = TextEditingController(text: '${(balanceDue > 0 ? balanceDue : 25000).round()}');
    _paymentDate = getTodayDateString();
    _paymentMethod = PaymentMethod.bankTransfer;
    _tdsCtrl = TextEditingController(text: '0');
    _otherDeductionCtrl = TextEditingController(text: '0');
    _referenceCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    final banks = ref.read(banksProvider);
    _bankAccountId = banks.isNotEmpty ? banks.first.id : null;
  }

  @override
  void dispose() {
    _payerNameCtrl.dispose();
    _amountCtrl.dispose();
    _tdsCtrl.dispose();
    _otherDeductionCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _handleOrderChange(String orderId, List<Order> orders) {
    setState(() {
      _selectedOrderId = orderId;
      final order = _currentOrder(orders);
      if (order != null) {
        _payerType = order.billing.billPayer;
        _payerNameCtrl.text = order.billing.billRecipientName.isNotEmpty ? order.billing.billRecipientName : order.companyName;
        _amountCtrl.text = '${_balanceDue(order).round()}';
        if (order.billing.tdsApplicable) {
          _tdsCtrl.text = '${order.billing.tdsAmount.round()}';
        }
      }
    });
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
        message: 'This reverses the amount from the order and from ${payment.payerName}\'s balance. This cannot be undone.',
        confirmLabel: 'Remove',
        isDestructive: true,
      );
      if (confirmed) ref.read(paymentsProvider.notifier).removePayment(payment.id);
    } else if (action == 'save') {
      ref.read(paymentsProvider.notifier).updatePayment(payment.copyWith(
            amountReceived: double.tryParse(amountCtrl.text) ?? payment.amountReceived,
            paymentMethod: method,
            referenceNumber: referenceCtrl.text,
            notes: notesCtrl.text,
          ));
    }
  }

  void _handleSubmit(Order? currentOrder) {
    final amountReceived = double.tryParse(_amountCtrl.text) ?? 0;
    if (amountReceived <= 0) {
      ref.read(toastProvider.notifier).show('Please enter a valid amount received', ToastType.warning);
      return;
    }
    if (_payerNameCtrl.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).show('Please specify the Payer Name', ToastType.warning);
      return;
    }

    ref.read(paymentsProvider.notifier).receivePayment(
          PaymentReceipt(
            id: '',
            receiptNumber: '',
            orderId: currentOrder?.id ?? 'ord-general',
            orderNumber: currentOrder?.orderNumber ?? 'GEN-PAY',
            payerType: _payerType,
            payerName: _payerNameCtrl.text,
            amountReceived: amountReceived,
            paymentDate: _paymentDate,
            paymentMethod: _paymentMethod,
            tdsDeducted: double.tryParse(_tdsCtrl.text) ?? 0,
            otherDeduction: double.tryParse(_otherDeductionCtrl.text) ?? 0,
            referenceNumber: _referenceCtrl.text,
            notes: _notesCtrl.text,
            recordedAt: '',
            bankAccountId: _bankAccountId,
          ),
        );

    if (currentOrder != null) {
      context.pushReplacement(AppRoutes.orderDetailsPath(currentOrder.id));
    } else {
      context.pushReplacement(AppRoutes.ledger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final payments = ref.watch(paymentsProvider);
    final banks = ref.watch(banksProvider);
    final currentOrder = _currentOrder(orders);
    final balanceDue = _balanceDue(currentOrder);
    final orderPaymentHistory = _selectedOrderId.isEmpty
        ? <dynamic>[]
        : payments.where((p) => p.orderId == _selectedOrderId || (currentOrder != null && p.orderNumber == currentOrder.orderNumber)).toList();

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
                    const Text('Record Customer Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
        if (currentOrder != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${currentOrder.orderNumber}', style: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('${currentOrder.numberOfBags} Bags', style: const TextStyle(color: Color(0xFF7DD3FC), fontWeight: FontWeight.w600, fontSize: 11)),
                  ],
                ),
                const Divider(height: 14, color: Color(0xFF1E293B)),
                Row(
                  children: [
                    Expanded(child: _StatBlock('Gross Bill', formatINR(currentOrder.charges.totalCustomerBill), Colors.white)),
                    Expanded(child: _StatBlock('Total Received', formatINR(currentOrder.amountReceived), const Color(0xFF34D399))),
                    Expanded(child: _StatBlock('Balance Due', formatINR(balanceDue), const Color(0xFFFCD34D))),
                  ],
                ),
              ],
            ),
          ),
          if (currentOrder.paymentStatus == PaymentStatus.paid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order\'s payment is already fully received. You can still record another payment (e.g. a refund adjustment or correction) — it just won\'t be required.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Payer Type *'),
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'Company',
                      icon: Icons.business,
                      selected: _payerType == PayerType.company,
                      onTap: () => setState(() => _payerType = PayerType.company),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Customer',
                      icon: Icons.local_shipping,
                      selected: _payerType == PayerType.customer,
                      onTap: () => setState(() => _payerType = PayerType.customer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Payer Party Name *'),
              TextField(controller: _payerNameCtrl, decoration: _decoration(hint: 'e.g. Shree Balaji PolyFab Pvt Ltd')),
              const SizedBox(height: 10),
              const _FieldLabel('Related Transport Order / Bill'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: orders.any((o) => o.id == _selectedOrderId) ? _selectedOrderId : null,
                decoration: _decoration(),
                items: [
                  const DropdownMenuItem(value: '', child: Text('-- General Payment (Unlinked) --', overflow: TextOverflow.ellipsis)),
                  for (final o in orders)
                    DropdownMenuItem(
                      value: o.id,
                      child: Text(
                        '${o.orderNumber} - ${o.companyName} → ${o.customerName} (${formatINR(o.charges.totalCustomerBill)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => _handleOrderChange(v ?? '', orders),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount Received (₹) *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  if (balanceDue > 0)
                    TextButton(
                      onPressed: () => setState(() => _amountCtrl.text = '${balanceDue.round()}'),
                      child: Text('Pay Full Due (${formatINR(balanceDue)})', style: const TextStyle(fontSize: 10)),
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
              ),
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
                        const _FieldLabel('TDS Deducted (₹)'),
                        TextField(controller: _tdsCtrl, keyboardType: TextInputType.number, decoration: _decoration(hint: '0')),
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
              TextField(controller: _notesCtrl, decoration: _decoration(hint: 'e.g. 1st installment for 500 bags order')),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => _handleSubmit(currentOrder),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('Confirm & Record ${formatINR(double.tryParse(_amountCtrl.text) ?? 0)}'),
                ),
              ),
            ],
          ),
        ),
        if (orderPaymentHistory.isNotEmpty) ...[
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
                    Text('PREVIOUS INSTALLMENTS FOR THIS ORDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                for (final h in orderPaymentHistory)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatINR(h.amountReceived as double), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(
                                '${formatDate(h.paymentDate as String)} via ${(h.paymentMethod as PaymentMethod).jsonValue}'
                                '${(h.referenceNumber as String).isNotEmpty ? ' • Ref: ${h.referenceNumber}' : ''}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(999)),
                          child: Text(h.receiptNumber as String, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () => _handleEditPayment(h as PaymentReceipt),
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
