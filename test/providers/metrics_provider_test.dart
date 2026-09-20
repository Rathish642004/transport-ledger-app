import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/enums.dart';
import 'package:flutter_app/models/expense_record.dart';
import 'package:flutter_app/models/order.dart';
import 'package:flutter_app/models/payment_allocation.dart';
import 'package:flutter_app/models/payment_receipt.dart';
import 'package:flutter_app/providers/all_transactions_provider.dart';
import 'package:flutter_app/providers/metrics_provider.dart';
import 'package:flutter_app/storage/hive_boxes.dart';

import '../test_helpers/hive_test_env.dart';

/// A minimal-but-complete [Order] fixture builder — only the fields that
/// matter for metrics/ledger math vary per call site.
Order _order({
  required String id,
  required String orderDate,
  required OrderStatus orderStatus,
  required PaymentStatus paymentStatus,
  required PayerType billPayer,
  required double totalCustomerBill,
  required double netExpectedReceipt,
  required double amountReceived,
  double transportationExpense = 0,
  double loadingExpense = 0,
  double otherExpense = 0,
  int numberOfBags = 10,
}) {
  return Order(
    id: id,
    orderNumber: id,
    orderDate: orderDate,
    companyId: 'comp-x',
    companyName: 'Test Co',
    customerId: 'cust-x',
    customerName: 'Test Customer',
    pickupLocation: 'Pickup City, State',
    deliveryLocation: 'Delivery City, State',
    vehicleNumber: 'TN00X0000',
    numberOfBags: numberOfBags,
    bagType: 'Test Bags',
    notes: '',
    orderStatus: orderStatus,
    paymentStatus: paymentStatus,
    amountReceived: amountReceived,
    charges: OrderCharges(totalCustomerBill: totalCustomerBill),
    expenses: OrderExpenses(
      loadingCharges: loadingExpense,
      transportationCharges: transportationExpense,
      otherCharges: otherExpense,
    ),
    billing: BillingDetails(
      billPayer: billPayer,
      billRecipientName: 'Test',
      billNumber: id,
      billDate: orderDate,
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
    createdAt: '${orderDate}T00:00:00Z',
    updatedAt: '${orderDate}T00:00:00Z',
  );
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await openTestHive();

    // Order A: Customer bill, partially paid, not overdue, delivered.
    final orderA = _order(
      id: 'A',
      orderDate: '2026-01-01',
      orderStatus: OrderStatus.delivered,
      paymentStatus: PaymentStatus.partiallyPaid,
      billPayer: PayerType.customer,
      totalCustomerBill: 1000,
      netExpectedReceipt: 1000,
      amountReceived: 400,
      transportationExpense: 600,
      loadingExpense: 50,
      otherExpense: 30,
      numberOfBags: 10,
    );

    // Order B: Cancelled — must be excluded from every sum except the raw
    // `orders` list (ordersInProgressCount reads that, but Cancelled never
    // matches Booked/InTransit anyway).
    final orderB = _order(
      id: 'B',
      orderDate: '2026-01-15',
      orderStatus: OrderStatus.cancelled,
      paymentStatus: PaymentStatus.unpaid,
      billPayer: PayerType.customer,
      totalCustomerBill: 99999,
      netExpectedReceipt: 99999,
      amountReceived: 0,
      transportationExpense: 99999,
      numberOfBags: 999,
    );

    // Order C: Company bill, overdue, booked (in-progress).
    final orderC = _order(
      id: 'C',
      orderDate: '2026-03-01',
      orderStatus: OrderStatus.booked,
      paymentStatus: PaymentStatus.overdue,
      billPayer: PayerType.company,
      totalCustomerBill: 2000,
      netExpectedReceipt: 2000,
      amountReceived: 500,
      transportationExpense: 1200,
      numberOfBags: 20,
    );

    for (final o in [orderA, orderB, orderC]) {
      await ordersBox.put(o.id, o);
    }

    await paymentsBox.put(
      'pay-1',
      const PaymentReceipt(
        id: 'pay-1',
        receiptNumber: 'RCT-TEST-1',
        partyId: 'cust-x',
        payerType: PayerType.customer,
        payerName: 'Test Customer',
        amountReceived: 400,
        paymentDate: '2026-02-01',
        paymentMethod: PaymentMethod.upi,
        tdsDeducted: 0,
        otherDeduction: 0,
        referenceNumber: 'REF-1',
        notes: '',
        recordedAt: '2026-02-01T00:00:00Z',
        allocations: [
          PaymentAllocation(orderId: 'A', orderNumber: 'A', amount: 400, tdsSettled: 0),
        ],
      ),
    );

    await expensesBox.put(
      'exp-1',
      const ExpenseRecord(
        id: 'exp-1',
        expenseNumber: 'EXP-TEST-1',
        date: '2026-04-01',
        category: ExpenseCategory.fuel,
        amount: 100,
        paidTo: 'Test Pump',
        paymentMethod: PaymentMethod.cash,
        notes: '',
      ),
    );
  });

  tearDown(() async {
    await closeTestHive(tempDir);
  });

  test('metricsProvider computes every KPI correctly against fixed fixture data', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final metrics = container.read(metricsProvider);

    expect(metrics.totalRevenue, 3000); // 1000 (A) + 2000 (C), B excluded
    expect(metrics.totalExpenses, 1980); // order expenses 680 (A) + 1200 (C) + direct 100
    expect(metrics.netProfit, 1020);
    expect(metrics.profitMargin, closeTo(34.0, 0.001));
    expect(metrics.cashCollected, 400);
    expect(metrics.cashPaidOut, 100); // direct expense only
    expect(metrics.netCashFlow, 300);
    expect(metrics.customerReceivables, 600); // A: 1000 - 400
    expect(metrics.companyReceivables, 1500); // C: 2000 - 500
    expect(metrics.totalReceivables, 2100);
    expect(metrics.pendingBillsCount, 2); // A and C both have net receivable > 0
    expect(metrics.overdueBillsCount, 1); // only C is Overdue
    expect(metrics.ordersInProgressCount, 1); // only C is Booked
    expect(metrics.totalBagsTransported, 30); // 10 (A) + 20 (C), B excluded
  });

  test('allTransactionsProvider merges all 3 sources and sorts date-descending', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final transactions = container.read(allTransactionsProvider);

    // Cancelled order B must not produce a bill transaction.
    expect(transactions.any((t) => t.id == 'bill-B'), isFalse);

    // 2 order bills (A, C) + 1 payment + 1 expense = 4.
    expect(transactions.length, 4);

    // Sorted descending: exp-1 (04-01) > bill-C (03-01) > pay-1 (02-01) > bill-A (01-01).
    expect(transactions.map((t) => t.id).toList(), [
      'exp-exp-1',
      'bill-C',
      'pay-pay-1',
      'bill-A',
    ]);

    final billC = transactions.firstWhere((t) => t.id == 'bill-C');
    expect(billC.amount, 2000);
    expect(billC.paymentStatus, 'Overdue');
  });
}
