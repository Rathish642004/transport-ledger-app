import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/toast_provider.dart';
import '../utils/formatters.dart';

enum _ReportType { pnl, tds, receivables, trips }

/// Ported from `src/screens/ReportsScreen.tsx`. [initialTab] is accepted for
/// interface parity with the router (`AppShell`'s notification bell pushes
/// `/reports?tab=notifications`, matching the `monthly_pnl`/`fy_summary`/
/// `notifications` `ActiveScreen` variants in `LedgerContext.tsx`) but —
/// verified against `App.tsx:64-68` — all four variants render the exact
/// same `<ReportsScreen />` with no props, and the component's own
/// `selectedReport` state always starts at `'pnl'` regardless. So, matching
/// the source faithfully, [initialTab] is deliberately unused here.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _ReportType _selectedReport = _ReportType.pnl;
  String _selectedFY = financialYears.first;

  String _csvNum(double n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  Future<void> _handleExportCSV(List<Order> fyOrders) async {
    final buffer = StringBuffer();

    switch (_selectedReport) {
      case _ReportType.pnl:
        final p = _pnlData(fyOrders);
        buffer.writeln('Financial Statement,Transport Ledger');
        buffer.writeln('Financial Year,$_selectedFY');
        buffer.writeln();
        buffer.writeln('Particulars,Amount (INR)');
        buffer.writeln('Gross Revenue,${_csvNum(p.grossRevenue)}');
        buffer.writeln('Transportation Expense (incl. driver payment),${_csvNum(p.transportationExpense)}');
        buffer.writeln('Loading Expense,${_csvNum(p.loadingExpense)}');
        buffer.writeln('Other Expense,${_csvNum(p.otherExpense)}');
        buffer.writeln('Total Operating Expenses,${_csvNum(p.totalExpenses)}');
        buffer.writeln('Net Profit,${_csvNum(p.netProfit)}');
      case _ReportType.tds:
        final t = _tdsData(fyOrders);
        buffer.writeln('TDS Report under Section 194C');
        buffer.writeln('Financial Year,$_selectedFY');
        buffer.writeln();
        buffer.writeln('Order No,Date,Deductor Party,Gross Bill,TDS %,TDS Deducted (INR)');
        for (final r in t.records) {
          buffer.writeln(
            '${r.orderNumber},${r.orderDate},"${r.billing.billRecipientName}",${_csvNum(r.charges.totalCustomerBill)},'
            '${_csvNum(r.billing.tdsPercentage)}%,${_csvNum(r.billing.tdsAmount)}',
          );
        }
        buffer.writeln('Total TDS Deducted,,,,,${_csvNum(t.totalTds)}');
      case _ReportType.receivables:
        final recs = _receivablesData(fyOrders);
        buffer.writeln('Outstanding Receivables Report');
        buffer.writeln('Financial Year,$_selectedFY');
        buffer.writeln();
        buffer.writeln('Order No,Date,Party,Total Bill,Received,Pending Due');
        for (final r in recs) {
          buffer.writeln('${r.orderNumber},${r.date},"${r.party}",${_csvNum(r.totalBill)},${_csvNum(r.received)},${_csvNum(r.pending)}');
        }
      case _ReportType.trips:
        // Matches the source: `handleExportCSV` has no `trips` branch, so
        // exporting while on the Trip Margin tab produces an empty file.
        break;
    }

    final dir = await getTemporaryDirectory();
    final reportKey = _selectedReport.name;
    final file = File('${dir.path}/${reportKey}_$_selectedFY.csv');
    await file.writeAsString(buffer.toString());

    if (!mounted) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: '$reportKey $_selectedFY'));
  }

  Future<void> _handleShareSummary(List<Order> fyOrders) async {
    final profile = ref.read(profileProvider);
    var text = '*Transport Ledger Report - $_selectedFY*\nTransporter: ${profile.businessName}\n';

    switch (_selectedReport) {
      case _ReportType.pnl:
        final p = _pnlData(fyOrders);
        text += 'Gross Revenue: ${formatINR(p.grossRevenue)}\nTotal Expenses: ${formatINR(p.totalExpenses)}\n'
            '*Net Profit: ${formatINR(p.netProfit)}* (Margin: ${p.profitMargin}%)\nTotal Trips: ${fyOrders.length}';
      case _ReportType.tds:
        final t = _tdsData(fyOrders);
        text += 'Total TDS Deducted under 194C: ${formatINR(t.totalTds)} across ${t.records.length} orders. For 26AS matching.';
      case _ReportType.receivables:
        final recs = _receivablesData(fyOrders);
        final totalPending = recs.fold<double>(0, (s, r) => s + r.pending);
        text += 'Pending Receivables: ${formatINR(totalPending)} across ${recs.length} pending orders.';
      case _ReportType.trips:
        text += 'Total Trips: ${fyOrders.length}';
    }

    final result = await SharePlus.instance.share(ShareParams(text: text, subject: 'Transport Report $_selectedFY'));
    if (result.status == ShareResultStatus.success && mounted) {
      ref.read(toastProvider.notifier).show('Report shared successfully');
    }
  }

  _PnlData _pnlData(List<Order> fyOrders) {
    final grossRevenue = fyOrders.fold<double>(0, (s, o) => s + o.charges.totalCustomerBill);
    final transportationExpense = fyOrders.fold<double>(0, (s, o) => s + o.orderExpenses.transportationCharges);
    final loadingExpense = fyOrders.fold<double>(0, (s, o) => s + o.orderExpenses.loadingCharges);
    final otherExpense = fyOrders.fold<double>(0, (s, o) => s + o.orderExpenses.otherCharges);
    final totalExpenses = transportationExpense + loadingExpense + otherExpense;
    final netProfit = grossRevenue - totalExpenses;
    final profitMargin = grossRevenue > 0 ? (netProfit / grossRevenue * 100).toStringAsFixed(1) : '0';
    return _PnlData(
      grossRevenue: grossRevenue,
      transportationExpense: transportationExpense,
      loadingExpense: loadingExpense,
      otherExpense: otherExpense,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      profitMargin: profitMargin,
    );
  }

  _TdsData _tdsData(List<Order> fyOrders) {
    final records = fyOrders.where((o) => o.billing.tdsApplicable && o.billing.tdsAmount > 0).toList();
    final totalTds = records.fold<double>(0, (s, o) => s + o.billing.tdsAmount);
    return _TdsData(records: records, totalTds: totalTds);
  }

  List<_ReceivableRow> _receivablesData(List<Order> fyOrders) {
    return fyOrders
        .map((o) {
          final netExpected = o.billing.netExpectedReceipt != 0 ? o.billing.netExpectedReceipt : o.charges.totalCustomerBill;
          final pending = netExpected - o.amountReceived;
          return _ReceivableRow(
            orderNumber: o.orderNumber,
            date: o.orderDate,
            party: o.billing.billRecipientName.isNotEmpty ? o.billing.billRecipientName : o.customerName,
            totalBill: o.charges.totalCustomerBill,
            received: o.amountReceived,
            pending: pending < 0 ? 0 : pending,
          );
        })
        .where((r) => r.pending > 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final fyOrders = orders.where((o) => getFinancialYear(o.orderDate) == _selectedFY).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ACCOUNTING REPORTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                      Text('Financial Reports & Tax', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _handleExportCSV(fyOrders),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.download, size: 16, color: Color(0xFF334155)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _handleShareSummary(fyOrders),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF0369A1)),
                        SizedBox(width: 4),
                        Text('Financial Year (Apr-Mar):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _selectedFY,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0C4A6E)),
                      items: [
                        for (final fy in financialYears)
                          DropdownMenuItem(value: fy, child: Text(fy == financialYears.first ? '$fy (Current)' : fy)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedFY = v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFCBD5E1).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(child: _ReportChip(label: 'P&L', selected: _selectedReport == _ReportType.pnl, onTap: () => setState(() => _selectedReport = _ReportType.pnl))),
              Expanded(child: _ReportChip(label: 'TDS 194C', selected: _selectedReport == _ReportType.tds, onTap: () => setState(() => _selectedReport = _ReportType.tds))),
              Expanded(
                child: _ReportChip(label: 'Dues', selected: _selectedReport == _ReportType.receivables, onTap: () => setState(() => _selectedReport = _ReportType.receivables)),
              ),
              Expanded(child: _ReportChip(label: 'Trip Margin', selected: _selectedReport == _ReportType.trips, onTap: () => setState(() => _selectedReport = _ReportType.trips))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        switch (_selectedReport) {
          _ReportType.pnl => _PnlSection(fy: _selectedFY, data: _pnlData(fyOrders)),
          _ReportType.tds => _TdsSection(data: _tdsData(fyOrders)),
          _ReportType.receivables => _ReceivablesSection(rows: _receivablesData(fyOrders)),
          _ReportType.trips => _TripsSection(orders: fyOrders),
        },
      ],
    );
  }
}

