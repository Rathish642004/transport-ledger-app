import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/payment_allocation_engine.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../storage/hive_boxes.dart';
import 'toast_provider.dart';

const _noteMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `toLocaleString('en-IN', {day:'2-digit', month:'short', year:'numeric',
/// hour:'2-digit', minute:'2-digit', hour12:true})` equivalent, used only for
/// the `[timestamp] note text` prefix in [OrdersNotifier.addOrderNote]. A full
/// `formatters.dart` port lands in Phase 4 for the display-facing formatters.
String _formatNoteTimestamp(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = _noteMonths[dt.month - 1];
  var hour = dt.hour % 12;
  if (hour == 0) hour = 12;
  final hourStr = hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'am' : 'pm';
  return '$day $month ${dt.year}, $hourStr:$minute $period';
}

/// Mirrors the order actions in `LedgerContext.tsx:476-596`. The order-side
/// updates from `receivePayment` are no longer imperative deltas — see
/// [recomputeFromAllocations], called by `PaymentsNotifier` after every
/// payment mutation so `amountReceived`/`paymentStatus` are always rebuilt
/// from the current set of allocations (idempotent, so remove/update/delete
/// cascades never need undo arithmetic).
class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() => ordersOrderedIndex.read();

  // Hive's Box iterates in key-sorted order, not insertion order (verified —
  // see OrderedBoxIndex's doc comment), so "newest first" can't be recovered
  // from the box alone after a restart. ordersOrderedIndex persists the
  // explicit order alongside the records.
  void _commit(List<Order> next) {
    ordersOrderedIndex.write(next);
    state = next;
  }

  /// `orderData`'s `id`/`createdAt`/`updatedAt` are placeholders — all three
  /// are overwritten here, matching `Omit<Order, 'id'|'createdAt'|'updatedAt'>`
  /// in the original.
  Order createOrder(Order orderData) {
    final now = DateTime.now().toIso8601String();
    final newOrder = orderData.copyWith(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );

    _commit([newOrder, ...state]);

    ref.read(toastProvider.notifier).show('Order #${newOrder.orderNumber} created successfully');
    return newOrder;
  }

  /// `updates` is the full edited order (id/createdAt are forced back to the
  /// original record's, and updatedAt is bumped), matching how
  /// `CreateOrderScreen` always submits a complete `Order`-shaped payload for
  /// edit-in-place — see the resolved `create_order` navigation payload in
  /// the implementation plan.
  Order? updateOrder(String id, Order updates) {
    Order? result;
    final next = [
      for (final o in state)
        if (o.id == id)
          (result = updates.copyWith(
            id: o.id,
            createdAt: o.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          ))
        else
          o,
    ];
    if (result == null) return null;
    _commit(next);
    ref.read(toastProvider.notifier).show('Order details updated');
    return result;
  }

  void updateOrderStatus(String id, OrderStatus status) {
    final next = [
      for (final o in state)
        if (o.id == id)
          o.copyWith(orderStatus: status, updatedAt: DateTime.now().toIso8601String())
        else
          o,
    ];
    _commit(next);
    ref.read(toastProvider.notifier).show('Order status marked as ${status.jsonValue}', ToastType.info);
  }

  void deleteOrder(String id) {
    ordersOrderedIndex.delete(id);
    state = state.where((o) => o.id != id).toList();
    ref.read(toastProvider.notifier).show('Order deleted successfully', ToastType.warning);
  }

  void addOrderNote(String orderId, String noteText) {
    final trimmed = noteText.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final formattedNote = '[${_formatNoteTimestamp(now)}] $trimmed';

    Order? found;
    final next = [
      for (final o in state)
        if (o.id == orderId)
          (found = o.copyWith(
            notes: o.notes.isNotEmpty ? '${o.notes}\n$formattedNote' : formattedNote,
            notesHistory: [
              OrderNoteItem(
                id: 'note-${now.millisecondsSinceEpoch}',
                text: trimmed,
                createdAt: now.toIso8601String(),
              ),
              ...o.notesHistory,
            ],
            updatedAt: now.toIso8601String(),
          ))
        else
          o,
    ];
    if (found == null) return;
    _commit(next);
    ref.read(toastProvider.notifier).show('Note added to order');
  }

  /// Rewrites `amountReceived`/`paymentStatus` for [orderIds] from
  /// [totalAllocatedByOrder] (order id → sum of every receipt's allocation to
  /// it) — always a full recompute, never a delta, so it's safe to call after
  /// recording, editing, or removing any payment, or after an order's
  /// allocations are stripped by [deleteOrder]'s caller.
  void recomputeFromAllocations(Set<String> orderIds, Map<String, double> totalAllocatedByOrder) {
    if (orderIds.isEmpty) return;
    _commit([
      for (final o in state)
        if (orderIds.contains(o.id)) _withRecomputedPayment(o, totalAllocatedByOrder[o.id] ?? 0) else o,
    ]);
  }

  Order _withRecomputedPayment(Order o, double amountReceived) {
    final totalReceivable = expectedReceiptFor(o);

    PaymentStatus status;
    if (amountReceived <= 0) {
      status = PaymentStatus.unpaid;
    } else if (amountReceived >= totalReceivable) {
      status = PaymentStatus.paid;
    } else {
      status = PaymentStatus.partiallyPaid;
    }

    return o.copyWith(
      amountReceived: amountReceived,
      paymentStatus: status,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);
