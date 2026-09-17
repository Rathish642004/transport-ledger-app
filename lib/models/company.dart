/// Mirrors `src/types.ts` `Company`.
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
    required this.totalOrders,
    required this.totalBagsDispatched,
    required this.totalBilled,
    required this.totalReceived,
    required this.outstandingBalance,
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
  final int totalOrders;
  final int totalBagsDispatched;
  final double totalBilled;
  final double totalReceived;
  final double outstandingBalance;

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
    int? totalOrders,
    int? totalBagsDispatched,
    double? totalBilled,
    double? totalReceived,
    double? outstandingBalance,
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
      totalOrders: totalOrders ?? this.totalOrders,
      totalBagsDispatched: totalBagsDispatched ?? this.totalBagsDispatched,
      totalBilled: totalBilled ?? this.totalBilled,
      totalReceived: totalReceived ?? this.totalReceived,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
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
      totalOrders: (json['totalOrders'] as num).toInt(),
      totalBagsDispatched: (json['totalBagsDispatched'] as num).toInt(),
      totalBilled: (json['totalBilled'] as num).toDouble(),
      totalReceived: (json['totalReceived'] as num).toDouble(),
      outstandingBalance: (json['outstandingBalance'] as num).toDouble(),
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
        'totalOrders': totalOrders,
        'totalBagsDispatched': totalBagsDispatched,
        'totalBilled': totalBilled,
        'totalReceived': totalReceived,
        'outstandingBalance': outstandingBalance,
      };
}
