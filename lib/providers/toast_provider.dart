import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mirrors the `ToastMessage`/`showToast`/`dismissToast` trio in `LedgerContext.tsx`.
enum ToastType { success, info, warning, error }

class ToastMessage {
  const ToastMessage({required this.id, required this.message, required this.type});

  final String id;
  final String message;
  final ToastType type;
}

/// Transient toast list, auto-dismissed after 3.8s — same delay as
/// `LedgerContext.tsx:265`.
class ToastNotifier extends Notifier<List<ToastMessage>> {
  @override
  List<ToastMessage> build() => [];

  void show(String message, [ToastType type = ToastType.success]) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    state = [...state, ToastMessage(id: id, message: message, type: type)];
    Future.delayed(const Duration(milliseconds: 3800), () => dismiss(id));
  }

  void dismiss(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final toastProvider = NotifierProvider<ToastNotifier, List<ToastMessage>>(ToastNotifier.new);
