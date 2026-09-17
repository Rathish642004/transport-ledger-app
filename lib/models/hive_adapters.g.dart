// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class OrderStatusAdapter extends TypeAdapter<OrderStatus> {
  @override
  final typeId = 0;

  @override
  OrderStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OrderStatus.draft;
      case 1:
        return OrderStatus.booked;
      case 2:
        return OrderStatus.inTransit;
      case 3:
        return OrderStatus.delivered;
      case 4:
        return OrderStatus.completed;
      case 5:
        return OrderStatus.cancelled;
      default:
        return OrderStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, OrderStatus obj) {
    switch (obj) {
      case OrderStatus.draft:
        writer.writeByte(0);
      case OrderStatus.booked:
        writer.writeByte(1);
      case OrderStatus.inTransit:
        writer.writeByte(2);
      case OrderStatus.delivered:
        writer.writeByte(3);
      case OrderStatus.completed:
        writer.writeByte(4);
      case OrderStatus.cancelled:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentStatusAdapter extends TypeAdapter<PaymentStatus> {
  @override
  final typeId = 1;

  @override
  PaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentStatus.unpaid;
      case 1:
        return PaymentStatus.partiallyPaid;
      case 2:
        return PaymentStatus.paid;
      case 3:
        return PaymentStatus.overdue;
      default:
        return PaymentStatus.unpaid;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentStatus obj) {
    switch (obj) {
      case PaymentStatus.unpaid:
        writer.writeByte(0);
      case PaymentStatus.partiallyPaid:
        writer.writeByte(1);
      case PaymentStatus.paid:
        writer.writeByte(2);
      case PaymentStatus.overdue:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DriverPaymentStatusAdapter extends TypeAdapter<DriverPaymentStatus> {
  @override
  final typeId = 2;

  @override
  DriverPaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DriverPaymentStatus.unpaid;
      case 1:
        return DriverPaymentStatus.advancePaid;
      case 2:
        return DriverPaymentStatus.partiallyPaid;
      case 3:
        return DriverPaymentStatus.paidInFull;
      default:
        return DriverPaymentStatus.unpaid;
    }
  }

  @override
  void write(BinaryWriter writer, DriverPaymentStatus obj) {
    switch (obj) {
      case DriverPaymentStatus.unpaid:
        writer.writeByte(0);
      case DriverPaymentStatus.advancePaid:
        writer.writeByte(1);
      case DriverPaymentStatus.partiallyPaid:
        writer.writeByte(2);
      case DriverPaymentStatus.paidInFull:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverPaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final typeId = 3;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.cash;
      case 1:
        return PaymentMethod.upi;
      case 2:
        return PaymentMethod.bankTransfer;
      case 3:
        return PaymentMethod.cheque;
      default:
        return PaymentMethod.cash;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    switch (obj) {
      case PaymentMethod.cash:
        writer.writeByte(0);
      case PaymentMethod.upi:
        writer.writeByte(1);
      case PaymentMethod.bankTransfer:
        writer.writeByte(2);
      case PaymentMethod.cheque:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PayerTypeAdapter extends TypeAdapter<PayerType> {
  @override
  final typeId = 4;

  @override
  PayerType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PayerType.customer;
      case 1:
        return PayerType.company;
      default:
        return PayerType.customer;
    }
  }

  @override
  void write(BinaryWriter writer, PayerType obj) {
    switch (obj) {
      case PayerType.customer:
        writer.writeByte(0);
      case PayerType.company:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayerTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseCategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final typeId = 5;

  @override
  ExpenseCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseCategory.fuel;
      case 1:
        return ExpenseCategory.tollTax;
      case 2:
        return ExpenseCategory.loadingLabour;
      case 3:
        return ExpenseCategory.unloadingLabour;
      case 4:
        return ExpenseCategory.rtoPolice;
      case 5:
        return ExpenseCategory.vehicleMaintenance;
      case 6:
        return ExpenseCategory.weighbridgeKaanta;
      case 7:
        return ExpenseCategory.officeTea;
      case 8:
        return ExpenseCategory.otherTransport;
      default:
        return ExpenseCategory.fuel;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseCategory obj) {
    switch (obj) {
      case ExpenseCategory.fuel:
        writer.writeByte(0);
      case ExpenseCategory.tollTax:
        writer.writeByte(1);
      case ExpenseCategory.loadingLabour:
        writer.writeByte(2);
      case ExpenseCategory.unloadingLabour:
        writer.writeByte(3);
      case ExpenseCategory.rtoPolice:
        writer.writeByte(4);
      case ExpenseCategory.vehicleMaintenance:
        writer.writeByte(5);
      case ExpenseCategory.weighbridgeKaanta:
        writer.writeByte(6);
      case ExpenseCategory.officeTea:
        writer.writeByte(7);
      case ExpenseCategory.otherTransport:
        writer.writeByte(8);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BackupFrequencyAdapter extends TypeAdapter<BackupFrequency> {
  @override
  final typeId = 6;

  @override
  BackupFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BackupFrequency.daily;
      case 1:
        return BackupFrequency.weekly;
      case 2:
        return BackupFrequency.monthly;
      default:
        return BackupFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, BackupFrequency obj) {
    switch (obj) {
      case BackupFrequency.daily:
        writer.writeByte(0);
      case BackupFrequency.weekly:
        writer.writeByte(1);
      case BackupFrequency.monthly:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final typeId = 7;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.synced;
      case 1:
        return SyncStatus.pending;
      case 2:
        return SyncStatus.never;
      case 3:
        return SyncStatus.syncing;
      default:
        return SyncStatus.synced;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.synced:
        writer.writeByte(0);
      case SyncStatus.pending:
        writer.writeByte(1);
      case SyncStatus.never:
        writer.writeByte(2);
      case SyncStatus.syncing:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderNoteItemAdapter extends TypeAdapter<OrderNoteItem> {
  @override
  final typeId = 8;

  @override
  OrderNoteItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderNoteItem(
      id: fields[0] as String,
      text: fields[1] as String,
      createdAt: fields[2] as String,
      author: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderNoteItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.author);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderNoteItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderChargesAdapter extends TypeAdapter<OrderCharges> {
  @override
  final typeId = 9;

  @override
  OrderCharges read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderCharges(
      loadingCharges: (fields[0] as num).toDouble(),
      transportationCharges: (fields[1] as num).toDouble(),
      otherCharges: (fields[2] as num).toDouble(),
      totalCustomerBill: (fields[3] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, OrderCharges obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.loadingCharges)
      ..writeByte(1)
      ..write(obj.transportationCharges)
      ..writeByte(2)
      ..write(obj.otherCharges)
      ..writeByte(3)
      ..write(obj.totalCustomerBill);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderChargesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DriverExpenseAdapter extends TypeAdapter<DriverExpense> {
  @override
  final typeId = 10;

  @override
  DriverExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DriverExpense(
      driverId: fields[0] as String,
      driverName: fields[1] as String,
      driverFreight: (fields[2] as num).toDouble(),
      driverPaidAmount: (fields[3] as num).toDouble(),
      driverPaymentStatus: fields[4] as DriverPaymentStatus,
      driverBillNumber: fields[5] as String,
      driverBillDate: fields[6] as String,
      driverBillAttachment: fields[7] as String?,
      additionalLoadingExpense: (fields[8] as num).toDouble(),
      otherTransportExpense: (fields[9] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, DriverExpense obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.driverId)
      ..writeByte(1)
      ..write(obj.driverName)
      ..writeByte(2)
      ..write(obj.driverFreight)
      ..writeByte(3)
      ..write(obj.driverPaidAmount)
      ..writeByte(4)
      ..write(obj.driverPaymentStatus)
      ..writeByte(5)
      ..write(obj.driverBillNumber)
      ..writeByte(6)
      ..write(obj.driverBillDate)
      ..writeByte(7)
      ..write(obj.driverBillAttachment)
      ..writeByte(8)
      ..write(obj.additionalLoadingExpense)
      ..writeByte(9)
      ..write(obj.otherTransportExpense);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BillingDetailsAdapter extends TypeAdapter<BillingDetails> {
  @override
  final typeId = 11;

  @override
  BillingDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillingDetails(
      billPayer: fields[0] as PayerType,
      billRecipientName: fields[1] as String,
      billNumber: fields[2] as String,
      billDate: fields[3] as String,
      tdsApplicable: fields[4] as bool,
      tdsPercentage: (fields[5] as num).toDouble(),
      tdsAmount: (fields[6] as num).toDouble(),
      otherDeductions: (fields[7] as num).toDouble(),
      netExpectedReceipt: (fields[8] as num).toDouble(),
      paymentTerms: fields[9] as String,
      notes: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BillingDetails obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.billPayer)
      ..writeByte(1)
      ..write(obj.billRecipientName)
      ..writeByte(2)
      ..write(obj.billNumber)
      ..writeByte(3)
      ..write(obj.billDate)
      ..writeByte(4)
      ..write(obj.tdsApplicable)
      ..writeByte(5)
      ..write(obj.tdsPercentage)
      ..writeByte(6)
      ..write(obj.tdsAmount)
      ..writeByte(7)
      ..write(obj.otherDeductions)
      ..writeByte(8)
      ..write(obj.netExpectedReceipt)
      ..writeByte(9)
      ..write(obj.paymentTerms)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FinancialSummaryAdapter extends TypeAdapter<FinancialSummary> {
  @override
  final typeId = 12;

  @override
  FinancialSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinancialSummary(
      grossBill: (fields[0] as num).toDouble(),
      driverExpenseTotal: (fields[1] as num).toDouble(),
      otherExpenseTotal: (fields[2] as num).toDouble(),
      expectedTds: (fields[3] as num).toDouble(),
      expectedNetReceipt: (fields[4] as num).toDouble(),
      estimatedProfit: (fields[5] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, FinancialSummary obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.grossBill)
      ..writeByte(1)
      ..write(obj.driverExpenseTotal)
      ..writeByte(2)
      ..write(obj.otherExpenseTotal)
      ..writeByte(3)
      ..write(obj.expectedTds)
      ..writeByte(4)
      ..write(obj.expectedNetReceipt)
      ..writeByte(5)
      ..write(obj.estimatedProfit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final typeId = 13;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      id: fields[0] as String,
      orderNumber: fields[1] as String,
      lrNumber: fields[2] as String?,
      orderDate: fields[3] as String,
      companyId: fields[4] as String,
      companyName: fields[5] as String,
      consignorDivision: fields[6] as String?,
      consignorAddress: fields[7] as String?,
      customerId: fields[8] as String,
      customerName: fields[9] as String,
      consigneeAddress: fields[10] as String?,
      deliveryAddress: fields[11] as String?,
      pickupLocation: fields[12] as String,
      deliveryLocation: fields[13] as String,
      vehicleNumber: fields[14] as String,
      invoiceDetails: fields[15] as String?,
      driverId: fields[16] as String,
      driverName: fields[17] as String,
      numberOfBags: (fields[18] as num).toInt(),
      bagType: fields[19] as String,
      goodsDescription: fields[20] as String?,
      ratePerBag: (fields[21] as num?)?.toDouble(),
      rateUnit: fields[22] as String?,
      notes: fields[23] as String,
      notesHistory: fields[24] == null
          ? const []
          : (fields[24] as List).cast<OrderNoteItem>(),
      orderStatus: fields[25] as OrderStatus,
      paymentStatus: fields[26] as PaymentStatus,
      amountReceived: (fields[27] as num).toDouble(),
      charges: fields[28] as OrderCharges,
      driverExpense: fields[29] as DriverExpense,
      billing: fields[30] as BillingDetails,
      financialSummary: fields[31] as FinancialSummary,
      createdAt: fields[32] as String,
      updatedAt: fields[33] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(34)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderNumber)
      ..writeByte(2)
      ..write(obj.lrNumber)
      ..writeByte(3)
      ..write(obj.orderDate)
      ..writeByte(4)
      ..write(obj.companyId)
      ..writeByte(5)
      ..write(obj.companyName)
      ..writeByte(6)
      ..write(obj.consignorDivision)
      ..writeByte(7)
      ..write(obj.consignorAddress)
      ..writeByte(8)
      ..write(obj.customerId)
      ..writeByte(9)
      ..write(obj.customerName)
      ..writeByte(10)
      ..write(obj.consigneeAddress)
      ..writeByte(11)
      ..write(obj.deliveryAddress)
      ..writeByte(12)
      ..write(obj.pickupLocation)
      ..writeByte(13)
      ..write(obj.deliveryLocation)
      ..writeByte(14)
      ..write(obj.vehicleNumber)
      ..writeByte(15)
      ..write(obj.invoiceDetails)
      ..writeByte(16)
      ..write(obj.driverId)
      ..writeByte(17)
      ..write(obj.driverName)
      ..writeByte(18)
      ..write(obj.numberOfBags)
      ..writeByte(19)
      ..write(obj.bagType)
      ..writeByte(20)
      ..write(obj.goodsDescription)
      ..writeByte(21)
      ..write(obj.ratePerBag)
      ..writeByte(22)
      ..write(obj.rateUnit)
      ..writeByte(23)
      ..write(obj.notes)
      ..writeByte(24)
      ..write(obj.notesHistory)
      ..writeByte(25)
      ..write(obj.orderStatus)
      ..writeByte(26)
      ..write(obj.paymentStatus)
      ..writeByte(27)
      ..write(obj.amountReceived)
      ..writeByte(28)
      ..write(obj.charges)
      ..writeByte(29)
      ..write(obj.driverExpense)
      ..writeByte(30)
      ..write(obj.billing)
      ..writeByte(31)
      ..write(obj.financialSummary)
      ..writeByte(32)
      ..write(obj.createdAt)
      ..writeByte(33)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CompanyAdapter extends TypeAdapter<Company> {
  @override
  final typeId = 14;

  @override
  Company read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Company(
      id: fields[0] as String,
      name: fields[1] as String,
      contactPerson: fields[2] as String,
      phone: fields[3] as String,
      email: fields[4] as String?,
      address: fields[5] as String,
      city: fields[6] as String,
      gstin: fields[7] as String?,
      pan: fields[8] as String?,
      totalOrders: (fields[9] as num).toInt(),
      totalBagsDispatched: (fields[10] as num).toInt(),
      totalBilled: (fields[11] as num).toDouble(),
      totalReceived: (fields[12] as num).toDouble(),
      outstandingBalance: (fields[13] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Company obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.contactPerson)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.city)
      ..writeByte(7)
      ..write(obj.gstin)
      ..writeByte(8)
      ..write(obj.pan)
      ..writeByte(9)
      ..write(obj.totalOrders)
      ..writeByte(10)
      ..write(obj.totalBagsDispatched)
      ..writeByte(11)
      ..write(obj.totalBilled)
      ..writeByte(12)
      ..write(obj.totalReceived)
      ..writeByte(13)
      ..write(obj.outstandingBalance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final typeId = 15;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      id: fields[0] as String,
      name: fields[1] as String,
      contactPerson: fields[2] as String,
      phone: fields[3] as String,
      email: fields[4] as String?,
      deliveryAddress: fields[5] as String,
      city: fields[6] as String,
      gstin: fields[7] as String?,
      pan: fields[8] as String?,
      totalOrders: (fields[9] as num).toInt(),
      totalBagsReceived: (fields[10] as num).toInt(),
      totalBilled: (fields[11] as num).toDouble(),
      totalReceived: (fields[12] as num).toDouble(),
      outstandingBalance: (fields[13] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.contactPerson)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.deliveryAddress)
      ..writeByte(6)
      ..write(obj.city)
      ..writeByte(7)
      ..write(obj.gstin)
      ..writeByte(8)
      ..write(obj.pan)
      ..writeByte(9)
      ..write(obj.totalOrders)
      ..writeByte(10)
      ..write(obj.totalBagsReceived)
      ..writeByte(11)
      ..write(obj.totalBilled)
      ..writeByte(12)
      ..write(obj.totalReceived)
      ..writeByte(13)
      ..write(obj.outstandingBalance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DriverAdapter extends TypeAdapter<Driver> {
  @override
  final typeId = 16;

  @override
  Driver read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Driver(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      vehicleNumber: fields[3] as String,
      licenseNumber: fields[4] as String?,
      totalTrips: (fields[5] as num).toInt(),
      totalAgreedFreight: (fields[6] as num).toDouble(),
      totalAmountPaid: (fields[7] as num).toDouble(),
      outstandingAmount: (fields[8] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Driver obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.vehicleNumber)
      ..writeByte(4)
      ..write(obj.licenseNumber)
      ..writeByte(5)
      ..write(obj.totalTrips)
      ..writeByte(6)
      ..write(obj.totalAgreedFreight)
      ..writeByte(7)
      ..write(obj.totalAmountPaid)
      ..writeByte(8)
      ..write(obj.outstandingAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentReceiptAdapter extends TypeAdapter<PaymentReceipt> {
  @override
  final typeId = 17;

  @override
  PaymentReceipt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentReceipt(
      id: fields[0] as String,
      receiptNumber: fields[1] as String,
      orderId: fields[2] as String,
      orderNumber: fields[3] as String,
      payerType: fields[4] as PayerType,
      payerName: fields[5] as String,
      amountReceived: (fields[6] as num).toDouble(),
      paymentDate: fields[7] as String,
      paymentMethod: fields[8] as PaymentMethod,
      tdsDeducted: (fields[9] as num).toDouble(),
      otherDeduction: (fields[10] as num).toDouble(),
      referenceNumber: fields[11] as String,
      notes: fields[12] as String,
      recordedAt: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentReceipt obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.receiptNumber)
      ..writeByte(2)
      ..write(obj.orderId)
      ..writeByte(3)
      ..write(obj.orderNumber)
      ..writeByte(4)
      ..write(obj.payerType)
      ..writeByte(5)
      ..write(obj.payerName)
      ..writeByte(6)
      ..write(obj.amountReceived)
      ..writeByte(7)
      ..write(obj.paymentDate)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.tdsDeducted)
      ..writeByte(10)
      ..write(obj.otherDeduction)
      ..writeByte(11)
      ..write(obj.referenceNumber)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.recordedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentReceiptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DriverPaymentRecordAdapter extends TypeAdapter<DriverPaymentRecord> {
  @override
  final typeId = 18;

  @override
  DriverPaymentRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DriverPaymentRecord(
      id: fields[0] as String,
      voucherNumber: fields[1] as String,
      driverId: fields[2] as String,
      driverName: fields[3] as String,
      orderId: fields[4] as String,
      orderNumber: fields[5] as String,
      driverBillNumber: fields[6] as String,
      driverBillDate: fields[7] as String,
      agreedFreight: (fields[8] as num).toDouble(),
      amountPaid: (fields[9] as num).toDouble(),
      paymentDate: fields[10] as String,
      paymentMethod: fields[11] as PaymentMethod,
      referenceNumber: fields[12] as String,
      notes: fields[13] as String,
      billAttachmentName: fields[14] as String?,
      recordedAt: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DriverPaymentRecord obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.voucherNumber)
      ..writeByte(2)
      ..write(obj.driverId)
      ..writeByte(3)
      ..write(obj.driverName)
      ..writeByte(4)
      ..write(obj.orderId)
      ..writeByte(5)
      ..write(obj.orderNumber)
      ..writeByte(6)
      ..write(obj.driverBillNumber)
      ..writeByte(7)
      ..write(obj.driverBillDate)
      ..writeByte(8)
      ..write(obj.agreedFreight)
      ..writeByte(9)
      ..write(obj.amountPaid)
      ..writeByte(10)
      ..write(obj.paymentDate)
      ..writeByte(11)
      ..write(obj.paymentMethod)
      ..writeByte(12)
      ..write(obj.referenceNumber)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.billAttachmentName)
      ..writeByte(15)
      ..write(obj.recordedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverPaymentRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseRecordAdapter extends TypeAdapter<ExpenseRecord> {
  @override
  final typeId = 19;

  @override
  ExpenseRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseRecord(
      id: fields[0] as String,
      expenseNumber: fields[1] as String,
      date: fields[2] as String,
      category: fields[3] as ExpenseCategory,
      amount: (fields[4] as num).toDouble(),
      vehicleNumber: fields[5] as String?,
      orderId: fields[6] as String?,
      orderNumber: fields[7] as String?,
      paidTo: fields[8] as String,
      paymentMethod: fields[9] as PaymentMethod,
      notes: fields[10] as String,
      receiptAttachmentName: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseRecord obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.expenseNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.vehicleNumber)
      ..writeByte(6)
      ..write(obj.orderId)
      ..writeByte(7)
      ..write(obj.orderNumber)
      ..writeByte(8)
      ..write(obj.paidTo)
      ..writeByte(9)
      ..write(obj.paymentMethod)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.receiptAttachmentName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransporterProfileAdapter extends TypeAdapter<TransporterProfile> {
  @override
  final typeId = 20;

  @override
  TransporterProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransporterProfile(
      businessName: fields[0] as String,
      tagline: fields[1] as String,
      ownerName: fields[2] as String,
      phone: fields[3] as String,
      email: fields[4] as String,
      address: fields[5] as String,
      city: fields[6] as String,
      state: fields[7] as String,
      pincode: fields[8] as String,
      gstin: fields[9] as String,
      pan: fields[10] as String,
      bankName: fields[11] as String,
      accountNumber: fields[12] as String,
      accountName: fields[13] as String?,
      ifscCode: fields[14] as String,
      branchName: fields[15] as String,
      upiId: fields[16] as String,
      termsAndConditions: fields[17] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TransporterProfile obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.businessName)
      ..writeByte(1)
      ..write(obj.tagline)
      ..writeByte(2)
      ..write(obj.ownerName)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.city)
      ..writeByte(7)
      ..write(obj.state)
      ..writeByte(8)
      ..write(obj.pincode)
      ..writeByte(9)
      ..write(obj.gstin)
      ..writeByte(10)
      ..write(obj.pan)
      ..writeByte(11)
      ..write(obj.bankName)
      ..writeByte(12)
      ..write(obj.accountNumber)
      ..writeByte(13)
      ..write(obj.accountName)
      ..writeByte(14)
      ..write(obj.ifscCode)
      ..writeByte(15)
      ..write(obj.branchName)
      ..writeByte(16)
      ..write(obj.upiId)
      ..writeByte(17)
      ..write(obj.termsAndConditions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransporterProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BackupSyncStateAdapter extends TypeAdapter<BackupSyncState> {
  @override
  final typeId = 21;

  @override
  BackupSyncState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupSyncState(
      googleAccount: fields[0] as String?,
      isConnected: fields[1] as bool,
      autoBackupEnabled: fields[2] as bool,
      backupFrequency: fields[3] as BackupFrequency,
      lastBackupDate: fields[4] as String?,
      syncStatus: fields[5] as SyncStatus,
      totalLocalRecordsCount: (fields[6] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, BackupSyncState obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.googleAccount)
      ..writeByte(1)
      ..write(obj.isConnected)
      ..writeByte(2)
      ..write(obj.autoBackupEnabled)
      ..writeByte(3)
      ..write(obj.backupFrequency)
      ..writeByte(4)
      ..write(obj.lastBackupDate)
      ..writeByte(5)
      ..write(obj.syncStatus)
      ..writeByte(6)
      ..write(obj.totalLocalRecordsCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupSyncStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
