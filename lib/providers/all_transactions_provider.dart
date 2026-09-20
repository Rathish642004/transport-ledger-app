import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/ledger_transaction.dart';
import 'expenses_provider.dart';
import 'orders_provider.dart';
import 'payments_provider.dart';

/// Mirrors the `allTransactions` `useMemo` in `LedgerContext.tsx:402-473` —
/// the 3-source merge (order bills, payments, expenses) sorted
/// date-descending.
final allTransactionsProvider = Provider<List<LedgerTransaction>>((ref) {
  final orders = ref.watch(ordersProvider);
  final payments = ref.watch(paymentsProvider);
  final expenses = ref.watch(expensesProvider);

  final list = <LedgerTransaction>[];

  // 1. Order Billings (Debit: Party owes us)
  for (final o in orders) {
    if (o.orderStatus == OrderStatus.cancelled) continue;
    final isBillCompany = o.billing.billPayer == PayerType.company;
    list.add(LedgerTransaction(
      id: 'bill-${o.id}',
      date: o.orderDate,
      partyType: isBillCompany ? LedgerPartyType.company : LedgerPartyType.customer,
      partyName: isBillCompany ? o.companyName : o.customerName,
      orderNumber: o.orderNumber,
      type: LedgerEntryType.debit,
      amount: o.charges.totalCustomerBill,
      paymentStatus: o.paymentStatus.jsonValue,
      notes: 'Transport Bill for ${o.numberOfBags} bags '
          '(${o.pickupLocation.split(',').first} → ${o.deliveryLocation.split(',').first})',
    ));
  }

  // 2. Customer & Company Receipts (Credit: Money received into our account)
  // — one row per receipt, even when a single lump-sum payment settles many
  // orders (see PaymentReceipt.allocations); the settled orders are listed
  // in the notes rather than split into separate rows.
  for (final p in payments) {
    final allocationNote = p.allocations.isEmpty
        ? ''
        : ' (applied to ${p.allocations.map((a) => a.orderNumber).join(', ')})';
    list.add(LedgerTransaction(
      id: 'pay-${p.id}',
      date: p.paymentDate,
      partyType: p.payerType == PayerType.company ? LedgerPartyType.company : LedgerPartyType.customer,
      partyName: p.payerName,
      orderNumber: p.allocations.length == 1 ? p.allocations.single.orderNumber : null,
      type: LedgerEntryType.credit,
      amount: p.amountReceived,
      paymentStatus: 'Paid',
      paymentMethod: p.paymentMethod.jsonValue,
      referenceNumber: p.referenceNumber,
      notes: 'Payment Received via ${p.paymentMethod.jsonValue}'
          '${p.tdsDeducted > 0 ? ' (TDS: ₹${p.tdsDeducted.round()})' : ''}'
          '$allocationNote',
    ));
  }

  // 3. Operating Expenses
  for (final e in expenses) {
    list.add(LedgerTransaction(
      id: 'exp-${e.id}',
      date: e.date,
      partyType: LedgerPartyType.operatingExpense,
      partyName: e.paidTo,
      orderNumber: e.orderNumber,
      type: LedgerEntryType.debit,
      amount: e.amount,
      paymentStatus: 'Paid',
      paymentMethod: e.paymentMethod.jsonValue,
      notes: '${e.category.jsonValue}: ${e.notes}',
    ));
  }

  list.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
  return list;
});
