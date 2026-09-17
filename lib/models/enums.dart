/// Enums mirroring the string unions in the React prototype's `src/types.ts`.
///
/// Each enum carries its exact original JSON string (some contain spaces or
/// slashes, so `.name` can't be used directly) via [jsonValue]/`fromJson`, so
/// the local JSON backup format stays byte-for-byte compatible with the React
/// app's `exportBackupJSON` output.
library;

enum OrderStatus {
  draft('Draft'),
  booked('Booked'),
  inTransit('In Transit'),
  delivered('Delivered'),
  completed('Completed'),
  cancelled('Cancelled');

  const OrderStatus(this.jsonValue);

  final String jsonValue;

  static OrderStatus fromJson(String value) =>
      values.firstWhere((e) => e.jsonValue == value);

  String toJson() => jsonValue;
}

enum PaymentStatus {
  unpaid('Unpaid'),
  partiallyPaid('Partially Paid'),
  paid('Paid'),
  overdue('Overdue');

  const PaymentStatus(this.jsonValue);

  final String jsonValue;

  static PaymentStatus fromJson(String value) =>
      values.firstWhere((e) => e.jsonValue == value);

  String toJson() => jsonValue;
}

enum DriverPaymentStatus {
  unpaid('Unpaid'),
  advancePaid('Advance Paid'),
  partiallyPaid('Partially Paid'),
  paidInFull('Paid in Full');

  const DriverPaymentStatus(this.jsonValue);

  final String jsonValue;

  static DriverPaymentStatus fromJson(String value) =>
      values.firstWhere((e) => e.jsonValue == value);

  String toJson() => jsonValue;
}

enum PaymentMethod {
  cash('Cash'),
  upi('UPI'),
  bankTransfer('Bank Transfer'),
  cheque('Cheque');

  const PaymentMethod(this.jsonValue);

  final String jsonValue;

  static PaymentMethod fromJson(String value) =>
      values.firstWhere((e) => e.jsonValue == value);

  String toJson() => jsonValue;
}

enum PayerType {
  customer('Customer'),
  company('Company');

  const PayerType(this.jsonValue);

  final String jsonValue;

  static PayerType fromJson(String value) =>
      values.firstWhere((e) => e.jsonValue == value);

  String toJson() => jsonValue;
}

enum ExpenseCategory {
  fuel('Fuel'),
  tollTax('Toll / Tax'),
  loadingLabour('Loading Labour'),
  unloadingLabour('Unloading Labour'),
  rtoPolice('RTO / Police'),
  vehicleMaintenance('Vehicle Maintenance'),
  weighbridgeKaanta('Weighbridge / Kaanta'),
  officeTea('Office / Tea'),
  otherTransport('Other Transport');

  const ExpenseCategory(this.jsonValue);

  final String jsonValue;

  static ExpenseCategory fromJson(String value) =>
      values.firstWhere((e) => e.jsonValue == value);

  String toJson() => jsonValue;
}

enum BackupFrequency {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly');

  const BackupFrequency(this.jsonValue);

  final String jsonValue;

  static BackupFrequency fromJson(String value) =>
      values.firstWhere((e) => e.jsonValue == value);

  String toJson() => jsonValue;
}

enum SyncStatus {
  synced('Synced'),
  pending('Pending'),
  never('Never'),
  syncing('Syncing');

  const SyncStatus(this.jsonValue);

  final String jsonValue;

  static SyncStatus fromJson(String value) =>
      values.firstWhere((e) => e.jsonValue == value);

  String toJson() => jsonValue;
}
