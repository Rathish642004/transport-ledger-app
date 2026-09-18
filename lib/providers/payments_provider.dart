import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/payment_receipt.dart';
import '../storage/hive_boxes.dart';
import 'companies_provider.dart';
import 'customers_provider.dart';
import 'orders_provider.dart';
import 'toast_provider.dart';

/// Mirrors `receivePayment` in `LedgerContext.tsx:599-663`.
class PaymentsNotifier extends Notifier<List<PaymentReceipt>> {
  @override
  List<PaymentReceipt> build() => paymentsOrderedIndex.read();

  // See OrdersNotifier._commit — same reasoning, same fix.
  void _commit(List<PaymentReceipt> next) {
    paymentsOrderedIndex.write(next);
    state = next;
  }

  /// `paymentData`'s `id`/`receiptNumber`/`recordedAt` are placeholders — all
  /// three are overwritten here, matching
  /// `Omit<PaymentReceipt, 'id'|'receiptNumber'|'recordedAt'>` in the original.
  PaymentReceipt receivePayment(PaymentReceipt paymentData) {
    // Note: numbering literally hardcodes "2026" in the source app, not the
    // current year — preserved as-is for parity with LedgerContext.tsx:600.
    final receiptNumber = 'RCT-2026-${(state.length + 43).toString().padLeft(3, '0')}';
    final newReceipt = paymentData.copyWith(
      id: 'rct-${DateTime.now().millisecondsSinceEpoch}',
      receiptNumber: receiptNumber,
      recordedAt: DateTime.now().toIso8601String(),
    );

    _commit([newReceipt, ...state]);

    ref.read(ordersProvider.notifier).applyPaymentReceived(
          orderId: paymentData.orderId,
          orderNumber: paymentData.orderNumber,
          amountReceived: paymentData.amountReceived,
        );

    if (paymentData.payerType == PayerType.company) {
      ref.read(companiesProvider.notifier).applyPaymentReceived(paymentData.payerName, paymentData.amountReceived);
    } else {
      ref.read(customersProvider.notifier).applyPaymentReceived(paymentData.payerName, paymentData.amountReceived);
    }

    ref.read(toastProvider.notifier).show('Payment of ₹${paymentData.amountReceived.round()} recorded');
    return newReceipt;
  }

  /// Applies (`sign: 1`) or reverses (`sign: -1`) a receipt's effect on its
  /// order and payer — the shared arithmetic behind [removePayment],
  /// [updatePayment], and `OrdersNotifier.deleteOrder`'s cascade delete.
  /// Negating the same amount that was originally added is enough: the order
  /// and payer notifiers already re-derive payment status/outstanding
  /// balance from the running total, not from a separate "undo" path.
  void _applyEffect(PaymentReceipt payment, double sign) {
    ref.read(ordersProvider.notifier).applyPaymentReceived(
          orderId: payment.orderId,
          orderNumber: payment.orderNumber,
          amountReceived: sign * payment.amountReceived,
        );
    if (payment.payerType == PayerType.company) {
      ref.read(companiesProvider.notifier).applyPaymentReceived(payment.payerName, sign * payment.amountReceived);
    } else {
      ref.read(customersProvider.notifier).applyPaymentReceived(payment.payerName, sign * payment.amountReceived);
    }
  }

  /// Undoes a payment recorded by mistake (including one added after the
  /// order was already fully paid) — not in the source, which has no way to
  /// remove a receipt at all.
  void removePayment(String id) {
    final payment = state.where((p) => p.id == id).firstOrNull;
    if (payment == null) return;

    _applyEffect(payment, -1);
    // Not `_commit`, which only ever `put`s — never removes the stale entry
    // from the underlying box (see `BanksNotifier.deleteBankAccount`, the
    // same reasoning for a plain box; `paymentsOrderedIndex` is the ordered
    // equivalent).
    paymentsOrderedIndex.delete(id);
    state = state.where((p) => p.id != id).toList();
    ref.read(toastProvider.notifier).show('Payment removed', ToastType.info);
  }

  /// Edits an existing receipt in place. Reversing the old amount and
  /// re-applying the new one (rather than a delta) correctly handles the
  /// payer or order changing too, not just the amount.
  void updatePayment(PaymentReceipt updated) {
    final old = state.where((p) => p.id == updated.id).firstOrNull;
    if (old == null) return;

    _applyEffect(old, -1);
    _commit([for (final p in state) if (p.id == updated.id) updated else p]);
    _applyEffect(updated, 1);
    ref.read(toastProvider.notifier).show('Payment updated');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final paymentsProvider = NotifierProvider<PaymentsNotifier, List<PaymentReceipt>>(PaymentsNotifier.new);
