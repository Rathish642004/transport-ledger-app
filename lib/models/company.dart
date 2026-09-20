/// Mirrors `src/types.ts` `Company`. Billing/outstanding totals are derived
/// from orders + payments (see `partyLedgerProvider`), not stored here.
class Company {
  const Company({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    this.email,
    required this.address,
    required this.city,
    this.gstin,
    this.pan,
    this.tdsApplicable,
    this.tdsPercentage,
  });

  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String? email;
  final String address;
  final String city;
  final String? gstin;
  final String? pan;

  /// Nullable so records persisted before TDS support was added still decode
  /// — see [hasTds]/[effectiveTdsPercentage] for the non-null accessors.
  final bool? tdsApplicable;
  final double? tdsPercentage;

  bool get hasTds => tdsApplicable == true;
  double get effectiveTdsPercentage => hasTds ? (tdsPercentage ?? 0) : 0;

  Company copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? gstin,
    String? pan,
    bool? tdsApplicable,
    double? tdsPercentage,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      tdsApplicable: tdsApplicable ?? this.tdsApplicable,
      tdsPercentage: tdsPercentage ?? this.tdsPercentage,
    );
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPerson: json['contactPerson'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String,
      city: json['city'] as String,
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      tdsApplicable: json['tdsApplicable'] as bool?,
      tdsPercentage: (json['tdsPercentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contactPerson': contactPerson,
        'phone': phone,
        if (email != null) 'email': email,
        'address': address,
        'city': city,
        if (gstin != null) 'gstin': gstin,
        if (pan != null) 'pan': pan,
        if (tdsApplicable != null) 'tdsApplicable': tdsApplicable,
        if (tdsPercentage != null) 'tdsPercentage': tdsPercentage,
      };
}
