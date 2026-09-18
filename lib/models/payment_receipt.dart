import 'enums.dart';

/// Mirrors `src/types.ts` `PaymentReceipt`.
class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.receiptNumber,
    required this.orderId,
    required this.orderNumber,
    required this.payerType,
    required this.payerName,
    required this.amountReceived,
    required this.paymentDate,
    required this.paymentMethod,
    required this.tdsDeducted,
    required this.otherDeduction,
    required this.referenceNumber,
    required this.notes,
    required this.recordedAt,
    this.bankAccountId,
  });

  final String id;
  final String receiptNumber;
  final String orderId;
  final String orderNumber;
  final PayerType payerType;
  final String payerName;
  final double amountReceived;
  final String paymentDate;
  final PaymentMethod paymentMethod;
  final double tdsDeducted;
  final double otherDeduction;
  final String referenceNumber;
  final String notes;
  final String recordedAt;
  /// Which of the transporter's own [BankAccount]s this was received into —
  /// `null` for cash or for records created before this field existed.
  final String? bankAccountId;

  PaymentReceipt copyWith({
    String? id,
    String? receiptNumber,
    String? orderId,
    String? orderNumber,
    PayerType? payerType,
    String? payerName,
    double? amountReceived,
    String? paymentDate,
    PaymentMethod? paymentMethod,
    double? tdsDeducted,
    double? otherDeduction,
    String? referenceNumber,
    String? notes,
    String? recordedAt,
    String? bankAccountId,
  }) {
    return PaymentReceipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      payerType: payerType ?? this.payerType,
      payerName: payerName ?? this.payerName,
      amountReceived: amountReceived ?? this.amountReceived,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tdsDeducted: tdsDeducted ?? this.tdsDeducted,
      otherDeduction: otherDeduction ?? this.otherDeduction,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
      bankAccountId: bankAccountId ?? this.bankAccountId,
    );
  }

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) {
    return PaymentReceipt(
      id: json['id'] as String,
      receiptNumber: json['receiptNumber'] as String,
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      payerType: PayerType.fromJson(json['payerType'] as String),
      payerName: json['payerName'] as String,
      amountReceived: (json['amountReceived'] as num).toDouble(),
      paymentDate: json['paymentDate'] as String,
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
      tdsDeducted: (json['tdsDeducted'] as num).toDouble(),
      otherDeduction: (json['otherDeduction'] as num).toDouble(),
      referenceNumber: json['referenceNumber'] as String,
      notes: json['notes'] as String,
      recordedAt: json['recordedAt'] as String,
      bankAccountId: json['bankAccountId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNumber': receiptNumber,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'payerType': payerType.toJson(),
        'payerName': payerName,
        'amountReceived': amountReceived,
        'paymentDate': paymentDate,
        'paymentMethod': paymentMethod.toJson(),
        'tdsDeducted': tdsDeducted,
        'otherDeduction': otherDeduction,
        'referenceNumber': referenceNumber,
        'notes': notes,
        'recordedAt': recordedAt,
        if (bankAccountId != null) 'bankAccountId': bankAccountId,
      };
}
