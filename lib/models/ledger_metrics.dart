/// Mirrors the `metrics` object computed in `LedgerContext.tsx:322-399`.
/// Derived/computed only — never persisted.
class LedgerMetrics {
  const LedgerMetrics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.cashCollected,
    required this.cashPaidOut,
    required this.netCashFlow,
    required this.customerReceivables,
    required this.companyReceivables,
    required this.totalReceivables,
    required this.driverPayables,
    required this.pendingBillsCount,
    required this.overdueBillsCount,
    required this.ordersInProgressCount,
    required this.totalBagsTransported,
  });

  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double profitMargin;
  final double cashCollected;
  final double cashPaidOut;
  final double netCashFlow;
  final double customerReceivables;
  final double companyReceivables;
  final double totalReceivables;
  final double driverPayables;
  final int pendingBillsCount;
  final int overdueBillsCount;
  final int ordersInProgressCount;
  final int totalBagsTransported;
}
