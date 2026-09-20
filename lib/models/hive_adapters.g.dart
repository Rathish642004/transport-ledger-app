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
    return OrderCharges(totalCustomerBill: (fields[3] as num).toDouble());
  }

  @override
  void write(BinaryWriter writer, OrderCharges obj) {
    writer
      ..writeByte(1)
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
      totalExpenses: (fields[6] as num).toDouble(),
      expectedTds: (fields[3] as num).toDouble(),
      expectedNetReceipt: (fields[4] as num).toDouble(),
      estimatedProfit: (fields[5] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, FinancialSummary obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.grossBill)
      ..writeByte(3)
      ..write(obj.expectedTds)
      ..writeByte(4)
      ..write(obj.expectedNetReceipt)
      ..writeByte(5)
      ..write(obj.estimatedProfit)
      ..writeByte(6)
      ..write(obj.totalExpenses);
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
      expenses: fields[34] as OrderExpenses?,
      billing: fields[30] as BillingDetails,
      financialSummary: fields[31] as FinancialSummary,
      createdAt: fields[32] as String,
      updatedAt: fields[33] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(31)
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
      ..writeByte(30)
      ..write(obj.billing)
      ..writeByte(31)
      ..write(obj.financialSummary)
      ..writeByte(32)
      ..write(obj.createdAt)
      ..writeByte(33)
      ..write(obj.updatedAt)
      ..writeByte(34)
      ..write(obj.expenses);
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
      tdsApplicable: fields[14] as bool?,
      tdsPercentage: (fields[15] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Company obj) {
    writer
      ..writeByte(11)
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
      ..writeByte(14)
      ..write(obj.tdsApplicable)
      ..writeByte(15)
      ..write(obj.tdsPercentage);
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
      tdsApplicable: fields[14] as bool?,
      tdsPercentage: (fields[15] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(11)
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
      ..writeByte(14)
      ..write(obj.tdsApplicable)
      ..writeByte(15)
      ..write(obj.tdsPercentage);
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
      partyId: fields[15] as String?,
      orderId: fields[2] as String?,
      orderNumber: fields[3] as String?,
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
      bankAccountId: fields[14] as String?,
      allocations: fields[16] == null
          ? const []
          : (fields[16] as List).cast<PaymentAllocation>(),
    );
  }

  @override
  void write(BinaryWriter writer, PaymentReceipt obj) {
    writer
      ..writeByte(17)
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
      ..write(obj.recordedAt)
      ..writeByte(14)
      ..write(obj.bankAccountId)
      ..writeByte(15)
      ..write(obj.partyId)
      ..writeByte(16)
      ..write(obj.allocations);
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
      bankAccountId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseRecord obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.receiptAttachmentName)
      ..writeByte(12)
      ..write(obj.bankAccountId);
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

class BankAccountAdapter extends TypeAdapter<BankAccount> {
  @override
  final typeId = 22;

  @override
  BankAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BankAccount(
      id: fields[0] as String,
      bankName: fields[1] as String,
      accountHolderName: fields[2] as String,
      accountNumber: fields[3] as String,
      ifscCode: fields[4] as String,
      branchName: fields[5] as String,
      upiId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BankAccount obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bankName)
      ..writeByte(2)
      ..write(obj.accountHolderName)
      ..writeByte(3)
      ..write(obj.accountNumber)
      ..writeByte(4)
      ..write(obj.ifscCode)
      ..writeByte(5)
      ..write(obj.branchName)
      ..writeByte(6)
      ..write(obj.upiId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderExpensesAdapter extends TypeAdapter<OrderExpenses> {
  @override
  final typeId = 24;

  @override
  OrderExpenses read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderExpenses(
      loadingCharges: (fields[0] as num).toDouble(),
      transportationCharges: (fields[1] as num).toDouble(),
      otherCharges: (fields[2] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, OrderExpenses obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.loadingCharges)
      ..writeByte(1)
      ..write(obj.transportationCharges)
      ..writeByte(2)
      ..write(obj.otherCharges);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderExpensesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentAllocationAdapter extends TypeAdapter<PaymentAllocation> {
  @override
  final typeId = 25;

  @override
  PaymentAllocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentAllocation(
      orderId: fields[0] as String,
      orderNumber: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      tdsSettled: (fields[3] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, PaymentAllocation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.orderId)
      ..writeByte(1)
      ..write(obj.orderNumber)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.tdsSettled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAllocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
