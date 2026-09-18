import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// One inflow/outflow row — shared by the Ledger screen's Cash Book tab and
/// the per-bank transactions screen.
class TransactionEntry {
  const TransactionEntry({
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

/// Renders a dark summary header (entry count) followed by one card per
/// [TransactionEntry], newest first. Extracted from `LedgerScreen`'s Cash
/// Book tab so `BankTransactionsScreen` can show the same layout filtered to
/// a single bank account.
class TransactionListPanel extends StatelessWidget {
  const TransactionListPanel({
    super.key,
    required this.entries,
    this.headerEyebrow = 'CASH & BANK MOVEMENT',
    this.headerTitle = 'Chronological Transaction Log',
    this.emptyLabel = 'No transactions yet.',
  });

  final List<TransactionEntry> entries;
  final String headerEyebrow;
  final String headerTitle;
  final String emptyLabel;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headerEyebrow, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  Text(headerTitle, style: const TextStyle(color: Color(0xFF7DD3FC), fontWeight: FontWeight.bold, fontSize: 12)),
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
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(emptyLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
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
