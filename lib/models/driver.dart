/// Mirrors `src/types.ts` `Driver`.
class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    this.licenseNumber,
    required this.totalTrips,
    required this.totalAgreedFreight,
    required this.totalAmountPaid,
    required this.outstandingAmount,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicleNumber;
  final String? licenseNumber;
  final int totalTrips;
  final double totalAgreedFreight;
  final double totalAmountPaid;
  final double outstandingAmount;

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? vehicleNumber,
    String? licenseNumber,
    int? totalTrips,
    double? totalAgreedFreight,
    double? totalAmountPaid,
    double? outstandingAmount,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      totalTrips: totalTrips ?? this.totalTrips,
      totalAgreedFreight: totalAgreedFreight ?? this.totalAgreedFreight,
      totalAmountPaid: totalAmountPaid ?? this.totalAmountPaid,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
    );
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      licenseNumber: json['licenseNumber'] as String?,
      totalTrips: (json['totalTrips'] as num).toInt(),
      totalAgreedFreight: (json['totalAgreedFreight'] as num).toDouble(),
      totalAmountPaid: (json['totalAmountPaid'] as num).toDouble(),
      outstandingAmount: (json['outstandingAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'vehicleNumber': vehicleNumber,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
        'totalTrips': totalTrips,
        'totalAgreedFreight': totalAgreedFreight,
        'totalAmountPaid': totalAmountPaid,
        'outstandingAmount': outstandingAmount,
      };
}
