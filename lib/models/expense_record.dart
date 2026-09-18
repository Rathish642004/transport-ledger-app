import 'enums.dart';

/// Mirrors `src/types.ts` `ExpenseRecord`.
class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.expenseNumber,
    required this.date,
    required this.category,
    required this.amount,
    this.vehicleNumber,
    this.orderId,
    this.orderNumber,
    required this.paidTo,
    required this.paymentMethod,
    required this.notes,
    this.receiptAttachmentName,
    this.bankAccountId,
  });

  final String id;
  final String expenseNumber;
  final String date;
  final ExpenseCategory category;
  final double amount;
  final String? vehicleNumber;
  final String? orderId;
  final String? orderNumber;
  final String paidTo;
  final PaymentMethod paymentMethod;
  final String notes;
  final String? receiptAttachmentName;
  /// Which of the transporter's own [BankAccount]s this was paid from —
  /// `null` for cash or for records created before this field existed.
  final String? bankAccountId;

  ExpenseRecord copyWith({
    String? id,
    String? expenseNumber,
    String? date,
    ExpenseCategory? category,
    double? amount,
    String? vehicleNumber,
    String? orderId,
    String? orderNumber,
    String? paidTo,
    PaymentMethod? paymentMethod,
    String? notes,
    String? receiptAttachmentName,
    String? bankAccountId,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      paidTo: paidTo ?? this.paidTo,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      receiptAttachmentName: receiptAttachmentName ?? this.receiptAttachmentName,
      bankAccountId: bankAccountId ?? this.bankAccountId,
    );
  }

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    return ExpenseRecord(
      id: json['id'] as String,
      expenseNumber: json['expenseNumber'] as String,
      date: json['date'] as String,
      category: ExpenseCategory.fromJson(json['category'] as String),
      amount: (json['amount'] as num).toDouble(),
      vehicleNumber: json['vehicleNumber'] as String?,
      orderId: json['orderId'] as String?,
      orderNumber: json['orderNumber'] as String?,
      paidTo: json['paidTo'] as String,
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
      notes: json['notes'] as String,
      receiptAttachmentName: json['receiptAttachmentName'] as String?,
      bankAccountId: json['bankAccountId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'expenseNumber': expenseNumber,
        'date': date,
        'category': category.toJson(),
        'amount': amount,
        if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
        if (orderId != null) 'orderId': orderId,
        if (orderNumber != null) 'orderNumber': orderNumber,
        'paidTo': paidTo,
        'paymentMethod': paymentMethod.toJson(),
        'notes': notes,
        if (receiptAttachmentName != null) 'receiptAttachmentName': receiptAttachmentName,
        if (bankAccountId != null) 'bankAccountId': bankAccountId,
      };
}
