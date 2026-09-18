import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bank_account.dart';
import '../storage/hive_boxes.dart';
import 'toast_provider.dart';

/// New concept, not in the React source — see `BankAccount`'s doc comment.
/// Mirrors the add-or-edit-by-id shape every other master-data notifier uses
/// (`CompaniesNotifier.saveCompany`, etc.) for consistency.
class BanksNotifier extends Notifier<List<BankAccount>> {
  @override
  List<BankAccount> build() => banksBox.values.toList();

  void _commit(List<BankAccount> next) {
    for (final b in next) {
      banksBox.put(b.id, b);
    }
    state = next;
  }

  BankAccount saveBankAccount({
    String? id,
    required String bankName,
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String branchName,
    String? upiId,
  }) {
    if (id != null) {
      BankAccount? updated;
      final next = [
        for (final b in state)
          if (b.id == id)
            (updated = b.copyWith(
              bankName: bankName,
              accountHolderName: accountHolderName,
              accountNumber: accountNumber,
              ifscCode: ifscCode,
              branchName: branchName,
              upiId: upiId,
            ))
          else
            b,
      ];
      _commit(next);
      ref.read(toastProvider.notifier).show('Bank account "$bankName" updated');
      return updated!;
    }

    final newAccount = BankAccount(
      id: 'bank-${DateTime.now().millisecondsSinceEpoch}',
      bankName: bankName,
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      branchName: branchName,
      upiId: upiId,
    );
    _commit([...state, newAccount]);
    ref.read(toastProvider.notifier).show('Bank account "$bankName" added');
    return newAccount;
  }

  void deleteBankAccount(String id) {
    banksBox.delete(id);
    state = state.where((b) => b.id != id).toList();
    ref.read(toastProvider.notifier).show('Bank account removed', ToastType.info);
  }
}

final banksProvider = NotifierProvider<BanksNotifier, List<BankAccount>>(BanksNotifier.new);
