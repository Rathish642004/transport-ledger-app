import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/company.dart';
import '../models/customer.dart';
import '../models/enums.dart';
import '../models/party_ledger.dart';
import '../providers/companies_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/party_ledger_provider.dart';
import '../providers/payments_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_list_panel.dart';

enum _LedgerTab { companies, customers, cashbook }

/// Ported from `src/screens/LedgerScreen.tsx`. Party balances are read from
/// [partyLedgerProvider] — the single place the `billPayer` rule lives —
/// rather than recomputed per-row here, which used to double-count a
/// customer-billed order's receivable onto the company card too (every
/// order carries both a `companyId` and a `customerId`).
class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  late _LedgerTab _activeTab;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _activeTab = switch (widget.initialTab) {
      'companies' => _LedgerTab.companies,
      'customers' => _LedgerTab.customers,
      'cashbook' => _LedgerTab.cashbook,
      _ => _LedgerTab.companies,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(companiesProvider);
    final customers = ref.watch(customersProvider);
    final ledgers = ref.watch(partyLedgerProvider);
    final payments = ref.watch(paymentsProvider);
    final expenses = ref.watch(expensesProvider);
    final q = _search.toLowerCase();

    Widget body;
    switch (_activeTab) {
      case _LedgerTab.companies:
        final rows = companies.where((c) => c.name.toLowerCase().contains(q) || c.city.toLowerCase().contains(q));
        body = Column(children: [for (final c in rows) _CompanyRow(company: c, ledger: ledgerFor(ledgers, PayerType.company, c.id))]);
      case _LedgerTab.customers:
        final rows = customers.where((c) => c.name.toLowerCase().contains(q) || c.city.toLowerCase().contains(q));
        body = Column(children: [for (final c in rows) _CustomerRow(customer: c, ledger: ledgerFor(ledgers, PayerType.customer, c.id))]);
      case _LedgerTab.cashbook:
        final entries = _buildCashbook(payments, expenses);
        body = TransactionListPanel(entries: entries);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PARTY STATEMENTS & BOOKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                  Text('Financial Ledger', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (_activeTab != _LedgerTab.cashbook)
              TextButton.icon(
                onPressed: () => switch (_activeTab) {
                  _LedgerTab.companies => context.push(AppRoutes.companiesEdit),
                  _LedgerTab.customers => context.push(AppRoutes.customersEdit),
                  _LedgerTab.cashbook => null,
                },
                icon: const Icon(Icons.add, size: 14),
                label: Text('Add ${switch (_activeTab) {
                  _LedgerTab.companies => 'Company',
                  _LedgerTab.customers => 'Customer',
                  _LedgerTab.cashbook => '',
                }}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(child: _TabButton(label: 'Company', selected: _activeTab == _LedgerTab.companies, onTap: () => setState(() => _activeTab = _LedgerTab.companies))),
              Expanded(child: _TabButton(label: 'Customer', selected: _activeTab == _LedgerTab.customers, onTap: () => setState(() => _activeTab = _LedgerTab.customers))),
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
        body,
      ],
    );
  }

  List<TransactionEntry> _buildCashbook(List<dynamic> payments, List<dynamic> expenses) {
    final list = <TransactionEntry>[];
    for (final p in payments) {
      final allocations = p.allocations as List<dynamic>;
      list.add(TransactionEntry(
        id: p.id as String,
        date: p.paymentDate as String,
        title: 'Payment Received (${(p.payerType as PayerType).jsonValue})',
        subtitle: allocations.isEmpty ? p.receiptNumber as String : '${allocations.map((a) => a.orderNumber).join(', ')} • ${p.receiptNumber}',
        party: p.payerName as String,
        isInflow: true,
        amount: p.amountReceived as double,
        method: (p.paymentMethod as PaymentMethod).jsonValue,
        ref: p.referenceNumber as String,
      ));
    }
    for (final ex in expenses) {
      list.add(TransactionEntry(
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
  const _LedgerCard({required this.child, this.onTap});

  final Widget child;

  /// Opens that party's ledger detail screen — the edit icon and Receive
  /// Payment button inside [child] are their own tap targets and win the
  /// gesture arena over this outer one, so they still work independently.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(14), child: child),
        ),
      ),
    );
  }
}

class _CompanyRow extends StatelessWidget {
  const _CompanyRow({required this.company, required this.ledger});

  final Company company;
  final PartyLedger ledger;

  @override
  Widget build(BuildContext context) {
    return _LedgerCard(
      onTap: () => context.push(AppRoutes.companyLedgerPath(company.id)),
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
                    Text(company.city, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('RECEIVABLE DUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  Text(formatINR(ledger.outstanding), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: ledger.outstanding > 0 ? const Color(0xFFBE123C) : const Color(0xFF047857))),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.push('${AppRoutes.companiesEdit}?id=${company.id}'),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: _MiniStat('Total Billed', formatINR(ledger.totalBilled), const Color(0xFF1E293B))),
                Expanded(child: _MiniStat('TDS Withheld', formatINR(ledger.tdsWithheldTotal), const Color(0xFFB45309))),
                Expanded(child: _MiniStat('Recv Cash', formatINR(ledger.received), const Color(0xFF047857))),
              ],
            ),
          ),
          if (ledger.unallocatedCredit > 0) ...[
            const SizedBox(height: 6),
            Text('Unallocated credit: ${formatINR(ledger.unallocatedCredit)}', style: const TextStyle(fontSize: 10, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
          ],
          if (ledger.outstanding > 0 || ledger.unallocatedCredit > 0) ...[
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

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer, required this.ledger});

  final Customer customer;
  final PartyLedger ledger;

  @override
  Widget build(BuildContext context) {
    return _LedgerCard(
      onTap: () => context.push(AppRoutes.customerLedgerPath(customer.id)),
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
                    Text(customer.city, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('RECEIVABLE DUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  Text(formatINR(ledger.outstanding), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: ledger.outstanding > 0 ? const Color(0xFFBE123C) : const Color(0xFF047857))),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.push('${AppRoutes.customersEdit}?id=${customer.id}'),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: _MiniStat('Total Billed', formatINR(ledger.totalBilled), const Color(0xFF1E293B))),
                Expanded(child: _MiniStat('TDS Withheld', formatINR(ledger.tdsWithheldTotal), const Color(0xFFB45309))),
                Expanded(child: _MiniStat('Recv Cash', formatINR(ledger.received), const Color(0xFF047857))),
              ],
            ),
          ),
          if (ledger.unallocatedCredit > 0) ...[
            const SizedBox(height: 6),
            Text('Unallocated credit: ${formatINR(ledger.unallocatedCredit)}', style: const TextStyle(fontSize: 10, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
          ],
          if (ledger.outstanding > 0 || ledger.unallocatedCredit > 0) ...[
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
