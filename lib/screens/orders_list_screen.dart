import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../models/order.dart';
import '../providers/companies_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/orders_provider.dart';
import '../router/app_router.dart';
import '../services/orders_export.dart';
import '../utils/formatters.dart';
import '../widgets/delete_order_dialog.dart';
import '../widgets/filter_chips.dart';
import '../widgets/order_notes_dialog.dart';
import '../widgets/status_badge.dart';

/// Ported from `src/screens/OrdersListScreen.tsx`, plus three additions not
/// in the source: Company/Customer filters, a date-range filter, and
/// PDF/Excel(CSV) export of the currently-filtered list.
class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  String? _companyId;
  String? _customerId;
  DateTimeRange? _dateRange;
  bool _exporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _handleExport(String format, List<Order> filteredOrders) async {
    setState(() => _exporting = true);
    try {
      if (format == 'pdf') {
        await exportOrdersPdf(filteredOrders);
      } else {
        await exportOrdersCsv(filteredOrders);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final companies = ref.watch(companiesProvider);
    final customers = ref.watch(customersProvider);

    final filterOptions = [
      FilterOption(id: 'all', label: 'All Orders', count: orders.length),
      FilterOption(id: 'In Transit', label: 'In Transit', count: orders.where((o) => o.orderStatus == OrderStatus.inTransit).length),
      FilterOption(id: 'Delivered', label: 'Delivered', count: orders.where((o) => o.orderStatus == OrderStatus.delivered).length),
      FilterOption(id: 'Completed', label: 'Completed', count: orders.where((o) => o.orderStatus == OrderStatus.completed).length),
      FilterOption(id: 'Draft', label: 'Drafts', count: orders.where((o) => o.orderStatus == OrderStatus.draft).length),
      FilterOption(
        id: 'unpaid',
        label: 'Unpaid / Due',
        count: orders.where((o) => o.paymentStatus == PaymentStatus.unpaid || o.paymentStatus == PaymentStatus.overdue).length,
      ),
    ];

    final filteredOrders = orders.where((o) {
      if (_statusFilter == 'unpaid') {
        if (o.paymentStatus != PaymentStatus.unpaid && o.paymentStatus != PaymentStatus.overdue) return false;
      } else if (_statusFilter != 'all') {
        if (o.orderStatus.jsonValue != _statusFilter) return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = o.orderNumber.toLowerCase().contains(q) ||
            o.companyName.toLowerCase().contains(q) ||
            o.customerName.toLowerCase().contains(q) ||
            o.vehicleNumber.toLowerCase().contains(q) ||
            o.pickupLocation.toLowerCase().contains(q) ||
            o.deliveryLocation.toLowerCase().contains(q) ||
            o.bagType.toLowerCase().contains(q);
        if (!matches) return false;
      }

      if (_companyId != null && o.companyId != _companyId) return false;
      if (_customerId != null && o.customerId != _customerId) return false;

      if (_dateRange != null) {
        final orderDate = DateTime.tryParse(o.orderDate);
        if (orderDate == null) return false;
        final day = DateTime(orderDate.year, orderDate.month, orderDate.day);
        final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
        final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
        if (day.isBefore(start) || day.isAfter(end)) return false;
      }

      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search order #, company, vehicle, driver, city...',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilterChips<String>(
          options: filterOptions,
          selectedId: _statusFilter,
          onSelect: (id) => setState(() => _statusFilter = id),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _companyId,
                  isDense: true,
                  decoration: _filterDecoration(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Companies', overflow: TextOverflow.ellipsis)),
                    for (final c in companies) DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _companyId = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _customerId,
                  isDense: true,
                  decoration: _filterDecoration(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Customers', overflow: TextOverflow.ellipsis)),
                    for (final c in customers) DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _customerId = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range_outlined, size: 14),
                  label: Text(
                    _dateRange == null
                        ? 'Filter by Date'
                        : _dateRange!.start == _dateRange!.end
                            ? formatShortDate(_dateRange!.start.toIso8601String())
                            : '${formatShortDate(_dateRange!.start.toIso8601String())} – ${formatShortDate(_dateRange!.end.toIso8601String())}',
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_dateRange != null)
                IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _dateRange = null)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Showing ${filteredOrders.length} orders', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Row(
                children: [
                  _exporting
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : PopupMenuButton<String>(
                          tooltip: 'Export list',
                          icon: const Icon(Icons.ios_share, size: 18, color: Color(0xFF0369A1)),
                          onSelected: (v) => _handleExport(v, filteredOrders),
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
                            PopupMenuItem(value: 'excel', child: Text('Export as Excel (CSV)')),
                          ],
                        ),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.createOrder),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('New Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredOrders.isEmpty
              ? _EmptyState(searchQuery: _searchQuery)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filteredOrders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _OrderCard(order: filteredOrders[index]),
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 28),
            ),
            const SizedBox(height: 12),
            const Text('No Orders Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              searchQuery.isNotEmpty
                  ? 'No orders matching "$searchQuery". Try adjusting your search.'
                  : 'No orders recorded in this filter view.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.createOrder),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create Transport Order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingReceivable =
        (order.billing.netExpectedReceipt != 0 ? order.billing.netExpectedReceipt : order.charges.totalCustomerBill) -
            order.amountReceived;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(AppRoutes.orderDetailsPath(order.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
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
                          Text(order.orderNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13)),
                          const SizedBox(width: 6),
                          StatusBadge(status: order.orderStatus.jsonValue),
                        ],
                      ),
                      Text(formatDate(order.orderDate), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatINR(order.charges.totalCustomerBill), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                    StatusBadge(status: order.paymentStatus.jsonValue, type: StatusBadgeType.payment),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9)), bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(child: _PartyColumn(label: 'From Company', value: order.companyName)),
                  Expanded(child: _PartyColumn(label: 'To Customer', value: order.customerName)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: Color(0xFF0284C7)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${order.pickupLocation.split(',').first} → ${order.deliveryLocation.split(',').first}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                  child: Text('${order.numberOfBags} Bags', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                  child: Text(order.vehicleNumber, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                ),
                Text(
                  pendingReceivable > 0 ? 'Due: ${formatINR(pendingReceivable)}' : 'Paid in Full',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: pendingReceivable > 0 ? const Color(0xFFBE123C) : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _CardActionButton(
                  icon: Icons.description_outlined,
                  label: 'Bill',
                  onTap: () => context.push(AppRoutes.billPreviewPath(order.id)),
                ),
                const SizedBox(width: 6),
                _CardActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () => context.push(AppRoutes.createOrder, extra: order),
                ),
                const SizedBox(width: 6),
                _CardActionButton(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Notes',
                  background: const Color(0xFFFFFBEB),
                  foreground: const Color(0xFF78350F),
                  showDot: order.notes.isNotEmpty,
                  onTap: () => showOrderNotesDialog(context, ref, order),
                ),
                const SizedBox(width: 6),
                _CardActionButton(
                  icon: Icons.delete_outline,
                  label: '',
                  foreground: const Color(0xFFDC2626),
                  onTap: () => showDeleteOrderDialog(context, ref, order),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyColumn extends StatelessWidget {
  const _PartyColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.background = const Color(0xFFF1F5F9),
    this.foreground = const Color(0xFF334155),
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 8 : 10, vertical: 6),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: foreground)),
            ],
            if (showDot) ...[
              const SizedBox(width: 4),
              Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFB45309), shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}

InputDecoration _filterDecoration() => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    );
