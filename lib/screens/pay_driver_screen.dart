import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/driver.dart';
import '../models/driver_payment_record.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../providers/banks_provider.dart';
import '../providers/driver_payments_provider.dart';
import '../providers/drivers_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/toast_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';

/// Ported from `src/screens/PayDriverScreen.tsx`.
class PayDriverScreen extends ConsumerStatefulWidget {
  const PayDriverScreen({super.key, this.orderId, this.driverId});

  final String? orderId;
  final String? driverId;

  @override
  ConsumerState<PayDriverScreen> createState() => _PayDriverScreenState();
}

class _PayDriverScreenState extends ConsumerState<PayDriverScreen> {
  late String _selectedDriverId;
  late String _selectedOrderId;
  late final TextEditingController _amountCtrl;
  late String _paymentDate;
  late PaymentMethod _paymentMethod;
  late final TextEditingController _driverBillNumberCtrl;
  late String _driverBillDate;
  late final TextEditingController _referenceCtrl;
  late final TextEditingController _notesCtrl;
  String _billAttachmentName = '';
  String? _bankAccountId;
  String? _driverPayoutAccountId;

  List<Order> _driverOrders(List<Order> orders, String driverId, String? driverName) {
    return orders
        .where((o) => o.orderStatus != OrderStatus.cancelled && (o.driverId == driverId || o.driverName == driverName || o.id == widget.orderId))
        .toList();
  }

