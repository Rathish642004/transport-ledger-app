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
}

final driverPaymentsProvider =
    NotifierProvider<DriverPaymentsNotifier, List<DriverPaymentRecord>>(DriverPaymentsNotifier.new);
