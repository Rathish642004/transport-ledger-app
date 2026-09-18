/// A transporter's own bank account, used to record which account a payment
/// was received into or paid out from. New concept — not present in the
/// React source, which only has a single set of bank fields on
/// `TransporterProfile` for invoice printing (see `SettingsScreen`'s
/// "Bank Details for Invoices & NEFT").
class BankAccount {
  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.branchName,
    this.upiId,
  });

  final String id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;
  final String? upiId;

  BankAccount copyWith({
    String? id,
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? branchName,
    String? upiId,
  }) {
    return BankAccount(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      branchName: branchName ?? this.branchName,
      upiId: upiId ?? this.upiId,
    );
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      bankName: json['bankName'] as String,
      accountHolderName: json['accountHolderName'] as String,
      accountNumber: json['accountNumber'] as String,
      ifscCode: json['ifscCode'] as String,
      branchName: json['branchName'] as String,
      upiId: json['upiId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bankName': bankName,
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'branchName': branchName,
        if (upiId != null) 'upiId': upiId,
      };
}
