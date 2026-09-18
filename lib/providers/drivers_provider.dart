import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/driver.dart';
import '../models/driver_payout_account.dart';
import '../models/order.dart';
import '../storage/hive_boxes.dart';
import 'toast_provider.dart';

/// Mirrors the driver-related logic in `LedgerContext.tsx`:
/// `createOrder`'s driver side-effect (:525-537), `payDriver`'s driver balance
/// update (:710-720), and `saveDriver` (:819-849).
class DriversNotifier extends Notifier<List<Driver>> {
  @override
  List<Driver> build() => driversBox.values.toList();

  void _commit(List<Driver> next) {
    for (final d in next) {
      driversBox.put(d.id, d);
    }
    state = next;
  }

  /// Bumps trip/freight stats when a new order is created for this driver.
  void applyOrderCreated(Order order) {
    _commit([
      for (final d in state)
        if (d.id == order.driverId || d.name == order.driverName)
          d.copyWith(
            totalTrips: d.totalTrips + 1,
            totalAgreedFreight: d.totalAgreedFreight + order.driverExpense.driverFreight,
            outstandingAmount: d.outstandingAmount + order.driverExpense.driverFreight,
          )
        else
          d,
    ]);
  }

  /// Applies a driver freight payment to the matching driver's balance.
  void applyDriverPayment({
    required String driverId,
    required String driverName,
    required double amountPaid,
  }) {
    _commit([
      for (final d in state)
        if (d.id == driverId || d.name == driverName)
          d.copyWith(
            totalAmountPaid: d.totalAmountPaid + amountPaid,
            outstandingAmount: (d.outstandingAmount - amountPaid) < 0 ? 0 : d.outstandingAmount - amountPaid,
          )
        else
          d,
    ]);
  }

  /// Add-or-edit by presence of [id], matching `saveDriver` in `LedgerContext.tsx`.
  /// The vehicle number is upper-cased only on add, matching the original.
  Driver saveDriver({
    String? id,
    required String name,
    required String phone,
    required String vehicleNumber,
    String? licenseNumber,
  }) {
    if (id != null) {
      Driver? updated;
      final next = [
        for (final d in state)
          if (d.id == id)
            (updated = d.copyWith(
              name: name,
              phone: phone,
              vehicleNumber: vehicleNumber,
              licenseNumber: licenseNumber,
            ))
          else
            d,
      ];
      _commit(next);
      ref.read(toastProvider.notifier).show('Driver "$name" updated');
      return updated!;
    }

    final newDriver = Driver(
      id: 'drv-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      vehicleNumber: vehicleNumber.toUpperCase(),
      licenseNumber: licenseNumber ?? '',
      totalTrips: 0,
      totalAgreedFreight: 0,
      totalAmountPaid: 0,
      outstandingAmount: 0,
    );
    _commit([...state, newDriver]);
    ref.read(toastProvider.notifier).show('Driver "${newDriver.name}" registered');
    return newDriver;
  }

  /// Adds one bank account or UPI ID to [driverId]'s [Driver.payoutAccounts]
  /// — new, not in the source (see `DriverPayoutAccount`'s doc comment).
  void addPayoutAccount({
    required String driverId,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
  }) {
    final label = (bankName != null && accountNumber != null) ? '$bankName - $accountNumber' : (upiId ?? 'Account');
    // A plain timestamp collides when two accounts are added back-to-back in
    // the same millisecond (verified in isolation — a real bug this caused
    // in `removePayoutAccount` before the random suffix was added).
    final account = DriverPayoutAccount(
      id: 'drvpay-acct-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000000)}',
      label: label,
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      upiId: upiId,
    );
    _commit([
      for (final d in state)
        if (d.id == driverId) d.copyWith(payoutAccounts: [...d.payoutAccounts, account]) else d,
    ]);
    ref.read(toastProvider.notifier).show('Payout account added');
  }

  void removePayoutAccount({required String driverId, required String accountId}) {
    _commit([
      for (final d in state)
        if (d.id == driverId)
          d.copyWith(payoutAccounts: d.payoutAccounts.where((a) => a.id != accountId).toList())
        else
          d,
    ]);
    ref.read(toastProvider.notifier).show('Payout account removed', ToastType.info);
  }

  /// Adds one more vehicle to [driverId]'s [Driver.additionalVehicleNumbers]
  /// — new, not in the source (see [Driver.allVehicleNumbers]'s doc comment).
  void addVehicleNumber({required String driverId, required String vehicleNumber}) {
    final normalized = vehicleNumber.trim().toUpperCase();
    if (normalized.isEmpty) return;

    final driver = state.where((d) => d.id == driverId).firstOrNull;
    if (driver == null || driver.allVehicleNumbers.contains(normalized)) {
      ref.read(toastProvider.notifier).show('That vehicle is already on file for this driver', ToastType.warning);
      return;
    }

    _commit([
      for (final d in state)
        if (d.id == driverId) d.copyWith(additionalVehicleNumbers: [...d.additionalVehicleNumbers, normalized]) else d,
    ]);
    ref.read(toastProvider.notifier).show('Vehicle added');
  }

  void removeVehicleNumber({required String driverId, required String vehicleNumber}) {
    _commit([
      for (final d in state)
        if (d.id == driverId)
          d.copyWith(additionalVehicleNumbers: d.additionalVehicleNumbers.where((v) => v != vehicleNumber).toList())
        else
          d,
    ]);
    ref.read(toastProvider.notifier).show('Vehicle removed', ToastType.info);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final driversProvider = NotifierProvider<DriversNotifier, List<Driver>>(DriversNotifier.new);
