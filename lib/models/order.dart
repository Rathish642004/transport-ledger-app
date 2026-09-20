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

/// The customer/company bill for an order — always `numberOfBags * ratePerBag`.
/// Kept as its own class (rather than a bare `double` on [Order]) for JSON/Hive
/// continuity with the previous shape, which summed three charge fields.
class OrderCharges {
  const OrderCharges({required this.totalCustomerBill});

  final double totalCustomerBill;

  OrderCharges copyWith({double? totalCustomerBill}) {
    return OrderCharges(totalCustomerBill: totalCustomerBill ?? this.totalCustomerBill);
  }

  /// Reads the current single-field shape, falling back to summing the
  /// pre-restructure `loadingCharges + transportationCharges + otherCharges`
  /// for records persisted before the order-money model changed.
  factory OrderCharges.fromJson(Map<String, dynamic> json) {
    final total = json['totalCustomerBill'] as num?;
    if (total != null) {
      return OrderCharges(totalCustomerBill: total.toDouble());
    }
    final loading = (json['loadingCharges'] as num?)?.toDouble() ?? 0;
    final transportation = (json['transportationCharges'] as num?)?.toDouble() ?? 0;
    final other = (json['otherCharges'] as num?)?.toDouble() ?? 0;
    return OrderCharges(totalCustomerBill: loading + transportation + other);
  }

  Map<String, dynamic> toJson() => {'totalCustomerBill': totalCustomerBill};
}

/// The expenses incurred for an order — subtracted from [OrderCharges] to
/// give the order's profit, which may be negative. Transportation charges
/// are inclusive of driver payment; there is no separate driver ledger.
class OrderExpenses {
  const OrderExpenses({
    required this.loadingCharges,
    required this.transportationCharges,
    required this.otherCharges,
  });

  const OrderExpenses.zero()
      : loadingCharges = 0,
        transportationCharges = 0,
        otherCharges = 0;

  final double loadingCharges;
  final double transportationCharges;
  final double otherCharges;

  double get total => loadingCharges + transportationCharges + otherCharges;

  OrderExpenses copyWith({
    double? loadingCharges,
    double? transportationCharges,
    double? otherCharges,
  }) {
    return OrderExpenses(
      loadingCharges: loadingCharges ?? this.loadingCharges,
      transportationCharges: transportationCharges ?? this.transportationCharges,
      otherCharges: otherCharges ?? this.otherCharges,
    );
  }

  factory OrderExpenses.fromJson(Map<String, dynamic> json) {
    return OrderExpenses(
      loadingCharges: (json['loadingCharges'] as num?)?.toDouble() ?? 0,
      transportationCharges: (json['transportationCharges'] as num?)?.toDouble() ?? 0,
      otherCharges: (json['otherCharges'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Maps the removed per-order `DriverExpense` shape onto the new expense
  /// categories, so a record persisted before the driver feature was removed
  /// still carries its money forward: the driver's freight and other
  /// transport expense both count as transportation expense (driver payment
  /// is no longer tracked separately), and the additional loading expense
  /// counts as loading expense.
  factory OrderExpenses.fromLegacyDriverExpense(Map<String, dynamic>? json) {
    if (json == null) return const OrderExpenses.zero();
    final driverFreight = (json['driverFreight'] as num?)?.toDouble() ?? 0;
    final otherTransportExpense = (json['otherTransportExpense'] as num?)?.toDouble() ?? 0;
    final additionalLoadingExpense = (json['additionalLoadingExpense'] as num?)?.toDouble() ?? 0;
    return OrderExpenses(
      loadingCharges: additionalLoadingExpense,
      transportationCharges: driverFreight + otherTransportExpense,
      otherCharges: 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'loadingCharges': loadingCharges,
        'transportationCharges': transportationCharges,
        'otherCharges': otherCharges,
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

/// Mirrors `src/types.ts` `FinancialSummary`. [estimatedProfit] may be
/// negative — an order's expenses are not capped at its bill amount.
class FinancialSummary {
  const FinancialSummary({
    required this.grossBill,
    required this.totalExpenses,
    required this.expectedTds,
    required this.expectedNetReceipt,
    required this.estimatedProfit,
  });

  final double grossBill;
  final double totalExpenses;
  final double expectedTds;
  final double expectedNetReceipt;
  final double estimatedProfit;

  FinancialSummary copyWith({
    double? grossBill,
    double? totalExpenses,
    double? expectedTds,
    double? expectedNetReceipt,
    double? estimatedProfit,
  }) {
    return FinancialSummary(
      grossBill: grossBill ?? this.grossBill,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      expectedTds: expectedTds ?? this.expectedTds,
      expectedNetReceipt: expectedNetReceipt ?? this.expectedNetReceipt,
      estimatedProfit: estimatedProfit ?? this.estimatedProfit,
    );
  }

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    final totalExpenses = json['totalExpenses'] as num? ??
        ((json['driverExpenseTotal'] as num?)?.toDouble() ?? 0) +
            ((json['otherExpenseTotal'] as num?)?.toDouble() ?? 0);
    return FinancialSummary(
      grossBill: (json['grossBill'] as num).toDouble(),
      totalExpenses: totalExpenses.toDouble(),
      expectedTds: (json['expectedTds'] as num).toDouble(),
      expectedNetReceipt: (json['expectedNetReceipt'] as num).toDouble(),
      estimatedProfit: (json['estimatedProfit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'grossBill': grossBill,
        'totalExpenses': totalExpenses,
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
    this.expenses,
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

  /// Nullable so records persisted before the order-money restructure (which
  /// carried expenses under the removed `driverExpense`/charge-split shape)
  /// still decode — see [orderExpenses] for the non-null accessor everywhere
  /// else in the app reads from.
  final OrderExpenses? expenses;
  final BillingDetails billing;
  final FinancialSummary financialSummary;
  final String createdAt;
  final String updatedAt;

  OrderExpenses get orderExpenses => expenses ?? const OrderExpenses.zero();

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
    OrderExpenses? expenses,
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
      expenses: expenses ?? this.expenses,
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
      expenses: json['expenses'] != null
          ? OrderExpenses.fromJson(json['expenses'] as Map<String, dynamic>)
          : OrderExpenses.fromLegacyDriverExpense(json['driverExpense'] as Map<String, dynamic>?),
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
        'expenses': orderExpenses.toJson(),
        'billing': billing.toJson(),
        'financialSummary': financialSummary.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
