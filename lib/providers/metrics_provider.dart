import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/payment_allocation_engine.dart';
import '../models/enums.dart';
import '../models/ledger_metrics.dart';
import 'expenses_provider.dart';
import 'orders_provider.dart';
import 'party_ledger_provider.dart';
import 'payments_provider.dart';

/// Mirrors the `metrics` `useMemo` in `LedgerContext.tsx:322-399`. Riverpod
/// recomputes this automatically whenever any watched provider changes.
/// Receivables are read from [partyLedgerProvider] — the single place the
/// `billPayer` rule lives — rather than recomputed here, so this can never
/// disagree with what the ledger/dashboard party cards show.
final metricsProvider = Provider<LedgerMetrics>((ref) {
  final orders = ref.watch(ordersProvider);
  final expenses = ref.watch(expensesProvider);
  final payments = ref.watch(paymentsProvider);
  final ledgers = ref.watch(partyLedgerProvider);

  final validOrders = orders.where((o) => o.orderStatus != OrderStatus.cancelled).toList();

  final totalRevenue = validOrders.fold<double>(0, (sum, o) => sum + o.charges.totalCustomerBill);

  final orderExpensesTotal = validOrders.fold<double>(0, (sum, o) => sum + o.orderExpenses.total);
  final directExpensesTotal = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  final totalExpenses = orderExpensesTotal + directExpensesTotal;

  final netProfit = totalRevenue - totalExpenses;
  final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

  final cashCollected = payments.fold<double>(0, (sum, p) => sum + p.amountReceived);
  final cashPaidOut = directExpensesTotal;
  final netCashFlow = cashCollected - cashPaidOut;

  var customerReceivables = 0.0;
  var companyReceivables = 0.0;
  final companyPrefix = '${PayerType.company.jsonValue}:';
  for (final entry in ledgers.entries) {
    if (entry.key.startsWith(companyPrefix)) {
      companyReceivables += entry.value.outstanding;
    } else {
      customerReceivables += entry.value.outstanding;
    }
  }

  var pendingBillsCount = 0;
  var overdueBillsCount = 0;
  for (final o in validOrders) {
    final netReceivable = expectedReceiptFor(o) - o.amountReceived;
    if (netReceivable > 0) {
      pendingBillsCount += 1;
      if (o.paymentStatus == PaymentStatus.overdue) {
        overdueBillsCount += 1;
      }
    }
  }

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
    pendingBillsCount: pendingBillsCount,
    overdueBillsCount: overdueBillsCount,
    ordersInProgressCount: ordersInProgressCount,
    totalBagsTransported: totalBagsTransported,
  );
});
