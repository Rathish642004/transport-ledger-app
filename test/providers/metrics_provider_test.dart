import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/driver_payment_record.dart';
import 'package:flutter_app/models/enums.dart';
import 'package:flutter_app/models/expense_record.dart';
import 'package:flutter_app/models/order.dart';
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
  required double driverFreight,
  required double driverPaidAmount,
  double additionalLoadingExpense = 0,
  double otherTransportExpense = 0,
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
    driverId: 'drv-x',
    driverName: 'Test Driver',
    numberOfBags: numberOfBags,
    bagType: 'Test Bags',
    notes: '',
    orderStatus: orderStatus,
    paymentStatus: paymentStatus,
    amountReceived: amountReceived,
    charges: OrderCharges(
      loadingCharges: 0,
      transportationCharges: totalCustomerBill,
      otherCharges: 0,
      totalCustomerBill: totalCustomerBill,
    ),
    driverExpense: DriverExpense(
      driverId: 'drv-x',
      driverName: 'Test Driver',
      driverFreight: driverFreight,
      driverPaidAmount: driverPaidAmount,
      driverPaymentStatus: DriverPaymentStatus.unpaid,
      driverBillNumber: '',
      driverBillDate: orderDate,
      additionalLoadingExpense: additionalLoadingExpense,
      otherTransportExpense: otherTransportExpense,
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
      driverExpenseTotal: 0,
      otherExpenseTotal: 0,
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
      driverFreight: 600,
      driverPaidAmount: 200,
      additionalLoadingExpense: 50,
      otherTransportExpense: 30,
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
      driverFreight: 99999,
      driverPaidAmount: 0,
      numberOfBags: 999,
    );

    // Order C: Company bill, overdue, booked (in-progress), fully paid to driver.
    final orderC = _order(
      id: 'C',
      orderDate: '2026-03-01',
      orderStatus: OrderStatus.booked,
      paymentStatus: PaymentStatus.overdue,
      billPayer: PayerType.company,
      totalCustomerBill: 2000,
      netExpectedReceipt: 2000,
      amountReceived: 500,
      driverFreight: 1200,
      driverPaidAmount: 1200,
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
        orderId: 'A',
        orderNumber: 'A',
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
      ),
    );

    await driverPaymentsBox.put(
      'dp-1',
      const DriverPaymentRecord(
        id: 'dp-1',
        voucherNumber: 'DRV-TEST-1',
        driverId: 'drv-x',
        driverName: 'Test Driver',
        orderId: 'A',
        orderNumber: 'A',
        driverBillNumber: '',
        driverBillDate: '2026-02-15',
        agreedFreight: 600,
        amountPaid: 200,
        paymentDate: '2026-02-15',
        paymentMethod: PaymentMethod.cash,
        referenceNumber: '',
        notes: '',
        recordedAt: '2026-02-15T00:00:00Z',
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
    expect(metrics.totalExpenses, 1980); // driver freight 1800 + additional 80 + direct 100
    expect(metrics.netProfit, 1020);
    expect(metrics.profitMargin, closeTo(34.0, 0.001));
    expect(metrics.cashCollected, 400);
    expect(metrics.cashPaidOut, 300); // 200 driver payment + 100 expense
    expect(metrics.netCashFlow, 100);
    expect(metrics.customerReceivables, 600); // A: 1000 - 400
    expect(metrics.companyReceivables, 1500); // C: 2000 - 500
    expect(metrics.totalReceivables, 2100);
    expect(metrics.driverPayables, 400); // A: 600-200=400, C: 1200-1200=0
    expect(metrics.pendingBillsCount, 2); // A and C both have net receivable > 0
    expect(metrics.overdueBillsCount, 1); // only C is Overdue
    expect(metrics.ordersInProgressCount, 1); // only C is Booked
    expect(metrics.totalBagsTransported, 30); // 10 (A) + 20 (C), B excluded
  });

  test('allTransactionsProvider merges all 4 sources and sorts date-descending', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final transactions = container.read(allTransactionsProvider);

    // Cancelled order B must not produce a bill transaction.
    expect(transactions.any((t) => t.id == 'bill-B'), isFalse);

    // 2 order bills (A, C) + 1 payment + 1 driver payment + 1 expense = 5.
    expect(transactions.length, 5);

    // Sorted descending: exp-1 (04-01) > bill-C (03-01) > dp-1 (02-15) > pay-1 (02-01) > bill-A (01-01).
    expect(transactions.map((t) => t.id).toList(), [
      'exp-exp-1',
      'bill-C',
      'drvpay-dp-1',
      'pay-pay-1',
      'bill-A',
    ]);

    final billC = transactions.firstWhere((t) => t.id == 'bill-C');
    expect(billC.amount, 2000);
    expect(billC.paymentStatus, 'Overdue');
  });
}
