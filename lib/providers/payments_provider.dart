import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/payment_allocation.dart';
import '../models/payment_receipt.dart';
import '../storage/hive_boxes.dart';
import 'orders_provider.dart';
import 'toast_provider.dart';

/// Mirrors `receivePayment` in `LedgerContext.tsx:599-663`, restructured
/// around party-level lump-sum payments allocated across many orders (FIFO)
/// instead of one payment per order. `Order.amountReceived`/`paymentStatus`
/// are never touched directly here — every mutation ends by recomputing the
/// affected orders' totals from the full set of receipts via
/// [OrdersNotifier.recomputeFromAllocations], so there's no delta arithmetic
/// to get wrong on edit/remove/cascade-delete.
class PaymentsNotifier extends Notifier<List<PaymentReceipt>> {
  @override
  List<PaymentReceipt> build() => paymentsOrderedIndex.read();

  // See OrdersNotifier._commit — same reasoning, same fix.
  void _commit(List<PaymentReceipt> next) {
    paymentsOrderedIndex.write(next);
    state = next;
  }

  /// Sums every receipt's allocation to each order id, across ALL receipts —
  /// what `Order.amountReceived` must equal after any payment mutation.
  Map<String, double> _totalsByOrder(List<PaymentReceipt> receipts) {
    final totals = <String, double>{};
    for (final r in receipts) {
      for (final a in r.allocations) {
        totals[a.orderId] = (totals[a.orderId] ?? 0) + a.amount;
      }
    }
    return totals;
  }

  void _recompute(Set<String> orderIds) {
    if (orderIds.isEmpty) return;
    ref.read(ordersProvider.notifier).recomputeFromAllocations(orderIds, _totalsByOrder(state));
  }

  /// Records a party-level payment already allocated (typically via
  /// `allocateFifo`, possibly adjusted by the user unticking/ticking orders
  /// in the payment screen) across [allocations]. Anything in
  /// [amountReceived] beyond the sum of [allocations] becomes unallocated
  /// credit against the party — see `PaymentReceipt.unallocatedAmount`.
  PaymentReceipt receivePayment({
    required String partyId,
    required PayerType payerType,
    required String payerName,
    required double amountReceived,
    required String paymentDate,
    required PaymentMethod paymentMethod,
    required double otherDeduction,
    required String referenceNumber,
    required String notes,
    String? bankAccountId,
    List<PaymentAllocation> allocations = const [],
  }) {
    // Note: numbering literally hardcodes "2026" in the source app, not the
    // current year — preserved as-is for parity with LedgerContext.tsx:600.
    final receiptNumber = 'RCT-2026-${(state.length + 43).toString().padLeft(3, '0')}';
    final tdsDeducted = allocations.fold(0.0, (sum, a) => sum + a.tdsSettled);
    final newReceipt = PaymentReceipt(
      id: 'rct-${DateTime.now().millisecondsSinceEpoch}',
      receiptNumber: receiptNumber,
      partyId: partyId,
      payerType: payerType,
      payerName: payerName,
      amountReceived: amountReceived,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      tdsDeducted: tdsDeducted,
      otherDeduction: otherDeduction,
      referenceNumber: referenceNumber,
      notes: notes,
      recordedAt: DateTime.now().toIso8601String(),
      bankAccountId: bankAccountId,
      allocations: allocations,
    );

    _commit([newReceipt, ...state]);
    _recompute(allocations.map((a) => a.orderId).toSet());

    ref.read(toastProvider.notifier).show('Payment of ₹${amountReceived.round()} recorded');
    return newReceipt;
  }

  /// Undoes a payment recorded by mistake (including one added after the
  /// order was already fully paid) — not in the source, which has no way to
  /// remove a receipt at all.
  void removePayment(String id) {
    final payment = state.where((p) => p.id == id).firstOrNull;
    if (payment == null) return;

    final affected = payment.allocations.map((a) => a.orderId).toSet();
    // Not `_commit`, which only ever `put`s — never removes the stale entry
    // from the underlying box (see `BanksNotifier.deleteBankAccount`, the
    // same reasoning for a plain box; `paymentsOrderedIndex` is the ordered
    // equivalent).
    paymentsOrderedIndex.delete(id);
    state = state.where((p) => p.id != id).toList();
    _recompute(affected);
    ref.read(toastProvider.notifier).show('Payment removed', ToastType.info);
  }

  /// Edits an existing receipt in place (amount, method, reference, notes,
  /// and/or its allocations). Recomputes the union of the old and new
  /// allocations' orders, so an order dropped from the allocation correctly
  /// reverts too.
  void updatePayment(PaymentReceipt updated) {
    final old = state.where((p) => p.id == updated.id).firstOrNull;
    if (old == null) return;

    final affected = {
      ...old.allocations.map((a) => a.orderId),
      ...updated.allocations.map((a) => a.orderId),
    };
    _commit([for (final p in state) if (p.id == updated.id) updated else p]);
    _recompute(affected);
    ref.read(toastProvider.notifier).show('Payment updated');
  }

  /// Strips [orderId]'s allocation from every receipt that has one, without
  /// deleting the receipts themselves — the money really was received, so it
  /// simply becomes unallocated credit against the party. Called when an
  /// order is deleted, so no receipt is left pointing at a nonexistent order.
  void stripOrderAllocations(String orderId) {
    var changed = false;
    final next = <PaymentReceipt>[];
    for (final p in state) {
      if (p.allocations.any((a) => a.orderId == orderId)) {
        changed = true;
        next.add(p.copyWith(allocations: [for (final a in p.allocations) if (a.orderId != orderId) a]));
      } else {
        next.add(p);
      }
    }
    if (!changed) return;
    _commit(next);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final paymentsProvider = NotifierProvider<PaymentsNotifier, List<PaymentReceipt>>(PaymentsNotifier.new);
