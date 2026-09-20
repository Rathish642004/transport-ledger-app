import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/payment_allocation_engine.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/party_ledger.dart';
import 'orders_provider.dart';
import 'payments_provider.dart';

String partyLedgerKey(PayerType payerType, String partyId) => '${payerType.jsonValue}:$partyId';

PartyLedger ledgerFor(Map<String, PartyLedger> ledgers, PayerType payerType, String partyId) =>
    ledgers[partyLedgerKey(payerType, partyId)] ?? PartyLedger.empty;

/// The single source of truth for "which party does an order's receivable
/// belong to" (`order.billing.billPayer` + the matching id) — every screen
/// that shows a customer's or company's running balance reads this instead
/// of recomputing its own aggregation. This replaces the bug where
/// `ledger_screen` summed orders by id alone with no `billPayer` check, so
/// one order posted its receivable to both its customer's and its company's
/// card at once.
final partyLedgerProvider = Provider<Map<String, PartyLedger>>((ref) {
  final orders = ref.watch(ordersProvider);
  final payments = ref.watch(paymentsProvider);

  final byParty = <String, List<Order>>{};
  for (final o in orders) {
    if (o.orderStatus == OrderStatus.cancelled) continue;
    final partyId = o.billing.billPayer == PayerType.company ? o.companyId : o.customerId;
    final key = partyLedgerKey(o.billing.billPayer, partyId);
    (byParty[key] ??= []).add(o);
  }

  final creditByParty = <String, double>{};
  for (final p in payments) {
    final partyId = p.partyId;
    if (partyId == null) continue;
    final key = partyLedgerKey(p.payerType, partyId);
    creditByParty[key] = (creditByParty[key] ?? 0) + p.unallocatedAmount;
  }

  final result = <String, PartyLedger>{};
  for (final key in {...byParty.keys, ...creditByParty.keys}) {
    final partyOrders = [...byParty[key] ?? const <Order>[]]
      ..sort((a, b) {
        final byDate = a.orderDate.compareTo(b.orderDate);
        return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
      });

    var totalBilled = 0.0, expectedReceipt = 0.0, received = 0.0;
    var tdsWithheldTotal = 0.0, tdsOutstanding = 0.0;
    var totalBags = 0;
    final openOrders = <Order>[];
    for (final o in partyOrders) {
      totalBags += o.numberOfBags;
      totalBilled += o.charges.totalCustomerBill;
      final expected = expectedReceiptFor(o);
      expectedReceipt += expected;
      received += o.amountReceived;
      tdsWithheldTotal += o.billing.tdsAmount;
      if (o.amountReceived < expected - 0.01) {
        openOrders.add(o);
        tdsOutstanding += o.billing.tdsAmount;
      }
    }

    final outstanding = expectedReceipt - received;
    result[key] = PartyLedger(
      orderCount: partyOrders.length,
      totalBags: totalBags,
      totalBilled: totalBilled,
      expectedReceipt: expectedReceipt,
      received: received,
      outstanding: outstanding < 0 ? 0 : outstanding,
      tdsWithheldTotal: tdsWithheldTotal,
      tdsOutstanding: tdsOutstanding,
      unallocatedCredit: creditByParty[key] ?? 0,
      openOrders: openOrders,
    );
  }
  return result;
});
