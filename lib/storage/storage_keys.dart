/// Hive box names, mirroring `STORAGE_KEYS` in `src/context/LedgerContext.tsx`.
///
/// One box per collection; `profile` and `backupSettings` hold a single value
/// each under [singleValueKey].
class StorageKeys {
  StorageKeys._();

  static const orders = 'tl_orders_v2';
  static const companies = 'tl_companies_v2';
  static const customers = 'tl_customers_v2';
  static const drivers = 'tl_drivers_v2';
  static const payments = 'tl_payments_v2';
  static const driverPayments = 'tl_driver_payments_v2';
  static const expenses = 'tl_expenses_v2';
  static const profile = 'tl_profile_v2';
  static const backup = 'tl_backup_v2';

  /// Companion `Box<List>` order-index for [orders]/[payments] — see
  /// `OrderedBoxIndex`. Only these two need it: Dashboard slices their raw
  /// provider list for "recent" display without sorting; every other
  /// consumer either doesn't depend on list order or (like the ledger's
  /// `allTransactionsProvider`) sorts explicitly by date anyway.
  static const ordersOrder = 'tl_orders_order_v2';
  static const paymentsOrder = 'tl_payments_order_v2';

  /// Key used inside the single-value [profile] and [backup] boxes, and
  /// inside each `*Order` box (which holds one list value).
  static const singleValueKey = 'value';

  static const all = [
    orders,
    companies,
    customers,
    drivers,
    payments,
    driverPayments,
    expenses,
    profile,
    backup,
    ordersOrder,
    paymentsOrder,
  ];
}
