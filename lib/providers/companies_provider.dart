import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company.dart';
import '../storage/hive_boxes.dart';
import 'toast_provider.dart';

/// Mirrors `saveCompany` in `LedgerContext.tsx:741-778`. Billing/outstanding
/// totals are no longer stored here — they're derived from orders + payments
/// by `partyLedgerProvider`, which is the single place the `billPayer` rule
/// (which party an order's receivable belongs to) lives.
class CompaniesNotifier extends Notifier<List<Company>> {
  @override
  List<Company> build() => companiesBox.values.toList();

  void _commit(List<Company> next) {
    for (final c in next) {
      companiesBox.put(c.id, c);
    }
    state = next;
  }

  /// Add-or-edit by presence of [id], matching `saveCompany` in `LedgerContext.tsx`.
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
    bool tdsApplicable = false,
    double tdsPercentage = 0,
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
              tdsApplicable: tdsApplicable,
              tdsPercentage: tdsPercentage,
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
      tdsApplicable: tdsApplicable,
      tdsPercentage: tdsPercentage,
    );
    _commit([...state, newCompany]);
    ref.read(toastProvider.notifier).show('Company "${newCompany.name}" added');
    return newCompany;
  }
}

final companiesProvider = NotifierProvider<CompaniesNotifier, List<Company>>(CompaniesNotifier.new);
