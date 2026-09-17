import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../storage/hive_boxes.dart';
import 'toast_provider.dart';

/// Mirrors the company-related logic in `LedgerContext.tsx`:
/// `createOrder`'s company side-effect (:487-503), `receivePayment`'s company
/// balance update (:635-646), and `saveCompany` (:741-778).
class CompaniesNotifier extends Notifier<List<Company>> {
  @override
  List<Company> build() => companiesBox.values.toList();

  void _commit(List<Company> next) {
    for (final c in next) {
      companiesBox.put(c.id, c);
    }
    state = next;
  }

  /// Bumps trip/billing stats when a new order is created against this company.
  void applyOrderCreated(Order order) {
    final isBillCompany = order.billing.billPayer == PayerType.company;
    _commit([
      for (final c in state)
        if (c.id == order.companyId || c.name == order.companyName)
          c.copyWith(
            totalOrders: c.totalOrders + 1,
            totalBagsDispatched: c.totalBagsDispatched + order.numberOfBags,
            totalBilled: isBillCompany ? c.totalBilled + order.charges.totalCustomerBill : null,
            outstandingBalance:
                isBillCompany ? c.outstandingBalance + order.billing.netExpectedReceipt : null,
          )
        else
          c,
    ]);
  }

  /// Applies a received payment to the matching company's balance.
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

  /// Add-or-edit by presence of [id], matching `saveCompany` in `LedgerContext.tsx`.
  /// Editing preserves the aggregate fields (`totalOrders`, `totalBilled`, ...) —
  /// those are only ever changed by [applyOrderCreated]/[applyPaymentReceived].
  Company saveCompany({
    String? id,
    required String name,
    required String contactPerson,
    required String phone,
    String? email,
    required String address,
    required String city,
    String? gstin,
    String? pan,
  }) {
    if (id != null) {
      Company? updated;
      final next = [
        for (final c in state)
          if (c.id == id)
            (updated = c.copyWith(
              name: name,
              contactPerson: contactPerson,
              phone: phone,
              email: email,
              address: address,
              city: city,
              gstin: gstin,
              pan: pan,
            ))
          else
            c,
      ];
      _commit(next);
      ref.read(toastProvider.notifier).show('Company "$name" updated');
      return updated!;
    }

    final newCompany = Company(
      id: 'comp-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email ?? '',
      address: address,
      city: city,
      gstin: gstin ?? '',
      pan: pan ?? '',
      totalOrders: 0,
      totalBagsDispatched: 0,
      totalBilled: 0,
      totalReceived: 0,
      outstandingBalance: 0,
    );
    _commit([...state, newCompany]);
    ref.read(toastProvider.notifier).show('Company "${newCompany.name}" added');
    return newCompany;
  }
}

final companiesProvider = NotifierProvider<CompaniesNotifier, List<Company>>(CompaniesNotifier.new);
