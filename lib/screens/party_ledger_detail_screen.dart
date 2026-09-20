import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/payment_allocation_engine.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/payment_receipt.dart';
import '../providers/companies_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/party_ledger_provider.dart';
import '../providers/payments_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';

enum _DetailTab { orders, payments }

/// A single company's or customer's full ledger: every order billed to them
/// (each showing whether it's pending or completed) and every payment
/// they've made against those orders. Reached by tapping a party row on the
/// Ledger screen. Orders and payments live behind an Orders/Payments tab
/// switcher (rather than both stacked in one long list) with a shared date
/// range filter above them.
class PartyLedgerDetailScreen extends ConsumerStatefulWidget {
  const PartyLedgerDetailScreen({super.key, required this.payerType, required this.partyId});

  final PayerType payerType;
  final String partyId;

  @override
  ConsumerState<PartyLedgerDetailScreen> createState() => _PartyLedgerDetailScreenState();
}

class _PartyLedgerDetailScreenState extends ConsumerState<PartyLedgerDetailScreen> {
  _DetailTab _activeTab = _DetailTab.orders;
  DateTimeRange? _dateRange;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  bool _withinRange(String dateString) {
    final range = _dateRange;
    if (range == null) return true;
    final d = DateTime.tryParse(dateString);
    if (d == null) return false;
    final day = DateTime(d.year, d.month, d.day);
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final payerType = widget.payerType;
    final partyId = widget.partyId;
    final isCompany = payerType == PayerType.company;
    final orders = ref.watch(ordersProvider);
    final payments = ref.watch(paymentsProvider);
    final ledger = ledgerFor(ref.watch(partyLedgerProvider), payerType, partyId);
    final partyOrders = ordersForParty(orders, payerType: payerType, partyId: partyId).where((o) => _withinRange(o.orderDate)).toList();
    final partyPayments = (payments.where((p) => p.partyId == partyId && p.payerType == payerType).toList()..sort((a, b) => b.paymentDate.compareTo(a.paymentDate)))
        .where((p) => _withinRange(p.paymentDate))
        .toList();

    String partyName = isCompany ? 'Unknown Company' : 'Unknown Customer';
    String city = '';
    String editRoute = '';
    if (isCompany) {
      for (final c in ref.watch(companiesProvider)) {
        if (c.id == partyId) {
          partyName = c.name;
          city = c.city;
          break;
        }
      }
      editRoute = '${AppRoutes.companiesEdit}?id=$partyId';
    } else {
      for (final c in ref.watch(customersProvider)) {
        if (c.id == partyId) {
          partyName = c.name;
          city = c.city;
          break;
        }
      }
      editRoute = '${AppRoutes.customersEdit}?id=$partyId';
    }

    final partyLabel = isCompany ? 'company' : 'customer';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Edit',
              onPressed: () => context.push(editRoute),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCompany ? const Color(0xFFE0F2FE) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(isCompany ? Icons.business : Icons.local_shipping, color: isCompany ? const Color(0xFF0369A1) : const Color(0xFF059669)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partyName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        if (city.isNotEmpty) Text(city, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
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
              if (ledger.tdsWithheldTotal > 0 || ledger.unallocatedCredit > 0) ...[
                const Divider(height: 18, color: Color(0xFF1E293B)),
                Row(
                  children: [
                    if (ledger.tdsWithheldTotal > 0)
                      Expanded(child: _StatBlock('TDS Withheld', formatINR(ledger.tdsWithheldTotal), const Color(0xFFB45309))),
                    if (ledger.unallocatedCredit > 0)
                      Expanded(child: _StatBlock('Unallocated Credit', formatINR(ledger.unallocatedCredit), const Color(0xFF7DD3FC))),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (ledger.outstanding > 0 || ledger.unallocatedCredit > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669), padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () => context.push('${AppRoutes.receivePayment}?partyType=${payerType.toJson()}&partyId=$partyId'),
              icon: const Icon(Icons.credit_card, size: 16),
              label: const Text('Receive Payment'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: _DetailTabButton(
                  label: 'Orders (${partyOrders.length})',
                  selected: _activeTab == _DetailTab.orders,
                  onTap: () => setState(() => _activeTab = _DetailTab.orders),
                ),
              ),
              Expanded(
                child: _DetailTabButton(
                  label: 'Payments (${partyPayments.length})',
                  selected: _activeTab == _DetailTab.payments,
                  onTap: () => setState(() => _activeTab = _DetailTab.payments),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_outlined, size: 14),
                label: Text(
                  _dateRange == null
                      ? 'Filter by Date'
                      : _dateRange!.start == _dateRange!.end
                          ? formatShortDate(_dateRange!.start.toIso8601String())
                          : '${formatShortDate(_dateRange!.start.toIso8601String())} – ${formatShortDate(_dateRange!.end.toIso8601String())}',
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (_dateRange != null)
              IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _dateRange = null)),
          ],
        ),
        const SizedBox(height: 12),
        if (_activeTab == _DetailTab.orders)
          if (partyOrders.isEmpty)
            _EmptyCard(text: 'No orders billed to this $partyLabel${_dateRange != null ? ' in this date range.' : ' yet.'}')
          else
            for (final o in partyOrders) _OrderRow(order: o)
        else if (partyPayments.isEmpty)
          _EmptyCard(text: 'No payments received from this $partyLabel${_dateRange != null ? ' in this date range.' : ' yet.'}')
        else
          for (final p in partyPayments) _PaymentRow(payment: p),
      ],
    );
  }
}

class _DetailTabButton extends StatelessWidget {
  const _DetailTabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? Colors.white : null, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? const Color(0xFF0C4A6E) : const Color(0xFF475569))),
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
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final due = expectedReceiptFor(order) - order.amountReceived;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(AppRoutes.orderDetailsPath(order.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('#${order.orderNumber}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                StatusBadge(status: order.paymentStatus.jsonValue, type: StatusBadgeType.payment),
                const SizedBox(width: 6),
                StatusBadge(status: order.orderStatus.jsonValue),
              ],
            ),
            const SizedBox(height: 6),
            Text('${formatDate(order.orderDate)} • ${order.numberOfBags} Bags', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bill: ${formatINR(order.charges.totalCustomerBill)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                if (due > 0.01)
                  Text('Due: ${formatINR(due)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)))
                else
                  const Text('Fully Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final PaymentReceipt payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatINR(payment.amountReceived), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF047857))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(999)),
                child: Text(payment.receiptNumber, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF047857), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatDate(payment.paymentDate)} via ${payment.paymentMethod.jsonValue}'
            '${payment.referenceNumber.isNotEmpty ? ' • Ref: ${payment.referenceNumber}' : ''}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          if (payment.allocations.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Applied to: ${payment.allocations.map((a) => a.orderNumber).join(', ')}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
            ),
          ],
          if (payment.unallocatedAmount > 0.01) ...[
            const SizedBox(height: 4),
            Text(
              'Unallocated credit: ${formatINR(payment.unallocatedAmount)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
