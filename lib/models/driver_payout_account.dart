/// One of a driver's own bank accounts or UPI IDs — new concept, not in the
/// React source. Lets `PayDriverScreen` record which of the *driver's*
/// accounts a freight payment was paid into (distinct from `BankAccount`,
/// which is one of the *transporter's own* accounts money is paid from).
class DriverPayoutAccount {
  const DriverPayoutAccount({
    required this.id,
    required this.label,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
  });

  final String id;

  /// Short display label, e.g. "SBI - 1234567890" or "UPI: name@bank".
  final String label;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;

  DriverPayoutAccount copyWith({
    String? id,
    String? label,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
  }) {
    return DriverPayoutAccount(
      id: id ?? this.id,
      label: label ?? this.label,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
    );
  }

  factory DriverPayoutAccount.fromJson(Map<String, dynamic> json) {
    return DriverPayoutAccount(
      id: json['id'] as String,
      label: json['label'] as String,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      upiId: json['upiId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (bankName != null) 'bankName': bankName,
        if (accountNumber != null) 'accountNumber': accountNumber,
        if (ifscCode != null) 'ifscCode': ifscCode,
        if (upiId != null) 'upiId': upiId,
      };
}
