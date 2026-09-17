import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../storage/hive_boxes.dart';
import 'toast_provider.dart';

/// Mirrors the customer-related logic in `LedgerContext.tsx`:
/// `createOrder`'s customer side-effect (:506-522), `receivePayment`'s
/// customer balance update (:647-659), and `saveCustomer` (:781-816).
class CustomersNotifier extends Notifier<List<Customer>> {
  @override
  List<Customer> build() => customersBox.values.toList();

  void _commit(List<Customer> next) {
    for (final c in next) {
      customersBox.put(c.id, c);
    }
    state = next;
  }

  /// Bumps trip/billing stats when a new order is created against this customer.
  void applyOrderCreated(Order order) {
    final isBillCustomer = order.billing.billPayer == PayerType.customer;
    _commit([
      for (final c in state)
        if (c.id == order.customerId || c.name == order.customerName)
          c.copyWith(
            totalOrders: c.totalOrders + 1,
            totalBagsReceived: c.totalBagsReceived + order.numberOfBags,
            totalBilled: isBillCustomer ? c.totalBilled + order.charges.totalCustomerBill : null,
            outstandingBalance:
                isBillCustomer ? c.outstandingBalance + order.billing.netExpectedReceipt : null,
          )
        else
          c,
    ]);
  }

  /// Applies a received payment to the matching customer's balance.
  void applyPaymentReceived(String payerName, double amountReceived) {
    _commit([
      for (final c in state)
        if (c.name == payerName)
          c.copyWith(
            totalReceived: c.totalReceived + amountReceived,
            outstandingBalance:
                (c.outstandingBalance - amountReceived) < 0 ? 0 : c.outstandingBalance - amountReceived,
          )
        else
          c,
    ]);
  }

  /// Add-or-edit by presence of [id], matching `saveCustomer` in `LedgerContext.tsx`.
  /// Editing preserves the aggregate fields — those only change via
  /// [applyOrderCreated]/[applyPaymentReceived].
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
      totalOrders: 0,
      totalBagsReceived: 0,
      totalBilled: 0,
      totalReceived: 0,
      outstandingBalance: 0,
    );
    _commit([...state, newCustomer]);
    ref.read(toastProvider.notifier).show('Customer "${newCustomer.name}" added');
    return newCustomer;
  }
}

final customersProvider = NotifierProvider<CustomersNotifier, List<Customer>>(CustomersNotifier.new);
