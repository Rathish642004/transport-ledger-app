import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/company.dart';
import 'package:flutter_app/models/customer.dart';
import 'package:flutter_app/models/driver.dart';
import 'package:flutter_app/models/driver_payment_record.dart';
import 'package:flutter_app/models/enums.dart';
import 'package:flutter_app/models/order.dart';
import 'package:flutter_app/models/payment_receipt.dart';
import 'package:flutter_app/providers/companies_provider.dart';
import 'package:flutter_app/providers/customers_provider.dart';
import 'package:flutter_app/providers/driver_payments_provider.dart';
import 'package:flutter_app/providers/drivers_provider.dart';
import 'package:flutter_app/providers/orders_provider.dart';
import 'package:flutter_app/providers/payments_provider.dart';
import 'package:flutter_app/storage/hive_boxes.dart';

import '../test_helpers/hive_test_env.dart';

const _company = Company(
  id: 'comp-1',
  name: 'Test Co',
  contactPerson: 'X',
  phone: '000',
  address: 'addr',
  city: 'city',
  totalOrders: 1,
  totalBagsDispatched: 10,
  totalBilled: 1000,
  totalReceived: 0,
  outstandingBalance: 1000,
);

const _driver = Driver(
  id: 'drv-1',
  name: 'Test Driver',
  phone: '000',
  vehicleNumber: 'TN00X0000',
  totalTrips: 1,
  totalAgreedFreight: 700,
  totalAmountPaid: 0,
  outstandingAmount: 700,
);

final _order = Order(
  id: 'ord-1',
  orderNumber: 'ORD-1',
  orderDate: '2026-01-01',
  companyId: 'comp-1',
  companyName: 'Test Co',
  customerId: 'cust-1',
  customerName: 'Test Customer',
  pickupLocation: 'A',
  deliveryLocation: 'B',
  vehicleNumber: 'TN00X0000',
  driverId: 'drv-1',
  driverName: 'Test Driver',
  numberOfBags: 10,
  bagType: 'Bags',
  notes: '',
  orderStatus: OrderStatus.delivered,
  paymentStatus: PaymentStatus.unpaid,
  amountReceived: 0,
  charges: const OrderCharges(
    loadingCharges: 0,
    transportationCharges: 1000,
    otherCharges: 0,
    totalCustomerBill: 1000,
  ),
  driverExpense: const DriverExpense(
    driverId: 'drv-1',
    driverName: 'Test Driver',
    driverFreight: 700,
    driverPaidAmount: 0,
    driverPaymentStatus: DriverPaymentStatus.unpaid,
    driverBillNumber: '',
    driverBillDate: '2026-01-01',
    additionalLoadingExpense: 0,
    otherTransportExpense: 0,
  ),
  billing: const BillingDetails(
    billPayer: PayerType.company,
    billRecipientName: 'x',
    billNumber: 'ORD-1',
    billDate: '2026-01-01',
    tdsApplicable: false,
    tdsPercentage: 0,
    tdsAmount: 0,
    otherDeductions: 0,
    netExpectedReceipt: 1000,
    paymentTerms: '',
    notes: '',
  ),
  financialSummary: const FinancialSummary(
    grossBill: 0,
    driverExpenseTotal: 0,
    otherExpenseTotal: 0,
    expectedTds: 0,
    expectedNetReceipt: 0,
    estimatedProfit: 0,
  ),
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
);

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    await companiesBox.put(_company.id, _company);
    await customersBox.put(
      'cust-1',
      const Customer(
        id: 'cust-1',
        name: 'Test Customer',
        contactPerson: 'Y',
        phone: '000',
        deliveryAddress: 'addr',
        city: 'city',
        totalOrders: 0,
        totalBagsReceived: 0,
        totalBilled: 0,
        totalReceived: 0,
        outstandingBalance: 0,
      ),
    );
    await driversBox.put(_driver.id, _driver);
    await ordersBox.put(_order.id, _order);
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  test('receivePayment records the receipt, updates the order, and updates the company balance', () {
    final receipt = container.read(paymentsProvider.notifier).receivePayment(
          PaymentReceipt(
            id: '',
            receiptNumber: '',
            orderId: 'ord-1',
            orderNumber: 'ORD-1',
            payerType: PayerType.company,
            payerName: 'Test Co',
            amountReceived: 1000,
            paymentDate: '2026-01-05',
            paymentMethod: PaymentMethod.upi,
            tdsDeducted: 0,
            otherDeduction: 0,
            referenceNumber: 'REF-1',
            notes: '',
            recordedAt: '',
          ),
        );

    expect(receipt.id, isNotEmpty);
    expect(receipt.receiptNumber, startsWith('RCT-2026-'));
    expect(container.read(paymentsProvider), contains(receipt));

    final order = container.read(ordersProvider).firstWhere((o) => o.id == 'ord-1');
    expect(order.amountReceived, 1000);
    expect(order.paymentStatus, PaymentStatus.paid);

    final company = container.read(companiesProvider).firstWhere((c) => c.id == 'comp-1');
    expect(company.totalReceived, 1000);
    expect(company.outstandingBalance, 0); // 1000 - 1000, clamped at 0
  });

  test('receivePayment updates customer balance when payerType is Customer', () {
    container.read(paymentsProvider.notifier).receivePayment(
          PaymentReceipt(
            id: '',
            receiptNumber: '',
            orderId: 'ord-1',
            orderNumber: 'ORD-1',
            payerType: PayerType.customer,
            payerName: 'Test Customer',
            amountReceived: 250,
            paymentDate: '2026-01-05',
            paymentMethod: PaymentMethod.cash,
            tdsDeducted: 0,
            otherDeduction: 0,
            referenceNumber: '',
            notes: '',
            recordedAt: '',
          ),
        );

    final customer = container.read(customersProvider).firstWhere((c) => c.id == 'cust-1');
    expect(customer.totalReceived, 250);
    // The company balance must be untouched since payerType was Customer.
    final company = container.read(companiesProvider).firstWhere((c) => c.id == 'comp-1');
    expect(company.totalReceived, 0);
  });

  test('payDriver records the voucher, updates the order driver-expense, and updates the driver balance', () {
    final voucher = container.read(driverPaymentsProvider.notifier).payDriver(
          DriverPaymentRecord(
            id: '',
            voucherNumber: '',
            driverId: 'drv-1',
            driverName: 'Test Driver',
            orderId: 'ord-1',
            orderNumber: 'ORD-1',
            driverBillNumber: 'DB-1',
            driverBillDate: '2026-01-05',
            agreedFreight: 700,
            amountPaid: 700,
            paymentDate: '2026-01-05',
            paymentMethod: PaymentMethod.cash,
            referenceNumber: '',
            notes: '',
            recordedAt: '',
          ),
        );

    expect(voucher.id, isNotEmpty);
    expect(voucher.voucherNumber, startsWith('DRV-2026-'));

    final order = container.read(ordersProvider).firstWhere((o) => o.id == 'ord-1');
    expect(order.driverExpense.driverPaidAmount, 700);
    expect(order.driverExpense.driverPaymentStatus, DriverPaymentStatus.paidInFull);
    expect(order.driverExpense.driverBillNumber, 'DB-1');

    final driver = container.read(driversProvider).firstWhere((d) => d.id == 'drv-1');
    expect(driver.totalAmountPaid, 700);
    expect(driver.outstandingAmount, 0);
  });
}
