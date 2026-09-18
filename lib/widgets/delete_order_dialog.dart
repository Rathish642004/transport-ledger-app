import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../providers/driver_payments_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/payments_provider.dart';
import '../utils/formatters.dart';

/// Ported from `src/components/orders/DeleteOrderModal.tsx`. Deletes the
/// order and returns `true` if confirmed; the caller decides what "deleted"
/// means for navigation (matching the original's optional `onDeleted`
/// callback / `navigateTo({type:'orders'})` fallback).
Future<bool> showDeleteOrderDialog(BuildContext context, WidgetRef ref, Order order) async {
  final displayName = (order.lrNumber?.isNotEmpty ?? false) ? order.lrNumber! : order.orderNumber;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFBE123C), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete Transport Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF4C0519))),
                        Text('Permanent removal from ledger', style: TextStyle(fontSize: 11, color: Color(0xFFBE123C))),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFFFB7185)),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                      children: [
                        const TextSpan(text: 'Are you sure you want to delete transport booking '),
                        TextSpan(
                          text: '#$displayName',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontFamily: 'monospace'),
                        ),
                        const TextSpan(text: '?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow('Consignor (From):', order.companyName),
                        _SummaryRow('Consignee (To):', order.customerName),
                        _SummaryRow('Vehicle & Cargo:', '${order.vehicleNumber} (${order.numberOfBags} Bags)'),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _SummaryRow('Total Bill:', formatINR(order.charges.totalCustomerBill), bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Text(
                      'This will remove the official invoice, driver freight entries, and associated ledger records for this trip.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Yes, Delete Order'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  if (confirmed == true) {
    // The dialog's own copy above already promises this ("...driver freight
    // entries, and associated ledger records for this trip") — actually
    // doing it: an order's payment receipts and driver payment vouchers
    // would otherwise survive as orphans, still counted in the payer's/
    // driver's outstanding balance for an order that no longer exists.
    for (final p in ref.read(paymentsProvider).where((p) => p.orderId == order.id).toList()) {
      ref.read(paymentsProvider.notifier).removePayment(p.id);
    }
    for (final dp in ref.read(driverPaymentsProvider).where((dp) => dp.orderId == order.id).toList()) {
      ref.read(driverPaymentsProvider.notifier).removeDriverPayment(dp.id);
    }
    ref.read(ordersProvider.notifier).deleteOrder(order.id);
    return true;
  }
  return false;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: bold ? 13 : 11, color: const Color(0xFF1E293B), fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
