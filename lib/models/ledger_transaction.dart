/// Mirrors `src/types.ts` `LedgerTransaction`. Derived/computed only — never
/// persisted, so no Hive annotations or JSON codec (see `allTransactionsProvider`).
enum LedgerPartyType { customer, company, driver, operatingExpense }

enum LedgerEntryType { debit, credit }

/// String labels matching `LedgerTransaction['partyType'|'type']` in
/// `src/types.ts:240,243` — used by `exportLedgerCSV`.
extension LedgerPartyTypeLabel on LedgerPartyType {
  String get label => switch (this) {
        LedgerPartyType.customer => 'Customer',
        LedgerPartyType.company => 'Company',
        LedgerPartyType.driver => 'Driver',
        LedgerPartyType.operatingExpense => 'Operating Expense',
      };
}

extension LedgerEntryTypeLabel on LedgerEntryType {
  String get label => switch (this) {
        LedgerEntryType.debit => 'Debit',
        LedgerEntryType.credit => 'Credit',
      };
}

class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.date,
    required this.partyType,
    required this.partyName,
    this.orderNumber,
    required this.type,
    required this.amount,
    required this.paymentStatus,
    this.paymentMethod,
    this.referenceNumber,
    required this.notes,
  });

  final String id;
  final String date;
  final LedgerPartyType partyType;
  final String partyName;
  final String? orderNumber;
  final LedgerEntryType type;
  final double amount;
  final String paymentStatus;
  final String? paymentMethod;
  final String? referenceNumber;
  final String notes;
}
