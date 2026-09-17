import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/company.dart';
import '../models/customer.dart';
import '../models/driver.dart';
import '../models/enums.dart';
import '../providers/companies_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/driver_payments_provider.dart';
import '../providers/drivers_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/payments_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';

enum _LedgerTab { companies, customers, drivers, cashbook }

/// Ported from `src/screens/LedgerScreen.tsx`.
///
/// The source's cash-book builder reads `ex.expenseDate`/`ex.description` on
/// `ExpenseRecord` — fields that don't actually exist on that type (see the
/// same mismatch noted in `ExpenseEntryScreen`, which is what actually
/// writes those records using the real `date`/`notes` fields). Using the
/// real field names here instead of reproducing broken date-sorting.
class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _CashbookEntry {
  const _CashbookEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.party,
    required this.isInflow,
    required this.amount,
    required this.method,
    required this.ref,
  });

  final String id;
  final String date;
  final String title;
  final String subtitle;
  final String party;
  final bool isInflow;
  final double amount;
  final String method;
  final String ref;
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  _LedgerTab _activeTab = _LedgerTab.companies;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final companies = ref.watch(companiesProvider);
    final customers = ref.watch(customersProvider);
    final drivers = ref.watch(driversProvider);
    final payments = ref.watch(paymentsProvider);
    final driverPayments = ref.watch(driverPaymentsProvider);
    final expenses = ref.watch(expensesProvider);
    final q = _search.toLowerCase();

    Widget body;
    switch (_activeTab) {
      case _LedgerTab.companies:
        final rows = companies.where((c) => c.name.toLowerCase().contains(q) || c.city.toLowerCase().contains(q));
        body = Column(children: [for (final c in rows) _CompanyRow(company: c, orders: orders)]);
      case _LedgerTab.customers:
        final rows = customers.where((c) => c.name.toLowerCase().contains(q) || c.city.toLowerCase().contains(q));
        body = Column(children: [for (final c in rows) _CustomerRow(customer: c, orders: orders)]);
      case _LedgerTab.drivers:
        final rows = drivers.where((d) => d.name.toLowerCase().contains(q) || d.vehicleNumber.toLowerCase().contains(q));
        body = Column(children: [for (final d in rows) _DriverRow(driver: d, orders: orders)]);
      case _LedgerTab.cashbook:
        final entries = _buildCashbook(payments, driverPayments, expenses);
        body = _CashbookPanel(entries: entries);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('PARTY STATEMENTS & BOOKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
        const Text('Financial Ledger', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(child: _TabButton(label: 'Company', selected: _activeTab == _LedgerTab.companies, onTap: () => setState(() => _activeTab = _LedgerTab.companies))),
              Expanded(child: _TabButton(label: 'Customer', selected: _activeTab == _LedgerTab.customers, onTap: () => setState(() => _activeTab = _LedgerTab.customers))),
              Expanded(child: _TabButton(label: 'Drivers', selected: _activeTab == _LedgerTab.drivers, onTap: () => setState(() => _activeTab = _LedgerTab.drivers))),
              Expanded(child: _TabButton(label: 'Cash Book', selected: _activeTab == _LedgerTab.cashbook, onTap: () => setState(() => _activeTab = _LedgerTab.cashbook))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _search = v),
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search in ${_activeTab.name}...',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 10),
        body,
      ],
    );
  }

  List<_CashbookEntry> _buildCashbook(List<dynamic> payments, List<dynamic> driverPayments, List<dynamic> expenses) {
    final list = <_CashbookEntry>[];
    for (final p in payments) {
      list.add(_CashbookEntry(
        id: p.id as String,
        date: p.paymentDate as String,
        title: 'Payment Received (${(p.payerType as PayerType).jsonValue})',
        subtitle: 'Order #${p.orderNumber} • ${p.receiptNumber}',
        party: p.payerName as String,
        isInflow: true,
        amount: p.amountReceived as double,
        method: (p.paymentMethod as PaymentMethod).jsonValue,
        ref: p.referenceNumber as String,
      ));
    }
    for (final dp in driverPayments) {
      list.add(_CashbookEntry(
        id: dp.id as String,
        date: dp.paymentDate as String,
        title: 'Driver Freight Paid',
        subtitle: 'Order #${dp.orderNumber} • ${dp.driverBillNumber}',
        party: dp.driverName as String,
        isInflow: false,
        amount: dp.amountPaid as double,
        method: (dp.paymentMethod as PaymentMethod).jsonValue,
        ref: dp.referenceNumber as String,
      ));
    }
    for (final ex in expenses) {
      list.add(_CashbookEntry(
        id: ex.id as String,
        date: ex.date as String,
        title: (ex.category as ExpenseCategory).jsonValue,
        subtitle: ex.notes as String,
        party: (ex.vehicleNumber as String?) ?? '',
        isInflow: false,
        amount: ex.amount as double,
        method: (ex.paymentMethod as PaymentMethod).jsonValue,
        ref: (ex.vehicleNumber as String?) ?? '',
      ));
    }
    list.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
    return list;
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

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

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: child,
    );
  }
}

class _CompanyRow extends ConsumerWidget {
  const _CompanyRow({required this.company, required this.orders});

