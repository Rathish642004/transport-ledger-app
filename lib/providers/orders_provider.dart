import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/order.dart';
import '../storage/hive_boxes.dart';
import 'companies_provider.dart';
import 'customers_provider.dart';
import 'drivers_provider.dart';
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

/// Mirrors the order actions in `LedgerContext.tsx:476-596`, plus the
/// order-side updates from `receivePayment` (:610-632) and `payDriver`
/// (:677-707), kept here since they mutate this notifier's own state.
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
  /// in the original. Also fans out the company/customer/driver aggregate
  /// stat updates `createOrder` does in the source.
  Order createOrder(Order orderData) {
    final now = DateTime.now().toIso8601String();
    final newOrder = orderData.copyWith(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );

    _commit([newOrder, ...state]);

    ref.read(companiesProvider.notifier).applyOrderCreated(newOrder);
    ref.read(customersProvider.notifier).applyOrderCreated(newOrder);
    ref.read(driversProvider.notifier).applyOrderCreated(newOrder);

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

  /// Order-side update from `receivePayment` (`LedgerContext.tsx:610-632`).
  void applyPaymentReceived({
    required String? orderId,
    required String? orderNumber,
    required double amountReceived,
  }) {
    _commit([
      for (final o in state)
        if (o.id == orderId || o.orderNumber == orderNumber)
          _withPaymentApplied(o, amountReceived)
        else
          o,
    ]);
  }

  Order _withPaymentApplied(Order o, double amountReceived) {
    final newAmountReceived = o.amountReceived + amountReceived;
    final totalReceivable =
        o.billing.netExpectedReceipt != 0 ? o.billing.netExpectedReceipt : o.charges.totalCustomerBill;

    PaymentStatus status;
    if (newAmountReceived >= totalReceivable) {
      status = PaymentStatus.paid;
    } else if (newAmountReceived == 0) {
      status = PaymentStatus.unpaid;
    } else {
      status = PaymentStatus.partiallyPaid;
    }

    return o.copyWith(
      amountReceived: newAmountReceived,
      paymentStatus: status,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Order-side update from `payDriver` (`LedgerContext.tsx:677-707`).
  void applyDriverPayment({
    required String? orderId,
    required String? orderNumber,
    required double amountPaid,
    String? driverBillNumber,
    String? driverBillDate,
    String? billAttachmentName,
  }) {
    _commit([
      for (final o in state)
        if (o.id == orderId || o.orderNumber == orderNumber)
          _withDriverPaymentApplied(o, amountPaid, driverBillNumber, driverBillDate, billAttachmentName)
        else
          o,
    ]);
  }

  Order _withDriverPaymentApplied(
    Order o,
    double amountPaid,
    String? driverBillNumber,
    String? driverBillDate,
    String? billAttachmentName,
  ) {
    final newPaidAmount = o.driverExpense.driverPaidAmount + amountPaid;
    final agreed = o.driverExpense.driverFreight;

    DriverPaymentStatus status;
    if (newPaidAmount >= agreed) {
      status = DriverPaymentStatus.paidInFull;
    } else if (newPaidAmount > 0) {
      status = DriverPaymentStatus.advancePaid;
    } else {
      status = DriverPaymentStatus.unpaid;
    }

    return o.copyWith(
      driverExpense: o.driverExpense.copyWith(
        driverPaidAmount: newPaidAmount,
        driverPaymentStatus: status,
        driverBillNumber: (driverBillNumber == null || driverBillNumber.isEmpty) ? null : driverBillNumber,
        driverBillDate: (driverBillDate == null || driverBillDate.isEmpty) ? null : driverBillDate,
        driverBillAttachment: (billAttachmentName == null || billAttachmentName.isEmpty) ? null : billAttachmentName,
      ),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);
