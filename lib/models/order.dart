import 'enums.dart';

/// Mirrors `src/types.ts` `OrderNoteItem`.
class OrderNoteItem {
  const OrderNoteItem({
    required this.id,
    required this.text,
    required this.createdAt,
    this.author,
  });

  final String id;
  final String text;
  final String createdAt;
  final String? author;

  OrderNoteItem copyWith({String? id, String? text, String? createdAt, String? author}) {
    return OrderNoteItem(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
    );
  }

  factory OrderNoteItem.fromJson(Map<String, dynamic> json) {
    return OrderNoteItem(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: json['createdAt'] as String,
      author: json['author'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt,
        if (author != null) 'author': author,
      };
}

/// Mirrors `src/types.ts` `OrderCharges`.
class OrderCharges {
  const OrderCharges({
    required this.loadingCharges,
    required this.transportationCharges,
    required this.otherCharges,
    required this.totalCustomerBill,
  });

  final double loadingCharges;
  final double transportationCharges;
  final double otherCharges;
  final double totalCustomerBill;

  OrderCharges copyWith({
    double? loadingCharges,
    double? transportationCharges,
    double? otherCharges,
    double? totalCustomerBill,
  }) {
    return OrderCharges(
      loadingCharges: loadingCharges ?? this.loadingCharges,
      transportationCharges: transportationCharges ?? this.transportationCharges,
      otherCharges: otherCharges ?? this.otherCharges,
      totalCustomerBill: totalCustomerBill ?? this.totalCustomerBill,
    );
  }

  factory OrderCharges.fromJson(Map<String, dynamic> json) {
    return OrderCharges(
      loadingCharges: (json['loadingCharges'] as num).toDouble(),
      transportationCharges: (json['transportationCharges'] as num).toDouble(),
      otherCharges: (json['otherCharges'] as num).toDouble(),
      totalCustomerBill: (json['totalCustomerBill'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'loadingCharges': loadingCharges,
        'transportationCharges': transportationCharges,
        'otherCharges': otherCharges,
        'totalCustomerBill': totalCustomerBill,
      };
}

/// Mirrors `src/types.ts` `DriverExpense`.
class DriverExpense {
  const DriverExpense({
    required this.driverId,
    required this.driverName,
    required this.driverFreight,
    required this.driverPaidAmount,
    required this.driverPaymentStatus,
    required this.driverBillNumber,
    required this.driverBillDate,
    this.driverBillAttachment,
    required this.additionalLoadingExpense,
    required this.otherTransportExpense,
  });

  final String driverId;
  final String driverName;
  final double driverFreight;
  final double driverPaidAmount;
  final DriverPaymentStatus driverPaymentStatus;
  final String driverBillNumber;
  final String driverBillDate;
  final String? driverBillAttachment;
  final double additionalLoadingExpense;
  final double otherTransportExpense;

  DriverExpense copyWith({
    String? driverId,
    String? driverName,
    double? driverFreight,
    double? driverPaidAmount,
    DriverPaymentStatus? driverPaymentStatus,
    String? driverBillNumber,
    String? driverBillDate,
    String? driverBillAttachment,
    double? additionalLoadingExpense,
    double? otherTransportExpense,
  }) {
    return DriverExpense(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverFreight: driverFreight ?? this.driverFreight,
      driverPaidAmount: driverPaidAmount ?? this.driverPaidAmount,
      driverPaymentStatus: driverPaymentStatus ?? this.driverPaymentStatus,
      driverBillNumber: driverBillNumber ?? this.driverBillNumber,
      driverBillDate: driverBillDate ?? this.driverBillDate,
      driverBillAttachment: driverBillAttachment ?? this.driverBillAttachment,
      additionalLoadingExpense: additionalLoadingExpense ?? this.additionalLoadingExpense,
      otherTransportExpense: otherTransportExpense ?? this.otherTransportExpense,
    );
  }

  factory DriverExpense.fromJson(Map<String, dynamic> json) {
    return DriverExpense(
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      driverFreight: (json['driverFreight'] as num).toDouble(),
      driverPaidAmount: (json['driverPaidAmount'] as num).toDouble(),
      driverPaymentStatus: DriverPaymentStatus.fromJson(json['driverPaymentStatus'] as String),
      driverBillNumber: json['driverBillNumber'] as String,
      driverBillDate: json['driverBillDate'] as String,
      driverBillAttachment: json['driverBillAttachment'] as String?,
      additionalLoadingExpense: (json['additionalLoadingExpense'] as num).toDouble(),
      otherTransportExpense: (json['otherTransportExpense'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'driverName': driverName,
        'driverFreight': driverFreight,
        'driverPaidAmount': driverPaidAmount,
        'driverPaymentStatus': driverPaymentStatus.toJson(),
        'driverBillNumber': driverBillNumber,
        'driverBillDate': driverBillDate,
        if (driverBillAttachment != null) 'driverBillAttachment': driverBillAttachment,
        'additionalLoadingExpense': additionalLoadingExpense,
        'otherTransportExpense': otherTransportExpense,
      };
}

/// Mirrors `src/types.ts` `BillingDetails`.
class BillingDetails {
  const BillingDetails({
    required this.billPayer,
    required this.billRecipientName,
    required this.billNumber,
    required this.billDate,
    required this.tdsApplicable,
    required this.tdsPercentage,
    required this.tdsAmount,
    required this.otherDeductions,
    required this.netExpectedReceipt,
    required this.paymentTerms,
    required this.notes,
  });

  final PayerType billPayer;
  final String billRecipientName;
  final String billNumber;
  final String billDate;
  final bool tdsApplicable;
  final double tdsPercentage;
  final double tdsAmount;
  final double otherDeductions;
  final double netExpectedReceipt;
  final String paymentTerms;
  final String notes;

  BillingDetails copyWith({
    PayerType? billPayer,
    String? billRecipientName,
    String? billNumber,
    String? billDate,
    bool? tdsApplicable,
    double? tdsPercentage,
    double? tdsAmount,
    double? otherDeductions,
    double? netExpectedReceipt,
    String? paymentTerms,
    String? notes,
  }) {
    return BillingDetails(
      billPayer: billPayer ?? this.billPayer,
      billRecipientName: billRecipientName ?? this.billRecipientName,
      billNumber: billNumber ?? this.billNumber,
      billDate: billDate ?? this.billDate,
      tdsApplicable: tdsApplicable ?? this.tdsApplicable,
      tdsPercentage: tdsPercentage ?? this.tdsPercentage,
      tdsAmount: tdsAmount ?? this.tdsAmount,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      netExpectedReceipt: netExpectedReceipt ?? this.netExpectedReceipt,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
    );
  }

  factory BillingDetails.fromJson(Map<String, dynamic> json) {
    return BillingDetails(
      billPayer: PayerType.fromJson(json['billPayer'] as String),
      billRecipientName: json['billRecipientName'] as String,
      billNumber: json['billNumber'] as String,
      billDate: json['billDate'] as String,
      tdsApplicable: json['tdsApplicable'] as bool,
      tdsPercentage: (json['tdsPercentage'] as num).toDouble(),
      tdsAmount: (json['tdsAmount'] as num).toDouble(),
      otherDeductions: (json['otherDeductions'] as num).toDouble(),
      netExpectedReceipt: (json['netExpectedReceipt'] as num).toDouble(),
      paymentTerms: json['paymentTerms'] as String,
      notes: json['notes'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'billPayer': billPayer.toJson(),
        'billRecipientName': billRecipientName,
        'billNumber': billNumber,
        'billDate': billDate,
        'tdsApplicable': tdsApplicable,
        'tdsPercentage': tdsPercentage,
        'tdsAmount': tdsAmount,
        'otherDeductions': otherDeductions,
        'netExpectedReceipt': netExpectedReceipt,
        'paymentTerms': paymentTerms,
        'notes': notes,
      };
}

/// Mirrors `src/types.ts` `FinancialSummary`.
class FinancialSummary {
  const FinancialSummary({
    required this.grossBill,
    required this.driverExpenseTotal,
    required this.otherExpenseTotal,
    required this.expectedTds,
    required this.expectedNetReceipt,
    required this.estimatedProfit,
  });

  final double grossBill;
  final double driverExpenseTotal;
  final double otherExpenseTotal;
  final double expectedTds;
  final double expectedNetReceipt;
  final double estimatedProfit;

  FinancialSummary copyWith({
    double? grossBill,
    double? driverExpenseTotal,
    double? otherExpenseTotal,
    double? expectedTds,
    double? expectedNetReceipt,
    double? estimatedProfit,
  }) {
    return FinancialSummary(
      grossBill: grossBill ?? this.grossBill,
      driverExpenseTotal: driverExpenseTotal ?? this.driverExpenseTotal,
      otherExpenseTotal: otherExpenseTotal ?? this.otherExpenseTotal,
      expectedTds: expectedTds ?? this.expectedTds,
      expectedNetReceipt: expectedNetReceipt ?? this.expectedNetReceipt,
      estimatedProfit: estimatedProfit ?? this.estimatedProfit,
    );
  }

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      grossBill: (json['grossBill'] as num).toDouble(),
      driverExpenseTotal: (json['driverExpenseTotal'] as num).toDouble(),
      otherExpenseTotal: (json['otherExpenseTotal'] as num).toDouble(),
      expectedTds: (json['expectedTds'] as num).toDouble(),
      expectedNetReceipt: (json['expectedNetReceipt'] as num).toDouble(),
      estimatedProfit: (json['estimatedProfit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'grossBill': grossBill,
        'driverExpenseTotal': driverExpenseTotal,
        'otherExpenseTotal': otherExpenseTotal,
        'expectedTds': expectedTds,
        'expectedNetReceipt': expectedNetReceipt,
        'estimatedProfit': estimatedProfit,
      };
}

/// Mirrors `src/types.ts` `Order`.
class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    this.lrNumber,
    required this.orderDate,
    required this.companyId,
    required this.companyName,
    this.consignorDivision,
    this.consignorAddress,
    required this.customerId,
    required this.customerName,
    this.consigneeAddress,
    this.deliveryAddress,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.vehicleNumber,
    this.invoiceDetails,
    required this.driverId,
    required this.driverName,
    required this.numberOfBags,
    required this.bagType,
    this.goodsDescription,
    this.ratePerBag,
    this.rateUnit,
    required this.notes,
    this.notesHistory = const [],
    required this.orderStatus,
    required this.paymentStatus,
    required this.amountReceived,
    required this.charges,
    required this.driverExpense,
    required this.billing,
    required this.financialSummary,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final String? lrNumber;
  final String orderDate;
  final String companyId;
  final String companyName;
  final String? consignorDivision;
  final String? consignorAddress;
  final String customerId;
  final String customerName;
  final String? consigneeAddress;
  final String? deliveryAddress;
  final String pickupLocation;
  final String deliveryLocation;
  final String vehicleNumber;
  final String? invoiceDetails;
  final String driverId;
  final String driverName;
  final int numberOfBags;
  final String bagType;
  final String? goodsDescription;
  final double? ratePerBag;
  final String? rateUnit;
  final String notes;
  final List<OrderNoteItem> notesHistory;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final double amountReceived;
  final OrderCharges charges;
  final DriverExpense driverExpense;
  final BillingDetails billing;
  final FinancialSummary financialSummary;
  final String createdAt;
  final String updatedAt;

  Order copyWith({
    String? id,
    String? orderNumber,
    String? lrNumber,
    String? orderDate,
    String? companyId,
    String? companyName,
    String? consignorDivision,
    String? consignorAddress,
    String? customerId,
    String? customerName,
    String? consigneeAddress,
    String? deliveryAddress,
    String? pickupLocation,
    String? deliveryLocation,
    String? vehicleNumber,
    String? invoiceDetails,
    String? driverId,
    String? driverName,
    int? numberOfBags,
    String? bagType,
    String? goodsDescription,
    double? ratePerBag,
    String? rateUnit,
    String? notes,
    List<OrderNoteItem>? notesHistory,
    OrderStatus? orderStatus,
    PaymentStatus? paymentStatus,
    double? amountReceived,
    OrderCharges? charges,
    DriverExpense? driverExpense,
    BillingDetails? billing,
    FinancialSummary? financialSummary,
    String? createdAt,
    String? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      lrNumber: lrNumber ?? this.lrNumber,
      orderDate: orderDate ?? this.orderDate,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      consignorDivision: consignorDivision ?? this.consignorDivision,
      consignorAddress: consignorAddress ?? this.consignorAddress,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      consigneeAddress: consigneeAddress ?? this.consigneeAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      invoiceDetails: invoiceDetails ?? this.invoiceDetails,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      numberOfBags: numberOfBags ?? this.numberOfBags,
      bagType: bagType ?? this.bagType,
      goodsDescription: goodsDescription ?? this.goodsDescription,
      ratePerBag: ratePerBag ?? this.ratePerBag,
      rateUnit: rateUnit ?? this.rateUnit,
      notes: notes ?? this.notes,
      notesHistory: notesHistory ?? this.notesHistory,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountReceived: amountReceived ?? this.amountReceived,
      charges: charges ?? this.charges,
      driverExpense: driverExpense ?? this.driverExpense,
      billing: billing ?? this.billing,
      financialSummary: financialSummary ?? this.financialSummary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      lrNumber: json['lrNumber'] as String?,
      orderDate: json['orderDate'] as String,
      companyId: json['companyId'] as String,
      companyName: json['companyName'] as String,
      consignorDivision: json['consignorDivision'] as String?,
      consignorAddress: json['consignorAddress'] as String?,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      consigneeAddress: json['consigneeAddress'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      pickupLocation: json['pickupLocation'] as String,
      deliveryLocation: json['deliveryLocation'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      invoiceDetails: json['invoiceDetails'] as String?,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      numberOfBags: (json['numberOfBags'] as num).toInt(),
      bagType: json['bagType'] as String,
      goodsDescription: json['goodsDescription'] as String?,
      ratePerBag: (json['ratePerBag'] as num?)?.toDouble(),
      rateUnit: json['rateUnit'] as String?,
      notes: json['notes'] as String,
      notesHistory: (json['notesHistory'] as List<dynamic>? ?? const [])
          .map((e) => OrderNoteItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderStatus: OrderStatus.fromJson(json['orderStatus'] as String),
      paymentStatus: PaymentStatus.fromJson(json['paymentStatus'] as String),
      amountReceived: (json['amountReceived'] as num).toDouble(),
      charges: OrderCharges.fromJson(json['charges'] as Map<String, dynamic>),
      driverExpense: DriverExpense.fromJson(json['driverExpense'] as Map<String, dynamic>),
      billing: BillingDetails.fromJson(json['billing'] as Map<String, dynamic>),
      financialSummary: FinancialSummary.fromJson(json['financialSummary'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        if (lrNumber != null) 'lrNumber': lrNumber,
        'orderDate': orderDate,
        'companyId': companyId,
        'companyName': companyName,
        if (consignorDivision != null) 'consignorDivision': consignorDivision,
        if (consignorAddress != null) 'consignorAddress': consignorAddress,
        'customerId': customerId,
        'customerName': customerName,
        if (consigneeAddress != null) 'consigneeAddress': consigneeAddress,
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
        'pickupLocation': pickupLocation,
        'deliveryLocation': deliveryLocation,
        'vehicleNumber': vehicleNumber,
        if (invoiceDetails != null) 'invoiceDetails': invoiceDetails,
        'driverId': driverId,
        'driverName': driverName,
        'numberOfBags': numberOfBags,
        'bagType': bagType,
        if (goodsDescription != null) 'goodsDescription': goodsDescription,
        if (ratePerBag != null) 'ratePerBag': ratePerBag,
        if (rateUnit != null) 'rateUnit': rateUnit,
        'notes': notes,
        if (notesHistory.isNotEmpty) 'notesHistory': notesHistory.map((e) => e.toJson()).toList(),
        'orderStatus': orderStatus.toJson(),
        'paymentStatus': paymentStatus.toJson(),
        'amountReceived': amountReceived,
        'charges': charges.toJson(),
        'driverExpense': driverExpense.toJson(),
        'billing': billing.toJson(),
        'financialSummary': financialSummary.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