  Order? _findOrder(List<Order> orders, String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  double _pendingFreight(Order? order) {
    if (order == null) return 0;
    final due = order.driverExpense.driverFreight - order.driverExpense.driverPaidAmount;
    return due > 0 ? due : 0;
  }

  @override
  void initState() {
    super.initState();
    final orders = ref.read(ordersProvider);
    final drivers = ref.read(driversProvider);

    _selectedDriverId = widget.driverId ?? (drivers.isNotEmpty ? drivers.first.id : '');
    final driverName = drivers.where((d) => d.id == _selectedDriverId).map((d) => d.name).firstOrNull;
    final driverOrders = _driverOrders(orders, _selectedDriverId, driverName);
    _selectedOrderId = widget.orderId ?? (driverOrders.isNotEmpty ? driverOrders.first.id : '');

    final currentOrder = _findOrder(orders, _selectedOrderId);
    final pending = _pendingFreight(currentOrder);
    _amountCtrl = TextEditingController(text: '${(pending > 0 ? pending : 10000).round()}');
    _paymentDate = getTodayDateString();
    _paymentMethod = PaymentMethod.bankTransfer;
    _driverBillNumberCtrl = TextEditingController(
      text: (currentOrder?.driverExpense.driverBillNumber.isNotEmpty ?? false) ? currentOrder!.driverExpense.driverBillNumber : '',
    );
    _driverBillDate = getTodayDateString();
    _referenceCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    final banks = ref.read(banksProvider);
    _bankAccountId = banks.isNotEmpty ? banks.first.id : null;
    final selectedDriver = drivers.where((d) => d.id == _selectedDriverId).firstOrNull;
    _driverPayoutAccountId = selectedDriver?.payoutAccounts.firstOrNull?.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _driverBillNumberCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _handleDriverChange(String driverId, List<Order> orders, List<Driver> drivers) {
    setState(() {
      _selectedDriverId = driverId;
      Order? matched;
      for (final o in orders) {
        if (o.driverId == driverId) {
          matched = o;
          break;
        }
      }
      if (matched != null) {
        _selectedOrderId = matched.id;
        _amountCtrl.text = '${_pendingFreight(matched).round()}';
      }
      final newDriver = drivers.where((d) => d.id == driverId).firstOrNull;
      _driverPayoutAccountId = newDriver?.payoutAccounts.firstOrNull?.id;
    });
  }

  void _handleOrderChange(String orderId, List<Order> orders) {
    setState(() {
      _selectedOrderId = orderId;
      final order = _findOrder(orders, orderId);
      if (order != null) {
        _amountCtrl.text = '${_pendingFreight(order).round()}';
        if (order.driverExpense.driverBillNumber.isNotEmpty) {
          _driverBillNumberCtrl.text = order.driverExpense.driverBillNumber;
        }
      }
    });
  }

  Future<void> _pickAttachment() async {
    final file = await FilePicker.pickFile();
    if (file != null) {
      setState(() => _billAttachmentName = file.name);
    }
  }

  void _handleSubmit(Order? currentOrder, Driver? selectedDriver) {
    final amountPaid = double.tryParse(_amountCtrl.text) ?? 0;
    if (amountPaid <= 0) {
      ref.read(toastProvider.notifier).show('Please enter a valid payment amount', ToastType.warning);
      return;
    }
    if (selectedDriver == null) {
      ref.read(toastProvider.notifier).show('Please select a driver', ToastType.warning);
      return;
    }

    ref.read(driverPaymentsProvider.notifier).payDriver(
          DriverPaymentRecord(
            id: '',
            voucherNumber: '',
            driverId: selectedDriver.id,
            driverName: selectedDriver.name,
            orderId: currentOrder?.id ?? 'general-trip',
            orderNumber: currentOrder?.orderNumber ?? 'GEN-DRV',
            driverBillNumber: _driverBillNumberCtrl.text,
            driverBillDate: _driverBillDate,
            agreedFreight: currentOrder?.driverExpense.driverFreight ?? amountPaid,
            amountPaid: amountPaid,
            paymentDate: _paymentDate,
            paymentMethod: _paymentMethod,
            referenceNumber: _referenceCtrl.text,
            notes: _notesCtrl.text,
            billAttachmentName: _billAttachmentName,
            bankAccountId: _bankAccountId,
            driverPayoutAccountId: _driverPayoutAccountId,
            recordedAt: '',
          ),
        );

    if (currentOrder != null) {
      context.pushReplacement(AppRoutes.orderDetailsPath(currentOrder.id));
    } else {
      context.pushReplacement(AppRoutes.drivers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final drivers = ref.watch(driversProvider);
    final banks = ref.watch(banksProvider);
    final selectedDriver = drivers.where((d) => d.id == _selectedDriverId).firstOrNull;
    final driverOrders = _driverOrders(orders, _selectedDriverId, selectedDriver?.name);
    final currentOrder = _findOrder(orders, _selectedOrderId);
    final pendingFreight = _pendingFreight(currentOrder);

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
                    const Text('DRIVER FREIGHT DISBURSEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                    const Text('Pay Truck Driver', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.badge, color: Color(0xFFB45309)),
              ),
            ],
          ),
        ),
        if (selectedDriver != null) ...[
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
                    Text(selectedDriver.name, style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(selectedDriver.vehicleNumber, style: const TextStyle(color: Color(0xFFCBD5E1), fontFamily: 'monospace', fontSize: 11)),
                  ],
                ),
                const Divider(height: 14, color: Color(0xFF1E293B)),
                Row(
                  children: [
                    Expanded(child: _StatBlock('Agreed Freight', currentOrder != null ? formatINR(currentOrder.driverExpense.driverFreight) : '—', Colors.white)),
                    Expanded(child: _StatBlock('Already Paid', currentOrder != null ? formatINR(currentOrder.driverExpense.driverPaidAmount) : '—', const Color(0xFF34D399))),
                    Expanded(
                      child: _StatBlock(
                        'Balance Payable',
                        currentOrder != null ? formatINR(pendingFreight) : formatINR(selectedDriver.outstandingAmount),
                        const Color(0xFFFCD34D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                  const Text('Select Truck Driver *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  TextButton(onPressed: () => context.push(AppRoutes.driversEdit), child: const Text('+ Add Driver', style: TextStyle(fontSize: 10))),
                ],
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: drivers.any((d) => d.id == _selectedDriverId) ? _selectedDriverId : null,
                decoration: _decoration(),
                items: [for (final d in drivers) DropdownMenuItem(value: d.id, child: Text('${d.name} • ${d.vehicleNumber} (Due: ${formatINR(d.outstandingAmount)})', overflow: TextOverflow.ellipsis))],
                onChanged: (v) {
                  if (v != null) _handleDriverChange(v, orders, drivers);
                },
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Select Transport Order *'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: driverOrders.any((o) => o.id == _selectedOrderId) ? _selectedOrderId : null,
                decoration: _decoration(),
                items: [
                  const DropdownMenuItem(value: '', child: Text('-- Standalone Driver Payment --', overflow: TextOverflow.ellipsis)),
                  for (final o in driverOrders)
                    DropdownMenuItem(
                      value: o.id,
                      child: Text('${o.orderNumber} - ${o.numberOfBags} Bags (${o.pickupLocation.split(',').first} → ${o.deliveryLocation.split(',').first})', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => _handleOrderChange(v ?? '', orders),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount Paid to Driver (₹) *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  if (pendingFreight > 0)
                    TextButton(
                      onPressed: () => setState(() => _amountCtrl.text = '${pendingFreight.round()}'),
                      child: Text('Clear Full Balance (${formatINR(pendingFreight)})', style: const TextStyle(fontSize: 10)),
                    ),
                ],
              ),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF451A03)),
                decoration: _decoration(hint: '10000').copyWith(
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD97706), width: 2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD97706), width: 2)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Driver Bill / Bilty No.'),
                        TextField(controller: _driverBillNumberCtrl, style: const TextStyle(fontFamily: 'monospace'), decoration: _decoration(hint: 'e.g. DB-4521/11')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Driver Bill Date'),
                        _DateField(value: _driverBillDate, onChanged: (d) => setState(() => _driverBillDate = d)),
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
                        const _FieldLabel('Payment Mode *'),
                        DropdownButtonFormField<PaymentMethod>(
                          isExpanded: true,
                          initialValue: _paymentMethod,
                          decoration: _decoration(),
                          items: const [
                            DropdownMenuItem(value: PaymentMethod.bankTransfer, child: Text('Bank Transfer (IMPS/NEFT)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: PaymentMethod.upi, child: Text('UPI (GooglePay/PhonePe)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash at Pump/Office', overflow: TextOverflow.ellipsis)),
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
              const _FieldLabel('Payment Ref / UTR / Cash Voucher No.'),
              TextField(controller: _referenceCtrl, style: const TextStyle(fontFamily: 'monospace'), decoration: _decoration()),
              const SizedBox(height: 10),
              const _FieldLabel('Driver Bill / Proof Attachment'),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.description_outlined, size: 14),
                    label: Text(_billAttachmentName.isNotEmpty ? 'Change Attachment' : 'Upload Driver Slip'),
                  ),
                  if (_billAttachmentName.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(child: Text('✓ $_billAttachmentName', style: const TextStyle(color: Color(0xFF047857), fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ],
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
                  const DropdownMenuItem(value: null, child: Text('-- Not linked to a bank account --', overflow: TextOverflow.ellipsis)),
                  for (final b in banks)
                    DropdownMenuItem(value: b.id, child: Text('${b.bankName} • ${b.accountNumber}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _bankAccountId = v),
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Paid To (Driver\'s Account)'),
              DropdownButtonFormField<String?>(
                key: const Key('driverPayoutAccountDropdown'),
                isExpanded: true,
                initialValue: (selectedDriver?.payoutAccounts ?? const []).any((a) => a.id == _driverPayoutAccountId) ? _driverPayoutAccountId : null,
                decoration: _decoration(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('-- Not specified --', overflow: TextOverflow.ellipsis)),
                  for (final a in selectedDriver?.payoutAccounts ?? const [])
                    DropdownMenuItem(value: a.id, child: Text(a.label, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _driverPayoutAccountId = v),
              ),
              const SizedBox(height: 10),
              const _FieldLabel('Notes'),
              TextField(controller: _notesCtrl, decoration: _decoration(hint: 'Diesel advance given at petrol pump...')),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => _handleSubmit(currentOrder, selectedDriver),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('Confirm Driver Payment of ${formatINR(double.tryParse(_amountCtrl.text) ?? 0)}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
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
