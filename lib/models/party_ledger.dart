import 'order.dart';

/// A single party's (customer or company) running ledger — derived from
/// orders + payments, never persisted. See `partyLedgerProvider`, the one
/// place the "which party does an order's receivable belong to" rule lives.
class PartyLedger {
  const PartyLedger({
    required this.orderCount,
    required this.totalBags,
    required this.totalBilled,
    required this.expectedReceipt,
    required this.received,
    required this.outstanding,
    required this.tdsWithheldTotal,
    required this.tdsOutstanding,
    required this.unallocatedCredit,
    required this.openOrders,
  });

  /// Count of this party's non-cancelled orders.
  final int orderCount;

  /// Total bags across this party's non-cancelled orders.
  final int totalBags;

  /// Sum of every non-cancelled order's gross bill (`qty * ratePerBag`).
  final double totalBilled;

  /// Sum of every non-cancelled order's net-of-TDS expected receipt.
  final double expectedReceipt;

  /// Sum of every order's `amountReceived`.
  final double received;

  /// `expectedReceipt - received`, floored at 0.
  final double outstanding;

  /// TDS recorded as settled across every closed order (see
  /// `PaymentAllocation.tdsSettled`) plus TDS still pending on open orders —
  /// i.e. the total TDS this party will withhold across all their orders.
  final double tdsWithheldTotal;

  /// TDS still outstanding on orders that aren't fully paid yet.
  final double tdsOutstanding;

  /// Money received from this party beyond what FIFO could allocate to an
  /// open order — sits as credit until applied to a new/reopened order.
  final double unallocatedCredit;

  /// This party's still-open (not cancelled, not fully paid) orders,
  /// oldest-first — the FIFO queue a new payment is allocated against.
  final List<Order> openOrders;

  static const empty = PartyLedger(
    orderCount: 0,
    totalBags: 0,
    totalBilled: 0,
    expectedReceipt: 0,
    received: 0,
    outstanding: 0,
    tdsWithheldTotal: 0,
    tdsOutstanding: 0,
    unallocatedCredit: 0,
    openOrders: [],
  );
}
