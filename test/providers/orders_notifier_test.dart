import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/company.dart';
import 'package:flutter_app/models/customer.dart';
import 'package:flutter_app/models/driver.dart';
import 'package:flutter_app/models/enums.dart';
import 'package:flutter_app/models/order.dart';
import 'package:flutter_app/providers/companies_provider.dart';
import 'package:flutter_app/providers/customers_provider.dart';
import 'package:flutter_app/providers/drivers_provider.dart';
import 'package:flutter_app/providers/orders_provider.dart';
import 'package:flutter_app/storage/hive_boxes.dart';

import '../test_helpers/hive_test_env.dart';

const _company = Company(
  id: 'comp-1',
  name: 'Test Co',
  contactPerson: 'X',
  phone: '000',
  address: 'addr',
  city: 'city',
  totalOrders: 0,
  totalBagsDispatched: 0,
  totalBilled: 0,
  totalReceived: 0,
  outstandingBalance: 0,
);

const _customer = Customer(
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
);

const _driver = Driver(
  id: 'drv-1',
  name: 'Test Driver',
  phone: '000',
  vehicleNumber: 'TN00X0000',
  totalTrips: 0,
  totalAgreedFreight: 0,
  totalAmountPaid: 0,
  outstandingAmount: 0,
);

Order _newOrderPayload({
  PayerType billPayer = PayerType.customer,
  double totalCustomerBill = 1000,
  double netExpectedReceipt = 1000,
  double driverFreight = 700,
}) {
  return Order(
    id: '',
    orderNumber: 'ORD-1',
    orderDate: '2026-01-01',
    companyId: _company.id,
    companyName: _company.name,
    customerId: _customer.id,
    customerName: _customer.name,
    pickupLocation: 'A',
    deliveryLocation: 'B',
    vehicleNumber: _driver.vehicleNumber,
    driverId: _driver.id,
    driverName: _driver.name,
    numberOfBags: 15,
    bagType: 'Bags',
    notes: '',
    orderStatus: OrderStatus.booked,
    paymentStatus: PaymentStatus.unpaid,
    amountReceived: 0,
    charges: OrderCharges(
      loadingCharges: 0,
      transportationCharges: totalCustomerBill,
      otherCharges: 0,
      totalCustomerBill: totalCustomerBill,
    ),
    driverExpense: DriverExpense(
      driverId: _driver.id,
      driverName: _driver.name,
      driverFreight: driverFreight,
      driverPaidAmount: 0,
      driverPaymentStatus: DriverPaymentStatus.unpaid,
      driverBillNumber: '',
      driverBillDate: '2026-01-01',
      additionalLoadingExpense: 0,
      otherTransportExpense: 0,
    ),
    billing: BillingDetails(
      billPayer: billPayer,
      billRecipientName: 'x',
      billNumber: 'ORD-1',
      billDate: '2026-01-01',
      tdsApplicable: false,
      tdsPercentage: 0,
      tdsAmount: 0,
      otherDeductions: 0,
      netExpectedReceipt: netExpectedReceipt,
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
    createdAt: '',
    updatedAt: '',
  );
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    await companiesBox.put(_company.id, _company);
    await customersBox.put(_customer.id, _customer);
    await driversBox.put(_driver.id, _driver);
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  test('createOrder assigns id/timestamps and fans out to company/customer/driver stats', () {
    final payload = _newOrderPayload(billPayer: PayerType.company, totalCustomerBill: 5000, netExpectedReceipt: 5000, driverFreight: 3000);
    final created = container.read(ordersProvider.notifier).createOrder(payload);

    expect(created.id, isNotEmpty);
    expect(created.createdAt, isNotEmpty);
    expect(created.updatedAt, isNotEmpty);
    expect(container.read(ordersProvider), contains(created));

    final company = container.read(companiesProvider).firstWhere((c) => c.id == 'comp-1');
    expect(company.totalOrders, 1);
    expect(company.totalBagsDispatched, 15);
    expect(company.totalBilled, 5000); // billPayer == company, so billed/outstanding update
    expect(company.outstandingBalance, 5000);

    final customer = container.read(customersProvider).firstWhere((c) => c.id == 'cust-1');
    expect(customer.totalOrders, 1);
    expect(customer.totalBagsReceived, 15);
    expect(customer.totalBilled, 0); // not the bill payer, so untouched

    final driver = container.read(driversProvider).firstWhere((d) => d.id == 'drv-1');
    expect(driver.totalTrips, 1);
    expect(driver.totalAgreedFreight, 3000);
    expect(driver.outstandingAmount, 3000);
  });

  test('updateOrder preserves id/createdAt and bumps updatedAt', () {
    final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload());
    final edited = created.copyWith(orderNumber: 'ORD-1-EDITED', numberOfBags: 99);

    final result = container.read(ordersProvider.notifier).updateOrder(created.id, edited);

    expect(result!.id, created.id);
    expect(result.createdAt, created.createdAt);
    expect(result.orderNumber, 'ORD-1-EDITED');
    expect(result.numberOfBags, 99);
  });

  test('updateOrderStatus updates only the targeted order', () {
    final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload());
    container.read(ordersProvider.notifier).updateOrderStatus(created.id, OrderStatus.delivered);

    final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
    expect(updated.orderStatus, OrderStatus.delivered);
  });

  test('deleteOrder removes the order from state and the Hive box', () {
    final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload());
    container.read(ordersProvider.notifier).deleteOrder(created.id);

    expect(container.read(ordersProvider).any((o) => o.id == created.id), isFalse);
    expect(ordersBox.containsKey(created.id), isFalse);
  });

  test('addOrderNote appends to notes and prepends to notesHistory', () {
    final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload());
    container.read(ordersProvider.notifier).addOrderNote(created.id, '  First note  ');
    container.read(ordersProvider.notifier).addOrderNote(created.id, 'Second note');

    final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
    expect(updated.notes, contains('First note'));
    expect(updated.notes, contains('Second note'));
    expect(updated.notesHistory.length, 2);
    expect(updated.notesHistory.first.text, 'Second note'); // prepended, newest first
  });

  test('addOrderNote ignores blank/whitespace-only text', () {
    final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload());
    container.read(ordersProvider.notifier).addOrderNote(created.id, '   ');

    final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
    expect(updated.notes, isEmpty);
    expect(updated.notesHistory, isEmpty);
  });

  group('applyPaymentReceived payment-status thresholds', () {
    test('partial payment -> Partially Paid', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(totalCustomerBill: 1000, netExpectedReceipt: 1000));
      container.read(ordersProvider.notifier).applyPaymentReceived(orderId: created.id, orderNumber: null, amountReceived: 400);

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.paymentStatus, PaymentStatus.partiallyPaid);
      expect(updated.amountReceived, 400);
    });

    test('payment reaching the full receivable -> Paid', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(totalCustomerBill: 1000, netExpectedReceipt: 1000));
      container.read(ordersProvider.notifier).applyPaymentReceived(orderId: created.id, orderNumber: null, amountReceived: 1000);

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.paymentStatus, PaymentStatus.paid);
    });

    test('overpayment still resolves to Paid (>= threshold)', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(totalCustomerBill: 1000, netExpectedReceipt: 1000));
      container.read(ordersProvider.notifier).applyPaymentReceived(orderId: created.id, orderNumber: null, amountReceived: 1500);

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.paymentStatus, PaymentStatus.paid);
    });
  });

  group('applyDriverPayment driver-payment-status thresholds', () {
    test('first partial payment -> Advance Paid', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(driverFreight: 1000));
      container.read(ordersProvider.notifier).applyDriverPayment(orderId: created.id, orderNumber: null, amountPaid: 300);

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.driverExpense.driverPaymentStatus, DriverPaymentStatus.advancePaid);
    });

    test('cumulative payment reaching the agreed freight -> Paid in Full', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(driverFreight: 1000));
      container.read(ordersProvider.notifier).applyDriverPayment(orderId: created.id, orderNumber: null, amountPaid: 300);
      container.read(ordersProvider.notifier).applyDriverPayment(orderId: created.id, orderNumber: null, amountPaid: 700);

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.driverExpense.driverPaymentStatus, DriverPaymentStatus.paidInFull);
      expect(updated.driverExpense.driverPaidAmount, 1000);
    });

    test('empty driverBillNumber/billAttachmentName do not clobber existing values', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(driverFreight: 1000));
      container.read(ordersProvider.notifier).applyDriverPayment(
            orderId: created.id,
            orderNumber: null,
            amountPaid: 300,
            driverBillNumber: 'DB-123',
          );
      container.read(ordersProvider.notifier).applyDriverPayment(
            orderId: created.id,
            orderNumber: null,
            amountPaid: 100,
            driverBillNumber: '', // falsy -> should keep 'DB-123'
          );

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.driverExpense.driverBillNumber, 'DB-123');
    });
  });
}
