import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/company.dart';
import 'package:flutter_app/models/customer.dart';
import 'package:flutter_app/models/enums.dart';
import 'package:flutter_app/models/order.dart';
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
);

const _customer = Customer(
  id: 'cust-1',
  name: 'Test Customer',
  contactPerson: 'Y',
  phone: '000',
  deliveryAddress: 'addr',
  city: 'city',
);

Order _newOrderPayload({
  PayerType billPayer = PayerType.customer,
  double totalCustomerBill = 1000,
  double netExpectedReceipt = 1000,
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
    vehicleNumber: 'TN00X0000',
    numberOfBags: 15,
    bagType: 'Bags',
    notes: '',
    orderStatus: OrderStatus.booked,
    paymentStatus: PaymentStatus.unpaid,
    amountReceived: 0,
    charges: OrderCharges(totalCustomerBill: totalCustomerBill),
    expenses: const OrderExpenses(loadingCharges: 0, transportationCharges: 700, otherCharges: 0),
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
      totalExpenses: 0,
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
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  test('createOrder assigns id/timestamps', () {
    final payload = _newOrderPayload(billPayer: PayerType.company, totalCustomerBill: 5000, netExpectedReceipt: 5000);
    final created = container.read(ordersProvider.notifier).createOrder(payload);

    expect(created.id, isNotEmpty);
    expect(created.createdAt, isNotEmpty);
    expect(created.updatedAt, isNotEmpty);
    expect(container.read(ordersProvider), contains(created));
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

  group('recomputeFromAllocations payment-status thresholds', () {
    test('partial payment -> Partially Paid', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(totalCustomerBill: 1000, netExpectedReceipt: 1000));
      container.read(ordersProvider.notifier).recomputeFromAllocations({created.id}, {created.id: 400});

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.paymentStatus, PaymentStatus.partiallyPaid);
      expect(updated.amountReceived, 400);
    });

    test('payment reaching the full receivable -> Paid', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(totalCustomerBill: 1000, netExpectedReceipt: 1000));
      container.read(ordersProvider.notifier).recomputeFromAllocations({created.id}, {created.id: 1000});

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.paymentStatus, PaymentStatus.paid);
    });

    test('overpayment still resolves to Paid (>= threshold)', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(totalCustomerBill: 1000, netExpectedReceipt: 1000));
      container.read(ordersProvider.notifier).recomputeFromAllocations({created.id}, {created.id: 1500});

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.paymentStatus, PaymentStatus.paid);
    });

    test('recompute is idempotent — it always rewrites from the given total, never a delta', () {
      final created = container.read(ordersProvider.notifier).createOrder(_newOrderPayload(totalCustomerBill: 1000, netExpectedReceipt: 1000));
      container.read(ordersProvider.notifier).recomputeFromAllocations({created.id}, {created.id: 400});
      container.read(ordersProvider.notifier).recomputeFromAllocations({created.id}, {created.id: 900});

      final updated = container.read(ordersProvider).firstWhere((o) => o.id == created.id);
      expect(updated.amountReceived, 900);
      expect(updated.paymentStatus, PaymentStatus.partiallyPaid);
    });
  });
}
