/// Mirrors `src/types.ts` `TransporterProfile`. Stored as a single-value box entry.
class TransporterProfile {
  const TransporterProfile({
    required this.businessName,
    required this.tagline,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.gstin,
    required this.pan,
    required this.bankName,
    required this.accountNumber,
    this.accountName,
    required this.ifscCode,
    required this.branchName,
    required this.upiId,
    required this.termsAndConditions,
  });

  final String businessName;
  final String tagline;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String gstin;
  final String pan;
  final String bankName;
  final String accountNumber;
  final String? accountName;
  final String ifscCode;
  final String branchName;
  final String upiId;
  final String termsAndConditions;

  TransporterProfile copyWith({
    String? businessName,
    String? tagline,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? pan,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? ifscCode,
    String? branchName,
    String? upiId,
    String? termsAndConditions,
  }) {
    return TransporterProfile(
      businessName: businessName ?? this.businessName,
      tagline: tagline ?? this.tagline,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      ifscCode: ifscCode ?? this.ifscCode,
      branchName: branchName ?? this.branchName,
      upiId: upiId ?? this.upiId,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    );
  }

  factory TransporterProfile.fromJson(Map<String, dynamic> json) {
    return TransporterProfile(
      businessName: json['businessName'] as String,
      tagline: json['tagline'] as String,
      ownerName: json['ownerName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      gstin: json['gstin'] as String,
      pan: json['pan'] as String,
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      accountName: json['accountName'] as String?,
      ifscCode: json['ifscCode'] as String,
      branchName: json['branchName'] as String,
      upiId: json['upiId'] as String,
      termsAndConditions: json['termsAndConditions'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'tagline': tagline,
        'ownerName': ownerName,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'gstin': gstin,
        'pan': pan,
        'bankName': bankName,
        'accountNumber': accountNumber,
        if (accountName != null) 'accountName': accountName,
        'ifscCode': ifscCode,
        'branchName': branchName,
        'upiId': upiId,
        'termsAndConditions': termsAndConditions,
      };
}
