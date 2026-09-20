import 'enums.dart';
import 'payment_allocation.dart';

/// A party-level payment. One receipt can settle many orders — see
/// [allocations], filled in FIFO order by `payment_allocation_engine.dart`.
/// [orderId]/[orderNumber] are kept only for records persisted before this
/// receipt became party-level (see [PaymentReceipt.fromJson]).
class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.receiptNumber,
    this.partyId,
    this.orderId,
    this.orderNumber,
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
    this.allocations = const [],
  });

  final String id;
  final String receiptNumber;

  /// The company/customer id this payment belongs to. Nullable only for
  /// receipts persisted before party-level payments existed and whose payer
  /// name could not be resolved to a party during migration.
  final String? partyId;
  final String? orderId;
  final String? orderNumber;
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

  /// How this receipt's [amountReceived] was applied across the party's open
  /// orders, oldest-first. Anything not covered here is unallocated credit —
  /// see [unallocatedAmount].
  final List<PaymentAllocation> allocations;

  double get allocatedTotal => allocations.fold(0.0, (sum, a) => sum + a.amount);
  double get unallocatedAmount => amountReceived - allocatedTotal;

  PaymentReceipt copyWith({
    String? id,
    String? receiptNumber,
    String? partyId,
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
    List<PaymentAllocation>? allocations,
  }) {
    return PaymentReceipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      partyId: partyId ?? this.partyId,
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
      allocations: allocations ?? this.allocations,
    );
  }

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) {
    final amountReceived = (json['amountReceived'] as num).toDouble();
    final rawAllocations = json['allocations'] as List<dynamic>?;
    final legacyOrderId = json['orderId'] as String?;

    List<PaymentAllocation> allocations;
    if (rawAllocations != null) {
      allocations = rawAllocations.map((e) => PaymentAllocation.fromJson(e as Map<String, dynamic>)).toList();
    } else if (legacyOrderId != null && legacyOrderId != 'ord-general') {
      // Pre-FIFO receipts were always recorded against exactly one order —
      // synthesize the equivalent single allocation.
      allocations = [
        PaymentAllocation(
          orderId: legacyOrderId,
          orderNumber: json['orderNumber'] as String? ?? '',
          amount: amountReceived,
          tdsSettled: (json['tdsDeducted'] as num?)?.toDouble() ?? 0,
        ),
      ];
    } else {
      allocations = const [];
    }

    return PaymentReceipt(
      id: json['id'] as String,
      receiptNumber: json['receiptNumber'] as String,
      partyId: json['partyId'] as String?,
      orderId: legacyOrderId,
      orderNumber: json['orderNumber'] as String?,
      payerType: PayerType.fromJson(json['payerType'] as String),
      payerName: json['payerName'] as String,
      amountReceived: amountReceived,
      paymentDate: json['paymentDate'] as String,
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
      tdsDeducted: (json['tdsDeducted'] as num).toDouble(),
      otherDeduction: (json['otherDeduction'] as num).toDouble(),
      referenceNumber: json['referenceNumber'] as String,
      notes: json['notes'] as String,
      recordedAt: json['recordedAt'] as String,
      bankAccountId: json['bankAccountId'] as String?,
      allocations: allocations,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNumber': receiptNumber,
        if (partyId != null) 'partyId': partyId,
        if (orderId != null) 'orderId': orderId,
        if (orderNumber != null) 'orderNumber': orderNumber,
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
        'allocations': allocations.map((a) => a.toJson()).toList(),
      };
}
