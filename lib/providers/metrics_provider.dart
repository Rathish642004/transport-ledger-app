import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/ledger_metrics.dart';
import 'driver_payments_provider.dart';
import 'expenses_provider.dart';
import 'orders_provider.dart';
import 'payments_provider.dart';

/// Mirrors the `metrics` `useMemo` in `LedgerContext.tsx:322-399`. Riverpod
/// recomputes this automatically whenever any watched provider changes —
/// the direct analogue of the original's `[orders, expenses, payments,
/// driverPayments]` dependency array.
final metricsProvider = Provider<LedgerMetrics>((ref) {
  final orders = ref.watch(ordersProvider);
  final expenses = ref.watch(expensesProvider);
  final payments = ref.watch(paymentsProvider);
  final driverPayments = ref.watch(driverPaymentsProvider);

  final validOrders = orders.where((o) => o.orderStatus != OrderStatus.cancelled).toList();

  final totalRevenue = validOrders.fold<double>(0, (sum, o) => sum + o.charges.totalCustomerBill);

  final driverFreightTotal = validOrders.fold<double>(0, (sum, o) => sum + o.driverExpense.driverFreight);
  final orderAdditionalExpenses = validOrders.fold<double>(
    0,
    (sum, o) => sum + o.driverExpense.additionalLoadingExpense + o.driverExpense.otherTransportExpense,
  );
  final directExpensesTotal = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  final totalExpenses = driverFreightTotal + orderAdditionalExpenses + directExpensesTotal;

  final netProfit = totalRevenue - totalExpenses;
  final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

  final cashCollected = payments.fold<double>(0, (sum, p) => sum + p.amountReceived);
  final cashPaidOut = driverPayments.fold<double>(0, (sum, dp) => sum + dp.amountPaid) + directExpensesTotal;
  final netCashFlow = cashCollected - cashPaidOut;

  var customerReceivables = 0.0;
  var companyReceivables = 0.0;
  var pendingBillsCount = 0;
  var overdueBillsCount = 0;

  for (final o in validOrders) {
    final baseReceivable =
        o.billing.netExpectedReceipt != 0 ? o.billing.netExpectedReceipt : o.charges.totalCustomerBill;
    final netReceivable = baseReceivable - o.amountReceived;
    if (netReceivable > 0) {
      pendingBillsCount += 1;
      if (o.paymentStatus == PaymentStatus.overdue) {
        overdueBillsCount += 1;
      }
      if (o.billing.billPayer == PayerType.company) {
        companyReceivables += netReceivable;
      } else {
        customerReceivables += netReceivable;
      }
    }
  }

  final driverPayables = validOrders.fold<double>(0, (sum, o) {
    final outstanding = o.driverExpense.driverFreight - o.driverExpense.driverPaidAmount;
    return sum + (outstanding > 0 ? outstanding : 0);
  });

  final ordersInProgressCount = orders
      .where((o) => o.orderStatus == OrderStatus.booked || o.orderStatus == OrderStatus.inTransit)
      .length;

  final totalBagsTransported = validOrders.fold<int>(0, (sum, o) => sum + o.numberOfBags);

  return LedgerMetrics(
    totalRevenue: totalRevenue,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    profitMargin: profitMargin,
    cashCollected: cashCollected,
    cashPaidOut: cashPaidOut,
    netCashFlow: netCashFlow,
    customerReceivables: customerReceivables,
    companyReceivables: companyReceivables,
    totalReceivables: customerReceivables + companyReceivables,
    driverPayables: driverPayables,
    pendingBillsCount: pendingBillsCount,
    overdueBillsCount: overdueBillsCount,
    ordersInProgressCount: ordersInProgressCount,
    totalBagsTransported: totalBagsTransported,
  );
});
