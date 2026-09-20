import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/ledger_metrics.dart';
import '../models/order.dart';
import '../models/payment_receipt.dart';
import '../models/transporter_profile.dart';
import '../providers/backup_provider.dart';
import '../providers/filters_provider.dart';
import '../providers/metrics_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/profile_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';

/// Ported from `src/screens/DashboardScreen.tsx`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);
    final orders = ref.watch(ordersProvider);
    final payments = ref.watch(paymentsProvider);
    final profile = ref.watch(profileProvider);
    final backup = ref.watch(backupProvider);
    final selectedFy = ref.watch(selectedFinancialYearProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    final recentOrders = orders.take(4).toList();
    final recentPayments = payments.take(3).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileHeaderCard(
          profile: profile,
          selectedFy: selectedFy,
          selectedMonth: selectedMonth,
          onFyChanged: (fy) => ref.read(selectedFinancialYearProvider.notifier).set(fy),
          onMonthChanged: (m) => ref.read(selectedMonthProvider.notifier).set(m),
        ),
        if (metrics.overdueBillsCount > 0) ...[
          const SizedBox(height: 16),
          _OverdueBanner(count: metrics.overdueBillsCount),
        ],
        if (!backup.isConnected) ...[
          const SizedBox(height: 16),
          const _BackupReminderBanner(),
        ],
        const SizedBox(height: 16),
        _NetProfitCard(metrics: metrics, selectedFy: selectedFy, selectedMonth: selectedMonth),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Receivables',
                dotColor: const Color(0xFFF59E0B),
                value: formatINR(metrics.totalReceivables),
                subtitle: 'Companies: ${formatINR(metrics.companyReceivables)}\n'
                    'Customers: ${formatINR(metrics.customerReceivables)}',
                onTap: () => context.push(AppRoutes.ledger),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'Total Expenses',
                dotColor: const Color(0xFFE11D48),
                value: formatINR(metrics.totalExpenses),
                subtitle: 'Trip expenses across all orders',
                onTap: () => context.push(AppRoutes.reports),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _QuickActionsCard(),
        const SizedBox(height: 16),
        _InProgressStrip(metrics: metrics),
        const SizedBox(height: 16),
        _RecentOrdersCard(orders: recentOrders),
        const SizedBox(height: 16),
        _RecentPaymentsCard(payments: recentPayments),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: content);
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.profile,
    required this.selectedFy,
    required this.selectedMonth,
    required this.onFyChanged,
    required this.onMonthChanged,
  });

  final TransporterProfile profile;
  final String selectedFy;
  final String selectedMonth;
  final ValueChanged<String> onFyChanged;
  final ValueChanged<String> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FLEET TRANSPORT ACCOUNTING',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1), letterSpacing: 0.5),
                    ),
                    Text(
                      profile.businessName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.push(AppRoutes.settings),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: const Icon(Icons.business, size: 16, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _PeriodDropdown(value: selectedFy, options: financialYears, onChanged: onFyChanged)),
              const SizedBox(width: 8),
              Expanded(child: _PeriodDropdown(value: selectedMonth, options: monthNames, onChanged: onMonthChanged)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({required this.value, required this.options, required this.onChanged});

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('${AppRoutes.reports}?tab=notifications'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFBE123C)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count Overdue Customer Bill${count > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF881337)),
                  ),
                  const Text(
                    'Tap to view receivables & send payment reminders',
                    style: TextStyle(fontSize: 11, color: Color(0xFFBE123C)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFFDA4AF)),
          ],
        ),
      ),
    );
  }
}

/// Nudges users who haven't connected Google Drive backup — all ledger data
/// otherwise lives only in this app's local storage and is permanently lost
/// on uninstall. Deliberately shown on every dashboard visit until connected
/// (no dismiss/snooze), same as [_OverdueBanner], since silent data loss is
/// a worse outcome than a persistent reminder.
class _BackupReminderBanner extends StatelessWidget {
  const _BackupReminderBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(AppRoutes.settings),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cloud_off_outlined, size: 16, color: Color(0xFFB45309)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your data isn\'t backed up',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                  Text(
                    'Orders & payments are stored only on this device. Connect Google Drive so uninstalling doesn\'t erase them.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFFCD34D)),
          ],
        ),
      ),
    );
  }
}

class _NetProfitCard extends StatelessWidget {
  const _NetProfitCard({required this.metrics, required this.selectedFy, required this.selectedMonth});

  final LedgerMetrics metrics;
  final String selectedFy;
  final String selectedMonth;

  static const _trend = [
    (m: 'Apr', h: 45.0),
    (m: 'May', h: 60.0),
    (m: 'Jun', h: 50.0),
    (m: 'Jul', h: 75.0),
    (m: 'Aug', h: 70.0),
    (m: 'Sep', h: 90.0),
  ];

