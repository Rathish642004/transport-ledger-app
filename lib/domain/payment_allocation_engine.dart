import '../models/enums.dart';
import '../models/order.dart';
import '../models/payment_allocation.dart';

/// An order's expected receipt — net of TDS/other deductions when set,
/// otherwise the gross bill. Shared by the allocation engine and every
/// screen/provider that shows "how much is actually due" for an order.
double expectedReceiptFor(Order order) =>
    order.billing.netExpectedReceipt != 0 ? order.billing.netExpectedReceipt : order.charges.totalCustomerBill;

/// The still-open (not cancelled) orders billed to [partyId] as the given
/// [payerType], oldest-first (`orderDate` then `createdAt`) — the FIFO
/// sequence a lump-sum payment is applied against. Matches by id only, never
/// by name (see the ledger double-count bug this replaces).
List<Order> openOrdersForParty(
  List<Order> orders, {
  required PayerType payerType,
  required String partyId,
}) {
  final matches = orders.where((o) {
    if (o.orderStatus == OrderStatus.cancelled) return false;
    if (o.billing.billPayer != payerType) return false;
    return payerType == PayerType.company ? o.companyId == partyId : o.customerId == partyId;
  }).toList();
  matches.sort((a, b) {
    final byDate = a.orderDate.compareTo(b.orderDate);
    if (byDate != 0) return byDate;
    return a.createdAt.compareTo(b.createdAt);
  });
  return matches;
}

/// Allocates [amount] across [openOrders] oldest-first, skipping whatever
/// each order has already had allocated (via [alreadyAllocated], keyed by
/// order id — from other receipts, or from allocations excluded by the
/// caller e.g. when the user unticks an order in the payment screen).
///
/// TDS reduces an order's expected receipt (see [expectedReceiptFor]), so an
/// order can close before its gross bill is fully covered — that's correct,
/// since the TDS portion is never actually received in cash. An allocation
/// records [PaymentAllocation.tdsSettled] only when it fully closes the
/// order, which is what lets a party's "TDS withheld" total be computed by
/// summing settled TDS across their orders.
///
/// Any leftover after every open order is fully covered is simply not
/// allocated — it becomes the payment's unallocated credit
/// (`PaymentReceipt.unallocatedAmount`).
List<PaymentAllocation> allocateFifo({
  required List<Order> openOrders,
  required Map<String, double> alreadyAllocated,
  required double amount,
}) {
  var remaining = amount;
  final allocations = <PaymentAllocation>[];

  for (final order in openOrders) {
    if (remaining <= 0.01) break;
    final expected = expectedReceiptFor(order);
    final already = alreadyAllocated[order.id] ?? 0;
    final dueNow = expected - already;
    if (dueNow <= 0.01) continue;

    final applied = remaining < dueNow ? remaining : dueNow;
    final closesOrder = applied >= dueNow - 0.01;
    allocations.add(PaymentAllocation(
      orderId: order.id,
      orderNumber: order.orderNumber,
      amount: applied,
      tdsSettled: closesOrder ? order.billing.tdsAmount : 0,
    ));
    remaining -= applied;
  }

  return allocations;
}
