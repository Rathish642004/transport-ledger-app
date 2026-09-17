/// Mirrors `src/types.ts` `Customer`.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    this.email,
    required this.deliveryAddress,
    required this.city,
    this.gstin,
    this.pan,
    required this.totalOrders,
    required this.totalBagsReceived,
    required this.totalBilled,
    required this.totalReceived,
    required this.outstandingBalance,
  });

  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String? email;
  final String deliveryAddress;
  final String city;
  final String? gstin;
  final String? pan;
  final int totalOrders;
  final int totalBagsReceived;
  final double totalBilled;
  final double totalReceived;
  final double outstandingBalance;

  Customer copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? deliveryAddress,
    String? city,
    String? gstin,
    String? pan,
    int? totalOrders,
    int? totalBagsReceived,
    double? totalBilled,
    double? totalReceived,
    double? outstandingBalance,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      city: city ?? this.city,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      totalOrders: totalOrders ?? this.totalOrders,
      totalBagsReceived: totalBagsReceived ?? this.totalBagsReceived,
      totalBilled: totalBilled ?? this.totalBilled,
      totalReceived: totalReceived ?? this.totalReceived,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPerson: json['contactPerson'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      deliveryAddress: json['deliveryAddress'] as String,
      city: json['city'] as String,
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      totalOrders: (json['totalOrders'] as num).toInt(),
      totalBagsReceived: (json['totalBagsReceived'] as num).toInt(),
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
        'deliveryAddress': deliveryAddress,
        'city': city,
        if (gstin != null) 'gstin': gstin,
        if (pan != null) 'pan': pan,
        'totalOrders': totalOrders,
        'totalBagsReceived': totalBagsReceived,
        'totalBilled': totalBilled,
        'totalReceived': totalReceived,
        'outstandingBalance': outstandingBalance,
      };
}
