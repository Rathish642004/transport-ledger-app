import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../storage/hive_boxes.dart';
import 'toast_provider.dart';

/// Mirrors `saveCustomer` in `LedgerContext.tsx:781-816`. Billing/outstanding
/// totals are no longer stored here — they're derived from orders + payments
/// by `partyLedgerProvider`, which is the single place the `billPayer` rule
/// (which party an order's receivable belongs to) lives.
class CustomersNotifier extends Notifier<List<Customer>> {
  @override
  List<Customer> build() => customersBox.values.toList();

  void _commit(List<Customer> next) {
    for (final c in next) {
      customersBox.put(c.id, c);
    }
    state = next;
  }

  /// Add-or-edit by presence of [id], matching `saveCustomer` in `LedgerContext.tsx`.
  Customer saveCustomer({
    String? id,
    required String name,
    required String contactPerson,
    required String phone,
    String? email,
    required String deliveryAddress,
    required String city,
    String? gstin,
    String? pan,
    bool tdsApplicable = false,
    double tdsPercentage = 0,
  }) {
    if (id != null) {
      Customer? updated;
      final next = [
        for (final c in state)
          if (c.id == id)
            (updated = c.copyWith(
              name: name,
              contactPerson: contactPerson,
              phone: phone,
              email: email,
              deliveryAddress: deliveryAddress,
              city: city,
              gstin: gstin,
              pan: pan,
              tdsApplicable: tdsApplicable,
              tdsPercentage: tdsPercentage,
            ))
          else
            c,
      ];
      _commit(next);
      ref.read(toastProvider.notifier).show('Customer "$name" updated');
      return updated!;
    }

    final newCustomer = Customer(
      id: 'cust-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email ?? '',
      deliveryAddress: deliveryAddress,
      city: city,
      gstin: gstin ?? '',
      pan: pan ?? '',
      tdsApplicable: tdsApplicable,
      tdsPercentage: tdsPercentage,
    );
    _commit([...state, newCustomer]);
    ref.read(toastProvider.notifier).show('Customer "${newCustomer.name}" added');
    return newCustomer;
  }
}

final customersProvider = NotifierProvider<CustomersNotifier, List<Customer>>(CustomersNotifier.new);
