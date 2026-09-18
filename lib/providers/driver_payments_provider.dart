import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/driver_payment_record.dart';
import '../storage/hive_boxes.dart';
import 'drivers_provider.dart';
import 'orders_provider.dart';
import 'toast_provider.dart';

/// Mirrors `payDriver` in `LedgerContext.tsx:666-724`.
class DriverPaymentsNotifier extends Notifier<List<DriverPaymentRecord>> {
  @override
  List<DriverPaymentRecord> build() => driverPaymentsBox.values.toList();

  // See the known-limitation comment on OrdersNotifier._commit.
  void _commit(List<DriverPaymentRecord> next) {
    for (final p in next) {
      driverPaymentsBox.put(p.id, p);
    }
    state = next;
  }

  /// `paymentData`'s `id`/`voucherNumber`/`recordedAt` are placeholders — all
  /// three are overwritten here, matching
  /// `Omit<DriverPaymentRecord, 'id'|'voucherNumber'|'recordedAt'>` in the original.
  DriverPaymentRecord payDriver(DriverPaymentRecord paymentData) {
    // Note: numbering literally hardcodes "2026" in the source app, not the
    // current year — preserved as-is for parity with LedgerContext.tsx:667.
    final voucherNumber = 'DRV-2026-${(state.length + 32).toString().padLeft(3, '0')}';
    final newVoucher = paymentData.copyWith(
      id: 'drvpay-${DateTime.now().millisecondsSinceEpoch}',
      voucherNumber: voucherNumber,
      recordedAt: DateTime.now().toIso8601String(),
    );

    _commit([newVoucher, ...state]);

    ref.read(ordersProvider.notifier).applyDriverPayment(
          orderId: paymentData.orderId,
          orderNumber: paymentData.orderNumber,
          amountPaid: paymentData.amountPaid,
          driverBillNumber: paymentData.driverBillNumber,
          driverBillDate: paymentData.driverBillDate,
          billAttachmentName: paymentData.billAttachmentName,
        );

    ref.read(driversProvider.notifier).applyDriverPayment(
          driverId: paymentData.driverId,
          driverName: paymentData.driverName,
          amountPaid: paymentData.amountPaid,
        );

    ref.read(toastProvider.notifier).show(
          'Driver payment of ₹${paymentData.amountPaid.round()} paid to ${paymentData.driverName}',
        );
    return newVoucher;
  }

  /// Applies (`sign: 1`) or reverses (`sign: -1`) a voucher's effect on its
  /// order and driver — see `PaymentsNotifier._applyEffect`'s doc comment
  /// for why negating the original amount is enough on its own.
  void _applyEffect(DriverPaymentRecord payment, double sign) {
    ref.read(ordersProvider.notifier).applyDriverPayment(
          orderId: payment.orderId,
          orderNumber: payment.orderNumber,
          amountPaid: sign * payment.amountPaid,
          driverBillNumber: payment.driverBillNumber,
          driverBillDate: payment.driverBillDate,
          billAttachmentName: payment.billAttachmentName,
        );
    ref.read(driversProvider.notifier).applyDriverPayment(
          driverId: payment.driverId,
          driverName: payment.driverName,
          amountPaid: sign * payment.amountPaid,
        );
  }

  /// Undoes a driver payment recorded by mistake — not in the source, which
  /// has no way to remove a voucher at all.
  void removeDriverPayment(String id) {
    final payment = state.where((p) => p.id == id).firstOrNull;
    if (payment == null) return;

    _applyEffect(payment, -1);
    // Not `_commit`, which only ever `put`s — never removes the stale entry
    // from the box (see `BanksNotifier.deleteBankAccount`'s same reasoning).
    driverPaymentsBox.delete(id);
    state = state.where((p) => p.id != id).toList();
    ref.read(toastProvider.notifier).show('Driver payment removed', ToastType.info);
  }

  /// Edits an existing voucher in place — see `PaymentsNotifier.updatePayment`.
  void updateDriverPayment(DriverPaymentRecord updated) {
    final old = state.where((p) => p.id == updated.id).firstOrNull;
    if (old == null) return;

    _applyEffect(old, -1);
    _commit([for (final p in state) if (p.id == updated.id) updated else p]);
    _applyEffect(updated, 1);
    ref.read(toastProvider.notifier).show('Driver payment updated');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final driverPaymentsProvider =
    NotifierProvider<DriverPaymentsNotifier, List<DriverPaymentRecord>>(DriverPaymentsNotifier.new);