  @override
  Widget build(BuildContext context) {
    final periodLabel = selectedMonth == 'All Months' ? selectedFy : selectedMonth;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF082F49)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Business Net Profit ($periodLabel)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x330EA5E9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x4D38BDF8)),
                ),
                child: Text(
                  '${metrics.profitMargin.toStringAsFixed(1)}% Margin',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatINR(metrics.netProfit),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const Text(
            'Earned Revenue minus Driver Freight & Transport Expenses',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1E293B)))),
            child: Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF34D399),
                    label: 'Total Revenue',
                    value: formatINR(metrics.totalRevenue),
                    footer: '${metrics.totalBagsTransported} Bags Moved',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBlock(
                    icon: Icons.trending_down,
                    iconColor: const Color(0xFFFCA5A5),
                    label: 'Total Expenses',
                    value: formatINR(metrics.totalExpenses),
                    footer: 'Drivers, Diesel, Labour',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text('Profit Trend (Last 6 Months)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              const Text('Growing Steady', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _trend.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 32 * (_trend[i].h / 100),
                          decoration: BoxDecoration(
                            color: i == _trend.length - 1 ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _trend[i].m,
                          style: TextStyle(
                            fontSize: 9,
                            color: i == _trend.length - 1 ? const Color(0xFF7DD3FC) : const Color(0xFF94A3B8),
                            fontWeight: i == _trend.length - 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.icon, required this.iconColor, required this.label, required this.value, required this.footer});

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x99334155).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: iconColor), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(footer, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.dotColor,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Card(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155), letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_circle,
                  bg: const Color(0xFFF0F9FF),
                  fg: const Color(0xFF0369A1),
                  iconBg: const Color(0xFF0284C7),
                  label: 'Create Order',
                  onTap: () => context.push(AppRoutes.createOrder),
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.credit_card,
                  bg: const Color(0xFFECFDF5),
                  fg: const Color(0xFF047857),
                  iconBg: const Color(0xFF059669),
                  label: 'Receive Payment',
                  onTap: () => context.push(AppRoutes.receivePayment),
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.receipt_long,
                  bg: const Color(0xFFFFFBEB),
                  fg: const Color(0xFF92400E),
                  iconBg: const Color(0xFFD97706),
                  label: 'Add Expense',
                  onTap: () => context.push(AppRoutes.expense),
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.table_chart,
                  bg: const Color(0xFFEEF2FF),
                  fg: const Color(0xFF3730A3),
                  iconBg: const Color(0xFF4F46E5),
                  label: 'Reports',
                  onTap: () => context.push(AppRoutes.reports),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _InProgressStrip extends StatelessWidget {
  const _InProgressStrip({required this.metrics});

  final LedgerMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.access_time, size: 18, color: Color(0xFF0369A1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metrics.ordersInProgressCount} Active Trips On Road',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  '${metrics.pendingBillsCount} Pending Customer Bills',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: const Color(0xFFF0F9FF)),
            onPressed: () => context.push(AppRoutes.orders),
            child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 16, color: Color(0xFF0369A1)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'RECENT TRANSPORT ORDERS',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.orders),
                  child: const Text('See All', style: TextStyle(fontSize: 12, color: Color(0xFF0369A1))),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          for (final order in orders)
            InkWell(
              onTap: () => context.push(AppRoutes.orderDetailsPath(order.id)),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      order.orderNumber,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  StatusBadge(status: order.orderStatus.jsonValue),
                                ],
                              ),
                              Text(
                                order.companyName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatINR(order.charges.totalCustomerBill),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            StatusBadge(
                              status: order.paymentStatus.jsonValue,
                              type: StatusBadgeType.payment,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${order.numberOfBags} Bags • '
                            '${(order.pickupLocation).split(',').first} → '
                            '${(order.deliveryLocation).split(',').first}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          order.vehicleNumber,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentPaymentsCard extends StatelessWidget {
  const _RecentPaymentsCard({required this.payments});

  final List<PaymentReceipt> payments;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 16, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'RECENT CASH COLLECTIONS',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.ledger),
                  child: const Text('Ledger', style: TextStyle(fontSize: 12, color: Color(0xFF0369A1))),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          for (final p in payments)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.payerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(
                          '${formatDate(p.paymentDate)} via ${p.paymentMethod.jsonValue}'
                          '${(p.tdsDeducted) > 0 ? ' (TDS: ₹${(p.tdsDeducted).round()})' : ''}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${formatINR(p.amountReceived)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                      ),
                      Text(
                        p.receiptNumber,
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
