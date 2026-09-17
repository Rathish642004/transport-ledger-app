import 'enums.dart';

/// Mirrors `src/types.ts` `DriverPaymentRecord`.
class DriverPaymentRecord {
  const DriverPaymentRecord({
    required this.id,
    required this.voucherNumber,
    required this.driverId,
    required this.driverName,
    required this.orderId,
    required this.orderNumber,
    required this.driverBillNumber,
    required this.driverBillDate,
    required this.agreedFreight,
    required this.amountPaid,
    required this.paymentDate,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.notes,
    this.billAttachmentName,
    required this.recordedAt,
  });

  final String id;
  final String voucherNumber;
  final String driverId;
  final String driverName;
  final String orderId;
  final String orderNumber;
  final String driverBillNumber;
  final String driverBillDate;
  final double agreedFreight;
  final double amountPaid;
  final String paymentDate;
  final PaymentMethod paymentMethod;
  final String referenceNumber;
  final String notes;
  final String? billAttachmentName;
  final String recordedAt;

  DriverPaymentRecord copyWith({
    String? id,
    String? voucherNumber,
    String? driverId,
    String? driverName,
    String? orderId,
    String? orderNumber,
    String? driverBillNumber,
    String? driverBillDate,
    double? agreedFreight,
    double? amountPaid,
    String? paymentDate,
    PaymentMethod? paymentMethod,
    String? referenceNumber,
    String? notes,
    String? billAttachmentName,
    String? recordedAt,
  }) {
    return DriverPaymentRecord(
      id: id ?? this.id,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      driverBillNumber: driverBillNumber ?? this.driverBillNumber,
      driverBillDate: driverBillDate ?? this.driverBillDate,
      agreedFreight: agreedFreight ?? this.agreedFreight,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      billAttachmentName: billAttachmentName ?? this.billAttachmentName,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  factory DriverPaymentRecord.fromJson(Map<String, dynamic> json) {
    return DriverPaymentRecord(
      id: json['id'] as String,
      voucherNumber: json['voucherNumber'] as String,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      driverBillNumber: json['driverBillNumber'] as String,
      driverBillDate: json['driverBillDate'] as String,
      agreedFreight: (json['agreedFreight'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num).toDouble(),
      paymentDate: json['paymentDate'] as String,
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
      referenceNumber: json['referenceNumber'] as String,
      notes: json['notes'] as String,
      billAttachmentName: json['billAttachmentName'] as String?,
      recordedAt: json['recordedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'voucherNumber': voucherNumber,
        'driverId': driverId,
        'driverName': driverName,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'driverBillNumber': driverBillNumber,
        'driverBillDate': driverBillDate,
        'agreedFreight': agreedFreight,
        'amountPaid': amountPaid,
        'paymentDate': paymentDate,
        'paymentMethod': paymentMethod.toJson(),
        'referenceNumber': referenceNumber,
        'notes': notes,
        if (billAttachmentName != null) 'billAttachmentName': billAttachmentName,
        'recordedAt': recordedAt,
      };
}
