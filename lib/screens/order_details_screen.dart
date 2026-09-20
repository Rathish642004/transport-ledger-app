import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../models/enums.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';
import '../widgets/delete_order_dialog.dart';
import '../widgets/order_notes_dialog.dart';
import '../widgets/status_badge.dart';

/// Ported from `src/screens/OrderDetailsScreen.tsx`. The confetti burst on
/// marking an order Delivered/Completed is a cosmetic-only flourish from the
/// source (`canvas-confetti`) with no functional effect — intentionally
/// skipped rather than pulling in a new dependency outside the pinned set.
class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _statusDropdownOpen = false;
  final _quickNoteController = TextEditingController();

  @override
  void dispose() {
    _quickNoteController.dispose();
    super.dispose();
  }

  void _handleStatusChange(Order order, OrderStatus status) {
    ref.read(ordersProvider.notifier).updateOrderStatus(order.id, status);
    setState(() => _statusDropdownOpen = false);
  }

  void _handleQuickAddNote(Order order) {
    final text = _quickNoteController.text.trim();
    if (text.isEmpty) return;
    ref.read(ordersProvider.notifier).addOrderNote(order.id, text);
    _quickNoteController.clear();
    setState(() {});
  }

  void _handleShare(Order order) {
    final shareText = 'Transport Order #${order.orderNumber} - ${order.numberOfBags} Bags\n'
        'Route: ${order.pickupLocation} to ${order.deliveryLocation}\n'
        'Vehicle: ${order.vehicleNumber}\n'
        'Gross Bill: ${formatINR(order.charges.totalCustomerBill)}';
    SharePlus.instance.share(ShareParams(text: shareText, subject: 'Transport Order ${order.orderNumber}'));
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    Order? order;
    for (final o in orders) {
      if (o.id == widget.orderId) {
        order = o;
        break;
      }
    }

    if (order == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Order not found', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go(AppRoutes.orders), child: const Text('Back to Orders')),
          ],
        ),
      );
    }

    final notesCount = order.notes.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).length;
    final pendingCustomerReceivable =
        (order.billing.netExpectedReceipt != 0 ? order.billing.netExpectedReceipt : order.charges.totalCustomerBill) -
            order.amountReceived;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Edit Order',
              onPressed: () => context.push(AppRoutes.createOrder, extra: order),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Notes',
              onPressed: () => showOrderNotesDialog(context, ref, order!),
              icon: Badge(
                isLabelVisible: notesCount > 0,
                label: Text('$notesCount'),
                child: const Icon(Icons.sticky_note_2_outlined),
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () async {
                final deleted = await showDeleteOrderDialog(context, ref, order!);
                if (deleted && context.mounted) context.go(AppRoutes.orders);
              },
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HeaderCard(
          order: order,
          statusDropdownOpen: _statusDropdownOpen,
          onToggleDropdown: () => setState(() => _statusDropdownOpen = !_statusDropdownOpen),
          onStatusChange: (s) => _handleStatusChange(order!, s),
        ),
        const SizedBox(height: 12),
        _PrimaryActionsGrid(order: order, onShare: () => _handleShare(order!)),
        const SizedBox(height: 12),
        _NotesCard(
          order: order,
          controller: _quickNoteController,
          onAdd: () => _handleQuickAddNote(order!),
          onManage: () => showOrderNotesDialog(context, ref, order!),
        ),
        const SizedBox(height: 12),
        _RoutePartiesCard(order: order),
        const SizedBox(height: 12),
        _ChargeBreakdownCard(order: order, pendingCustomerReceivable: pendingCustomerReceivable),
        const SizedBox(height: 12),
        _ProfitSummaryCard(order: order),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.createOrder, extra: order),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit Order'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('${AppRoutes.expense}?orderId=${order!.id}'),
                icon: const Icon(Icons.add_circle_outline, size: 14),
                label: const Text('Add Expense'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.billPreviewPath(order!.id)),
                icon: const Icon(Icons.description_outlined, size: 14),
                label: const Text('Print LR Bill'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DangerZoneCard(order: order),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: child,
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order, required this.statusDropdownOpen, required this.onToggleDropdown, required this.onStatusChange});

  final Order order;
  final bool statusDropdownOpen;
  final VoidCallback onToggleDropdown;
  final ValueChanged<OrderStatus> onStatusChange;

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
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(order.orderNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 15)),
                        StatusBadge(status: order.orderStatus.jsonValue, size: StatusBadgeSize.md),
                      ],
                    ),
                    Text('Booked on ${formatDate(order.orderDate)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(status: order.paymentStatus.jsonValue, type: StatusBadgeType.payment, size: StatusBadgeSize.md),
                  const SizedBox(height: 4),
                  Text('Recv: ${formatINR(order.amountReceived)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onToggleDropdown,
                icon: const Icon(Icons.access_time, size: 14),
                label: Text('Change Status: ${order.orderStatus.jsonValue}', style: const TextStyle(fontSize: 11)),
              ),
              if (order.orderStatus != OrderStatus.delivered && order.orderStatus != OrderStatus.completed)
                TextButton(
                  onPressed: () => onStatusChange(OrderStatus.delivered),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFF0FDFA), foregroundColor: const Color(0xFF0F766E)),
                  child: const Text('Mark Delivered', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              if (order.orderStatus != OrderStatus.completed)
                TextButton(
                  onPressed: () => onStatusChange(OrderStatus.completed),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFECFDF5), foregroundColor: const Color(0xFF047857)),
                  child: const Text('Mark Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (statusDropdownOpen) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final st in OrderStatus.values)
                  ChoiceChip(
                    label: Text(st.jsonValue, style: const TextStyle(fontSize: 11)),
                    selected: order.orderStatus == st,
                    onSelected: (_) => onStatusChange(st),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryActionsGrid extends StatelessWidget {
  const _PrimaryActionsGrid({required this.order, required this.onShare});

  final Order order;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final notesCount = order.notes.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).length;
    final items = <(IconData, Color, String, VoidCallback, int?)>[
      (Icons.edit_outlined, const Color(0xFF0369A1), 'Edit Order', () => context.push(AppRoutes.createOrder, extra: order), null),
      (Icons.sticky_note_2_outlined, const Color(0xFFD97706), 'Trip Notes', () {}, notesCount > 0 ? notesCount : null),
      (Icons.print_outlined, const Color(0xFF475569), 'Print Bill', () => context.push(AppRoutes.billPreviewPath(order.id)), null),
      (
        Icons.credit_card,
        const Color(0xFF059669),
        'Receive Pay',
        () => context.push(
              '${AppRoutes.receivePayment}?partyType=${order.billing.billPayer.toJson()}'
              '&partyId=${order.billing.billPayer == PayerType.company ? order.companyId : order.customerId}',
            ),
        null,
      ),
      (Icons.share_outlined, const Color(0xFF4F46E5), 'Share Bill', onShare, null),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.3,
      children: [
        for (final (icon, color, label, onTap, badge) in items)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(height: 4),
                      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ],
                  ),
                  if (badge != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle),
                        child: Text('$badge', style: const TextStyle(fontSize: 9, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.order, required this.controller, required this.onAdd, required this.onManage});

  final Order order;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final noteLines = order.notes.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ORDER NOTES & TRIP UPDATES (${noteLines.length})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              TextButton(onPressed: onManage, child: Text(order.notes.isNotEmpty ? 'Manage Notes' : '+ Add Note', style: const TextStyle(fontSize: 11))),
            ],
          ),
          const SizedBox(height: 8),
          if (noteLines.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Text(
                'No notes or instructions attached to this order yet.',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: noteLines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final line = noteLines[i];
                  final closeBracket = line.indexOf(']');
                  final isTimestamped = line.startsWith('[') && closeBracket != -1;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: isTimestamped
                        ? Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: line.substring(0, closeBracket + 1),
                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                              ),
                              TextSpan(text: ' ${line.substring(closeBracket + 1)}'),
                            ]),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                          )
                        : Text(line, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onAdd(),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Add a quick note or trip update...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 14), label: const Text('Add')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutePartiesCard extends StatelessWidget {
  const _RoutePartiesCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ROUTE & PARTY DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 10),
          _RouteRow(icon: Icons.place, color: const Color(0xFF0284C7), label: 'PICKUP LOCATION (COMPANY)', name: order.companyName, address: order.pickupLocation),
          const SizedBox(height: 8),
          _RouteRow(icon: Icons.place, color: const Color(0xFF059669), label: 'DELIVERY DESTINATION (CUSTOMER)', name: order.customerName, address: order.deliveryLocation),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: _InfoTile(label: 'VEHICLE NUMBER', value: order.vehicleNumber, mono: true),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(label: 'BAG QUANTITY', value: '${order.numberOfBags} Bags', subtitle: order.bagType),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.icon, required this.color, required this.label, required this.name, required this.address});

  final IconData icon;
  final Color color;
  final String label;
  final String name;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(address, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, this.subtitle, this.mono = false});

  final String label;
  final String value;
  final String? subtitle;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, fontFamily: mono ? 'monospace' : null)),
          if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ChargeBreakdownCard extends StatelessWidget {
  const _ChargeBreakdownCard({required this.order, required this.pendingCustomerReceivable});

  final Order order;
  final double pendingCustomerReceivable;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CUSTOMER CHARGE BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text('Billed to ${order.billing.billPayer.jsonValue}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
            ],
          ),
          const SizedBox(height: 8),
          _LineRow('${order.numberOfBags} Bags × ₹${(order.ratePerBag ?? 0).round()}/bag', formatINR(order.charges.totalCustomerBill)),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _LineRow('Gross Bill Amount', formatINR(order.charges.totalCustomerBill), bold: true),
          if (order.billing.tdsApplicable)
            _LineRow('Less: TDS Deducted (${order.billing.tdsPercentage}%)', '-${formatINR(order.billing.tdsAmount)}', color: const Color(0xFFB45309)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Amount Receivable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0C4A6E))),
                Text(formatINR(order.billing.netExpectedReceipt), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF075985))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: pendingCustomerReceivable > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pendingCustomerReceivable > 0 ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pendingCustomerReceivable > 0 ? 'Balance Receivable:' : 'Full Bill Amount Received',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pendingCustomerReceivable > 0 ? const Color(0xFF92400E) : const Color(0xFF065F46)),
                ),
                if (pendingCustomerReceivable > 0)
                  Text(formatINR(pendingCustomerReceivable), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E)))
                else
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow(this.label, this.value, {this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color ?? const Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: bold ? 13 : 11, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: color ?? const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _ProfitSummaryCard extends StatelessWidget {
  const _ProfitSummaryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final expenses = order.orderExpenses;
    final profit = order.financialSummary.estimatedProfit;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRIP PROFIT CALCULATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1))),
          const SizedBox(height: 8),
          _DarkLineRow('Order Total', formatINR(order.charges.totalCustomerBill)),
          _DarkLineRow('Transportation (incl. driver payment)', '-${formatINR(expenses.transportationCharges)}', color: const Color(0xFFFCA5A5)),
          if (expenses.loadingCharges > 0) _DarkLineRow('Loading Expense', '-${formatINR(expenses.loadingCharges)}', color: const Color(0xFFFCA5A5)),
          if (expenses.otherCharges > 0) _DarkLineRow('Other Expense', '-${formatINR(expenses.otherCharges)}', color: const Color(0xFFFCA5A5)),
          const Divider(height: 16, color: Color(0xFF1E293B)),
          _DarkLineRow(
            profit >= 0 ? 'Net Trip Profit' : 'Net Trip Loss',
            formatINR(profit),
            bold: true,
            color: profit >= 0 ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
          ),
        ],
      ),
    );
  }
}

class _DarkLineRow extends StatelessWidget {
  const _DarkLineRow(this.label, this.value, {this.bold = false, this.color = Colors.white});

  final String label;
  final String value;
  final bool bold;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 13 : 11, color: bold ? color : const Color(0xFFCBD5E1), fontWeight: bold ? FontWeight.w900 : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: bold ? 14 : 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _DangerZoneCard extends ConsumerWidget {
  const _DangerZoneCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFE4E6))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delete Transport Booking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4C0519))),
                const Text(
                  'Permanently delete this order, its bill copy, and financial transactions.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFBE123C)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              final deleted = await showDeleteOrderDialog(context, ref, order);
              if (deleted && context.mounted) context.go(AppRoutes.orders);
            },
            icon: const Icon(Icons.delete, size: 14),
            label: const Text('Delete Order'),
          ),
        ],
      ),
    );
  }
}
