import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/bank_account.dart';
import '../providers/banks_provider.dart';
import '../providers/driver_payments_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/payments_provider.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_list_panel.dart';

/// New screen — not in the React source. Shows every payment received,
/// driver payment, and expense recorded against one [BankAccount], with a
/// running in/out summary. The counterpart to `BanksListScreen`.
class BankTransactionsScreen extends ConsumerWidget {
  const BankTransactionsScreen({super.key, required this.bankAccountId});

  final String bankAccountId;

  List<TransactionEntry> _buildEntries(WidgetRef ref) {
    final payments = ref.watch(paymentsProvider).where((p) => p.bankAccountId == bankAccountId);
    final driverPayments = ref.watch(driverPaymentsProvider).where((dp) => dp.bankAccountId == bankAccountId);
    final expenses = ref.watch(expensesProvider).where((e) => e.bankAccountId == bankAccountId);

    final list = <TransactionEntry>[];
    for (final p in payments) {
      list.add(TransactionEntry(
        id: p.id,
        date: p.paymentDate,
        title: 'Payment Received (${p.payerType.jsonValue})',
        subtitle: 'Order #${p.orderNumber} • ${p.receiptNumber}',
        party: p.payerName,
        isInflow: true,
        amount: p.amountReceived,
        method: p.paymentMethod.jsonValue,
        ref: p.referenceNumber,
      ));
    }
    for (final dp in driverPayments) {
      list.add(TransactionEntry(
        id: dp.id,
        date: dp.paymentDate,
        title: 'Driver Freight Paid',
        subtitle: 'Order #${dp.orderNumber} • ${dp.driverBillNumber}',
        party: dp.driverName,
        isInflow: false,
        amount: dp.amountPaid,
        method: dp.paymentMethod.jsonValue,
        ref: dp.referenceNumber,
      ));
    }
    for (final ex in expenses) {
      list.add(TransactionEntry(
        id: ex.id,
        date: ex.date,
        title: ex.category.jsonValue,
        subtitle: ex.notes,
        party: ex.vehicleNumber ?? '',
        isInflow: false,
        amount: ex.amount,
        method: ex.paymentMethod.jsonValue,
        ref: ex.vehicleNumber ?? '',
      ));
    }
    list.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banks = ref.watch(banksProvider);
    BankAccount? bank;
    for (final b in banks) {
      if (b.id == bankAccountId) bank = b;
    }

    if (bank == null) {
      return const Center(child: Text('This bank account no longer exists.'));
    }

    final entries = _buildEntries(ref);
    final totalIn = entries.where((e) => e.isInflow).fold<double>(0, (s, e) => s + e.amount);
    final totalOut = entries.where((e) => !e.isInflow).fold<double>(0, (s, e) => s + e.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bank.bankName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  Text('${bank.accountNumber} • ${bank.ifscCode}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total In', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    Text(formatINR(totalIn), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF34D399))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Out', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    Text(formatINR(totalOut), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFFCA5A5))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Net', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    Text(formatINR(totalIn - totalOut), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TransactionListPanel(
          entries: entries,
          headerEyebrow: 'BANK ACCOUNT ACTIVITY',
          headerTitle: 'Transactions for this Account',
          emptyLabel: 'No payments, driver payments, or expenses have been recorded against this account yet.',
        ),
      ],
    );
  }
}
