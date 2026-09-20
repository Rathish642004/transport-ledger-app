/// One order's share of a party-level [PaymentReceipt] — a single lump-sum
/// payment can settle many orders, allocated oldest-first (FIFO).
class PaymentAllocation {
  const PaymentAllocation({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.tdsSettled,
  });

  final String orderId;
  final String orderNumber;
  final double amount;

  /// The order's TDS amount, recorded here only when this allocation fully
  /// closes the order — this is what a party's "TDS withheld" total sums.
  final double tdsSettled;

  PaymentAllocation copyWith({
    String? orderId,
    String? orderNumber,
    double? amount,
    double? tdsSettled,
  }) {
    return PaymentAllocation(
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      amount: amount ?? this.amount,
      tdsSettled: tdsSettled ?? this.tdsSettled,
    );
  }

  factory PaymentAllocation.fromJson(Map<String, dynamic> json) {
    return PaymentAllocation(
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
      tdsSettled: (json['tdsSettled'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'amount': amount,
        'tdsSettled': tdsSettled,
      };
}
