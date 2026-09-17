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
}

final paymentsProvider = NotifierProvider<PaymentsNotifier, List<PaymentReceipt>>(PaymentsNotifier.new);
