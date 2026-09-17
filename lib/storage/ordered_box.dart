import 'package:hive_ce/hive_ce.dart';

/// Hive's `Box` iterates in key-sorted order, not insertion order (verified:
/// `putAll({'ord-kst-162': ..., 'ord-kst-161': ...})` comes back key-sorted
/// as 159/160/161/162/163, not in the order it was written) — so a
/// collection that needs a specific display order (e.g. "newest first", as
/// `createOrder` establishes by prepending) must persist that order
/// explicitly. This pairs a data [Box] (keyed by record id) with a small
/// companion `Box<List>` holding just the ordered list of ids under
/// [orderKey].
class OrderedBoxIndex<T> {
  const OrderedBoxIndex({required this.dataBox, required this.orderBox, required this.orderKey, required this.idOf});

  final Box<T> dataBox;
  final Box<List> orderBox;
  final String orderKey;
  final String Function(T) idOf;

  /// Reconstructs the ordered list: the stored order first (dropping ids no
  /// longer present in [dataBox]), then any ids present in [dataBox] but
  /// missing from the stored order — e.g. records seeded before the order
  /// index existed, or written directly to the box some other way.
  List<T> read() {
    final storedOrder = orderBox.get(orderKey)?.cast<String>() ?? const <String>[];
    final byId = {for (final item in dataBox.values) idOf(item): item};

    final ordered = <T>[];
    for (final id in storedOrder) {
      final item = byId.remove(id);
      if (item != null) ordered.add(item);
    }
    ordered.addAll(byId.values);
    return ordered;
  }

  /// Persists both the records and their order. Callers pass the full list
  /// in the desired order (mirroring `_commit` elsewhere in the providers).
  void write(List<T> items) {
    for (final item in items) {
      dataBox.put(idOf(item), item);
    }
    orderBox.put(orderKey, items.map(idOf).toList());
  }

  /// Removes one record and drops it from the stored order.
  void delete(String id) {
    dataBox.delete(id);
    final storedOrder = orderBox.get(orderKey)?.cast<String>() ?? const <String>[];
    orderBox.put(orderKey, storedOrder.where((existing) => existing != id).toList());
  }

  /// Clears both the records and the stored order. Unlike [write]/[delete]
  /// (fire-and-forget, matching the rest of the providers), this is awaited:
  /// `Box.clear()` is genuinely async, and an un-awaited `clear()` racing
  /// the next read can leave stale records visible (verified in isolation
  /// before this was written this way).
  Future<void> clear() async {
    await dataBox.clear();
    await orderBox.delete(orderKey);
  }
}
