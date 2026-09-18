import 'driver_payout_account.dart';

/// Mirrors `src/types.ts` `Driver`, plus [payoutAccounts] — new, not in the
/// React source (see `DriverPayoutAccount`'s doc comment).
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
    this.payoutAccounts = const [],
    this.additionalVehicleNumbers = const [],
  });

  final String id;
  final String name;
  final String phone;

  /// The driver's first/primary vehicle — kept as its own required field
  /// (rather than folded into [additionalVehicleNumbers]) so existing
  /// on-device data and every read site that predates multi-vehicle support
  /// keeps working untouched. See [allVehicleNumbers] for the full list.
  final String vehicleNumber;
  final String? licenseNumber;
  final int totalTrips;
  final double totalAgreedFreight;
  final double totalAmountPaid;
  final double outstandingAmount;
  final List<DriverPayoutAccount> payoutAccounts;

  /// Any vehicles beyond [vehicleNumber] — new, not in the React source (see
  /// [DriverPayoutAccount]'s doc comment for the same additive-field shape).
  final List<String> additionalVehicleNumbers;

  /// [vehicleNumber] plus [additionalVehicleNumbers], deduplicated — what
  /// `CreateOrderScreen`'s vehicle picker actually offers.
  List<String> get allVehicleNumbers => [vehicleNumber, ...additionalVehicleNumbers].where((v) => v.isNotEmpty).toSet().toList();

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
    List<DriverPayoutAccount>? payoutAccounts,
    List<String>? additionalVehicleNumbers,
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
      payoutAccounts: payoutAccounts ?? this.payoutAccounts,
      additionalVehicleNumbers: additionalVehicleNumbers ?? this.additionalVehicleNumbers,
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
      payoutAccounts: (json['payoutAccounts'] as List<dynamic>?)
              ?.map((e) => DriverPayoutAccount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      additionalVehicleNumbers: (json['additionalVehicleNumbers'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
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
        'payoutAccounts': payoutAccounts.map((a) => a.toJson()).toList(),
        'additionalVehicleNumbers': additionalVehicleNumbers,
      };
}