  final Company company;
  final List<dynamic> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compOrders = orders.where((o) => o.companyId == company.id || o.companyName == company.name);
    var totalBilled = 0.0, totalTds = 0.0, totalReceived = 0.0, netExpected = 0.0;
    var count = 0;
    for (final o in compOrders) {
      count++;
      totalBilled += o.charges.totalCustomerBill as double;
      totalTds += o.billing.tdsAmount as double;
      totalReceived += o.amountReceived as double;
      final net = o.billing.netExpectedReceipt as double;
      netExpected += net != 0 ? net : o.charges.totalCustomerBill as double;
    }
    final balance = (netExpected - totalReceived).clamp(0, double.infinity);

    return _LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    Text('${company.city} • $count Orders', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('RECEIVABLE DUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  Text(formatINR(balance), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: balance > 0 ? const Color(0xFFBE123C) : const Color(0xFF047857))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: _MiniStat('Total Billed', formatINR(totalBilled), const Color(0xFF1E293B))),
                Expanded(child: _MiniStat('TDS Deducted', formatINR(totalTds), const Color(0xFFB45309))),
                Expanded(child: _MiniStat('Recv Cash', formatINR(totalReceived), const Color(0xFF047857))),
              ],
            ),
          ),
          if (balance > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                onPressed: () => context.push('${AppRoutes.receivePayment}?partyType=Company&partyId=${company.id}'),
                child: const Text('Receive Payment', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerRow extends ConsumerWidget {
  const _CustomerRow({required this.customer, required this.orders});

  final Customer customer;
  final List<dynamic> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custOrders = orders.where((o) => o.customerId == customer.id || o.customerName == customer.name);
    var totalBilled = 0.0, totalTds = 0.0, totalReceived = 0.0, netExpected = 0.0;
    var count = 0;
    for (final o in custOrders) {
      count++;
      totalBilled += o.charges.totalCustomerBill as double;
      totalTds += o.billing.tdsAmount as double;
      totalReceived += o.amountReceived as double;
      final net = o.billing.netExpectedReceipt as double;
      netExpected += net != 0 ? net : o.charges.totalCustomerBill as double;
    }
    final balance = (netExpected - totalReceived).clamp(0, double.infinity);

    return _LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    Text('${customer.city} • $count Orders', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('RECEIVABLE DUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  Text(formatINR(balance), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: balance > 0 ? const Color(0xFFBE123C) : const Color(0xFF047857))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: _MiniStat('Total Billed', formatINR(totalBilled), const Color(0xFF1E293B))),
                Expanded(child: _MiniStat('TDS Deducted', formatINR(totalTds), const Color(0xFFB45309))),
                Expanded(child: _MiniStat('Recv Cash', formatINR(totalReceived), const Color(0xFF047857))),
              ],
            ),
          ),
          if (balance > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                onPressed: () => context.push('${AppRoutes.receivePayment}?partyType=Customer&partyId=${customer.id}'),
                child: const Text('Receive Payment', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverRow extends ConsumerWidget {
  const _DriverRow({required this.driver, required this.orders});

  final Driver driver;
  final List<dynamic> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drvOrders = orders.where((o) => o.driverId == driver.id || o.driverName == driver.name);
    var totalAgreed = 0.0, totalPaid = 0.0;
    var count = 0;
    for (final o in drvOrders) {
      count++;
      totalAgreed += o.driverExpense.driverFreight as double;
      totalPaid += o.driverExpense.driverPaidAmount as double;
    }
    final balance = (totalAgreed - totalPaid).clamp(0, double.infinity);

    return _LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(driver.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                          child: Text(driver.vehicleNumber, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text('$count Trips Driven', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('PAYABLE BALANCE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  Text(formatINR(balance), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: balance > 0 ? const Color(0xFFBE123C) : const Color(0xFF047857))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: _MiniStat('Total Agreed Freight', formatINR(totalAgreed), const Color(0xFF1E293B))),
                Expanded(child: _MiniStat('Total Disbursed', formatINR(totalPaid), const Color(0xFF047857))),
              ],
            ),
          ),
          if (balance > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                onPressed: () => context.push('${AppRoutes.payDriver}?driverId=${driver.id}'),
                child: const Text('Pay Freight', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _CashbookPanel extends StatelessWidget {
  const _CashbookPanel({required this.entries});

  final List<_CashbookEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CASH & BANK MOVEMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  Text('Chronological Transaction Log', style: TextStyle(color: Color(0xFF7DD3FC), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Entries', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                  Text('${entries.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        for (final tx in entries)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: tx.isInflow ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10)),
                  child: Icon(tx.isInflow ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: tx.isInflow ? const Color(0xFF047857) : const Color(0xFFBE123C)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('${tx.party} • ${tx.subtitle}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                      Text('${formatDate(tx.date)} • ${tx.method} • Ref: ${tx.ref}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${tx.isInflow ? '+' : '-'}${formatINR(tx.amount)}',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: tx.isInflow ? const Color(0xFF047857) : const Color(0xFFBE123C)),
                    ),
                    Text(tx.isInflow ? 'INFLOW' : 'OUTFLOW', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
