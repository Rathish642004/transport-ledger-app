import 'package:flutter/material.dart';

/// Ported from `src/components/common/StatusBadge.tsx`. `status` is passed
/// as the raw display label (e.g. `order.orderStatus.jsonValue`) rather than
/// a typed enum, since [type] alone doesn't disambiguate which of the three
/// status enums applies, matching the original's loosely-typed prop.
enum StatusBadgeType { order, payment }

enum StatusBadgeSize { sm, md }

class _BadgeSpec {
  const _BadgeSpec(this.label, this.icon, this.background, this.foreground, this.border);

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final Color border;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.type = StatusBadgeType.order,
    this.size = StatusBadgeSize.sm,
  });

  final String status;
  final StatusBadgeType type;
  final StatusBadgeSize size;

  _BadgeSpec _spec() {
    switch (type) {
      case StatusBadgeType.payment:
        switch (status) {
          case 'Paid':
            return const _BadgeSpec('Paid', Icons.check_circle, Color(0xFFECFDF5), Color(0xFF047857), Color(0xFFA7F3D0));
          case 'Partially Paid':
            return const _BadgeSpec('Part Paid', Icons.access_time, Color(0xFFFFFBEB), Color(0xFFB45309), Color(0xFFFDE68A));
          case 'Overdue':
            return const _BadgeSpec('Overdue', Icons.error_outline, Color(0xFFFFF1F2), Color(0xFFBE123C), Color(0xFFFECDD3));
          default:
            return const _BadgeSpec('Unpaid', Icons.error_outline, Color(0xFFF1F5F9), Color(0xFF334155), Color(0xFFCBD5E1));
        }
      case StatusBadgeType.order:
        switch (status) {
          case 'Draft':
            return const _BadgeSpec('Draft', Icons.edit_note, Color(0xFFF1F5F9), Color(0xFF334155), Color(0xFFE2E8F0));
          case 'Booked':
            return const _BadgeSpec('Booked', Icons.access_time, Color(0xFFF0F9FF), Color(0xFF0369A1), Color(0xFFBAE6FD));
          case 'In Transit':
            return const _BadgeSpec('In Transit', Icons.local_shipping, Color(0xFFFFFBEB), Color(0xFF92400E), Color(0xFFFCD34D));
          case 'Delivered':
            return const _BadgeSpec('Delivered', Icons.check_circle, Color(0xFFF0FDFA), Color(0xFF0F766E), Color(0xFF99F6E4));
          case 'Completed':
            return const _BadgeSpec('Completed', Icons.check_circle, Color(0xFFECFDF5), Color(0xFF065F46), Color(0xFFA7F3D0));
          case 'Cancelled':
            return const _BadgeSpec('Cancelled', Icons.cancel, Color(0xFFFFF1F2), Color(0xFFBE123C), Color(0xFFFECDD3));
          default:
            return _BadgeSpec(status, null, const Color(0xFFF1F5F9), const Color(0xFF475569), const Color(0xFFF1F5F9));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec();
    final isSmall = size == StatusBadgeSize.sm;
    final iconSize = isSmall ? 12.0 : 14.0;
    final fontSize = 11.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10, vertical: isSmall ? 2 : 4),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: spec.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spec.icon != null) ...[
            Icon(spec.icon, size: iconSize, color: spec.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            spec.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isSmall ? FontWeight.w600 : FontWeight.bold,
              color: spec.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
