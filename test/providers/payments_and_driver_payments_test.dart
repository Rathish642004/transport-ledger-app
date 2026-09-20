import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/domain/payment_allocation_engine.dart';
import 'package:flutter_app/models/company.dart';
import 'package:flutter_app/models/customer.dart';
import 'package:flutter_app/models/enums.dart';
import 'package:flutter_app/models/order.dart';
import 'package:flutter_app/providers/orders_provider.dart';
import 'package:flutter_app/providers/party_ledger_provider.dart';
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
);

const _customer = Customer(
  id: 'cust-1',
  name: 'Test Customer',
  contactPerson: 'Y',
  phone: '000',
  deliveryAddress: 'addr',
  city: 'city',
);

Order _order({
  required String id,
  required String orderDate,
  required String createdAt,
  double totalCustomerBill = 1000,
}) {
  return Order(
    id: id,
    orderNumber: id,
    orderDate: orderDate,
    companyId: 'comp-1',
    companyName: 'Test Co',
    customerId: 'cust-1',
    customerName: 'Test Customer',
    pickupLocation: 'A',
    deliveryLocation: 'B',
    vehicleNumber: 'TN00X0000',
    numberOfBags: 10,
    bagType: 'Bags',
    notes: '',
    orderStatus: OrderStatus.delivered,
    paymentStatus: PaymentStatus.unpaid,
    amountReceived: 0,
    charges: OrderCharges(totalCustomerBill: totalCustomerBill),
    expenses: const OrderExpenses(loadingCharges: 0, transportationCharges: 700, otherCharges: 0),
    billing: BillingDetails(
      billPayer: PayerType.company,
      billRecipientName: 'x',
      billNumber: id,
      billDate: orderDate,
      tdsApplicable: false,
      tdsPercentage: 0,
      tdsAmount: 0,
      otherDeductions: 0,
      netExpectedReceipt: totalCustomerBill,
      paymentTerms: '',
      notes: '',
    ),
    financialSummary: const FinancialSummary(
      grossBill: 0,
      totalExpenses: 0,
      expectedTds: 0,
      expectedNetReceipt: 0,
      estimatedProfit: 0,
    ),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await openTestHive();
    await companiesBox.put(_company.id, _company);
    await customersBox.put(_customer.id, _customer);
  });

  tearDown(() async {
    await closeTestHive(tempDir);
  });

  test('receivePayment records the receipt and updates the order via its allocation', () async {
    final order = _order(id: 'ord-1', orderDate: '2026-01-01', createdAt: '2026-01-01T00:00:00Z', totalCustomerBill: 1000);
    await ordersBox.put(order.id, order);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final receipt = container.read(paymentsProvider.notifier).receivePayment(
          partyId: 'comp-1',
          payerType: PayerType.company,
          payerName: 'Test Co',
          amountReceived: 1000,
          paymentDate: '2026-01-05',
          paymentMethod: PaymentMethod.upi,
          otherDeduction: 0,
          referenceNumber: 'REF-1',
          notes: '',
          allocations: allocateFifo(
            openOrders: [order],
            alreadyAllocated: {order.id: 0},
            amount: 1000,
          ),
        );

    expect(receipt.id, isNotEmpty);
    expect(receipt.receiptNumber, startsWith('RCT-2026-'));
    expect(container.read(paymentsProvider), contains(receipt));

    final updatedOrder = container.read(ordersProvider).firstWhere((o) => o.id == 'ord-1');
    expect(updatedOrder.amountReceived, 1000);
    expect(updatedOrder.paymentStatus, PaymentStatus.paid);

    final ledger = ledgerFor(container.read(partyLedgerProvider), PayerType.company, 'comp-1');
    expect(ledger.received, 1000);
    expect(ledger.outstanding, 0);
  });

  test('a lump-sum payment applies FIFO across a party\'s open orders, oldest first', () async {
    final orderOld = _order(id: 'ord-old', orderDate: '2026-01-01', createdAt: '2026-01-01T00:00:00Z', totalCustomerBill: 600);
    final orderNew = _order(id: 'ord-new', orderDate: '2026-02-01', createdAt: '2026-02-01T00:00:00Z', totalCustomerBill: 600);
    await ordersBox.put(orderOld.id, orderOld);
    await ordersBox.put(orderNew.id, orderNew);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final openOrders = openOrdersForParty(container.read(ordersProvider), payerType: PayerType.company, partyId: 'comp-1');
    final allocations = allocateFifo(
      openOrders: openOrders,
      alreadyAllocated: {for (final o in openOrders) o.id: o.amountReceived},
      amount: 900,
    );

    container.read(paymentsProvider.notifier).receivePayment(
          partyId: 'comp-1',
          payerType: PayerType.company,
          payerName: 'Test Co',
          amountReceived: 900,
          paymentDate: '2026-02-05',
          paymentMethod: PaymentMethod.upi,
          otherDeduction: 0,
          referenceNumber: '',
          notes: '',
          allocations: allocations,
        );

    final orders = container.read(ordersProvider);
    expect(orders.firstWhere((o) => o.id == 'ord-old').amountReceived, 600);
    expect(orders.firstWhere((o) => o.id == 'ord-old').paymentStatus, PaymentStatus.paid);
    expect(orders.firstWhere((o) => o.id == 'ord-new').amountReceived, 300);
    expect(orders.firstWhere((o) => o.id == 'ord-new').paymentStatus, PaymentStatus.partiallyPaid);
  });

  test('removePayment reverses the order and the party ledger', () async {
    final order = _order(id: 'ord-1', orderDate: '2026-01-01', createdAt: '2026-01-01T00:00:00Z', totalCustomerBill: 1000);
    await ordersBox.put(order.id, order);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final receipt = container.read(paymentsProvider.notifier).receivePayment(
          partyId: 'comp-1',
          payerType: PayerType.company,
          payerName: 'Test Co',
          amountReceived: 1000,
          paymentDate: '2026-01-05',
          paymentMethod: PaymentMethod.upi,
          otherDeduction: 0,
          referenceNumber: '',
          notes: '',
          allocations: allocateFifo(openOrders: [order], alreadyAllocated: {order.id: 0}, amount: 1000),
        );

    container.read(paymentsProvider.notifier).removePayment(receipt.id);

    expect(container.read(paymentsProvider).any((p) => p.id == receipt.id), isFalse);
    final updatedOrder = container.read(ordersProvider).firstWhere((o) => o.id == 'ord-1');
    expect(updatedOrder.amountReceived, 0);
    expect(updatedOrder.paymentStatus, PaymentStatus.unpaid);
  });

  test('stripOrderAllocations returns a deleted order\'s share to unallocated credit', () async {
    final order = _order(id: 'ord-1', orderDate: '2026-01-01', createdAt: '2026-01-01T00:00:00Z', totalCustomerBill: 1000);
    await ordersBox.put(order.id, order);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final receipt = container.read(paymentsProvider.notifier).receivePayment(
          partyId: 'comp-1',
          payerType: PayerType.company,
          payerName: 'Test Co',
          amountReceived: 1000,
          paymentDate: '2026-01-05',
          paymentMethod: PaymentMethod.upi,
          otherDeduction: 0,
          referenceNumber: '',
          notes: '',
          allocations: allocateFifo(openOrders: [order], alreadyAllocated: {order.id: 0}, amount: 1000),
        );

    container.read(paymentsProvider.notifier).stripOrderAllocations('ord-1');

    final updatedReceipt = container.read(paymentsProvider).firstWhere((p) => p.id == receipt.id);
    expect(updatedReceipt.allocations, isEmpty);
    expect(updatedReceipt.unallocatedAmount, 1000);
  });
}