class _PnlData {
  const _PnlData({
    required this.grossRevenue,
    required this.transportationExpense,
    required this.loadingExpense,
    required this.otherExpense,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
  });

  final double grossRevenue;
  final double transportationExpense;
  final double loadingExpense;
  final double otherExpense;
  final double totalExpenses;
  final double netProfit;
  final String profitMargin;
}

class _TdsData {
  const _TdsData({required this.records, required this.totalTds});

  final List<Order> records;
  final double totalTds;
}

class _ReceivableRow {
  const _ReceivableRow({
    required this.orderNumber,
    required this.date,
    required this.party,
    required this.totalBill,
    required this.received,
    required this.pending,
  });

  final String orderNumber;
  final String date;
  final String party;
  final double totalBill;
  final double received;
  final double pending;
}

class _ReportChip extends StatelessWidget {
  const _ReportChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? [const BoxShadow(color: Color(0x14000000), blurRadius: 2)] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? const Color(0xFF0C4A6E) : const Color(0xFF475569)),
        ),
      ),
    );
  }
}

class _PnlSection extends StatelessWidget {
  const _PnlSection({required this.fy, required this.data});

  final String fy;
  final _PnlData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$fy BUSINESS PROFITABILITY', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text('${data.profitMargin}% Margin', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6EE7B7))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    const Text('Net Business Profit', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Text(formatINR(data.netProfit), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF34D399))),
                    const SizedBox(height: 6),
                    const Text(
                      'Accrual basis: Total Billed Revenue minus Driver & Operating Costs',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1E293B)))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Earned Revenue', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          Text(formatINR(data.grossRevenue), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Direct Transport Costs', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          Text(formatINR(data.totalExpenses), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFCA5A5))),
                        ],
                      ),
                    ),
                  ],
                ),
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
              Text('REVENUE & EXPENSE BREAKDOWN ($fy)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text('A. Revenue From Operations', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF075985))),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFBAE6FD), width: 2))),
                child: Column(
                  children: [
                    _LineItem('Total Gross Revenue (A)', formatINR(data.grossRevenue), bold: true, topBorder: true, valueColor: const Color(0xFF075985)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('B. Direct Operating Outflow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9F1239))),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFFECDD3), width: 2))),
                child: Column(
                  children: [
                    _LineItem('Transportation Expense (incl. driver payment)', formatINR(data.transportationExpense)),
                    _LineItem('Loading Expense', formatINR(data.loadingExpense)),
                    _LineItem('Other Expense', formatINR(data.otherExpense)),
                    _LineItem('Total Direct Expenses (B)', formatINR(data.totalExpenses), bold: true, topBorder: true, valueColor: const Color(0xFFBE123C)),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 2))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net Business Profit (A - B)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                    Text(formatINR(data.netProfit), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem(this.label, this.value, {this.bold = false, this.topBorder = false, this.valueColor});

  final String label;
  final String value;
  final bool bold;
  final bool topBorder;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: topBorder ? 6 : 3),
      margin: topBorder ? const EdgeInsets.only(top: 2) : null,
      decoration: topBorder ? const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 11, color: const Color(0xFF475569), fontWeight: bold ? FontWeight.w900 : FontWeight.normal)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: valueColor ?? const Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }
}

class _TdsSection extends StatelessWidget {
  const _TdsSection({required this.data});

  final _TdsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            border: Border.all(color: const Color(0xFFFCD34D)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 6),
                  Text('Section 194C TDS Credit Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF78350F))),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'TDS deducted by consignors and consignees for Form 26AS matching and income tax advance credit.',
                style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TOTAL TDS DEDUCTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    Text(formatINR(data.totalTds), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF451A03))),
                  ],
                ),
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
              Text('TDS TRANSACTION REGISTER (${data.records.length} ORDERS)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              for (final r in data.records) ...[
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.orderNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(r.billing.billRecipientName, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatINR(r.billing.tdsAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                        Text('${r.billing.tdsPercentage.toStringAsFixed(0)}% TDS', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date: ${formatDate(r.orderDate)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text('Gross Bill: ${formatINR(r.charges.totalCustomerBill)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceivablesSection extends StatelessWidget {
  const _ReceivablesSection({required this.rows});

  final List<_ReceivableRow> rows;

  @override
  Widget build(BuildContext context) {
    final totalPending = rows.fold<double>(0, (s, r) => s + r.pending);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFFF1F2), border: Border.all(color: const Color(0xFFFECDD3)), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Due from Parties', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF881337))),
                  Text('${rows.length} unpaid / pending trips', style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C))),
                ],
              ),
              Text(formatINR(totalPending), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF9F1239))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final r in rows) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.orderNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(r.party, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatINR(r.pending), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFBE123C))),
                        const Text('Pending Balance', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.only(top: 6),
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gross: ${formatINR(r.totalBill)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text('Received: ${formatINR(r.received)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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

class _TripsSection extends StatelessWidget {
  const _TripsSection({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trip-by-Trip Margin Analysis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
              Text('${orders.length} Trips Recorded', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final ord in orders) ...[
          _TripCard(order: ord),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final profit = order.financialSummary.estimatedProfit;
    final margin = order.charges.totalCustomerBill > 0 ? (profit / order.charges.totalCustomerBill * 100).toStringAsFixed(0) : '0';
    final expenses = order.orderExpenses;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.orderNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                          child: Text(order.vehicleNumber, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text('${order.companyName} → ${order.customerName}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatINR(profit),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: profit >= 0 ? const Color(0xFF047857) : const Color(0xFFBE123C)),
                  ),
                  Text('$margin% Margin', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(top: 6),
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
            child: Row(
              children: [
                Expanded(child: Text('Bill: ${formatINR(order.charges.totalCustomerBill)}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
                Expanded(child: Text('Transport: ${formatINR(expenses.transportationCharges)}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
                Expanded(child: Text('Exp: ${formatINR(expenses.total)}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
