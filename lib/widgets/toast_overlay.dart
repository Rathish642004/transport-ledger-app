import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/toast_provider.dart';

/// Ported from `src/components/common/ToastContainer.tsx`. Wraps [child]
/// (the shell's body) and floats the active toast list above it, bottom
/// aligned — matching the original's `fixed bottom-20` stack of dismissible
/// pills (multiple toasts can be visible at once, each auto-dismissing after
/// 3.8s via `toastProvider`).
class ToastOverlay extends ConsumerWidget {
  const ToastOverlay({super.key, required this.child});

  final Widget child;

  static const _typeStyle = {
    ToastType.success: (bg: Color(0xFF0F172A), icon: Icons.check_circle, iconColor: Color(0xFF34D399)),
    ToastType.error: (bg: Color(0xFF7F1D1D), icon: Icons.error, iconColor: Color(0xFFFCA5A5)),
    ToastType.warning: (bg: Color(0xFF78350F), icon: Icons.error, iconColor: Color(0xFFFCD34D)),
    ToastType.info: (bg: Color(0xFF0C4A6E), icon: Icons.info, iconColor: Color(0xFF7DD3FC)),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastProvider);

    return Stack(
      children: [
        child,
        if (toasts.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: IgnorePointer(
              ignoring: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final toast in toasts)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _ToastPill(toast: toast, style: _typeStyle[toast.type]!),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ToastPill extends ConsumerWidget {
  const _ToastPill({required this.toast, required this.style});

  final ToastMessage toast;
  final ({Color bg, IconData icon, Color iconColor}) style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: style.bg,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 16, color: style.iconColor),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                toast.message,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => ref.read(toastProvider.notifier).dismiss(toast.id),
              child: const Icon(Icons.close, size: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
