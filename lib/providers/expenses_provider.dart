import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_record.dart';
import '../storage/hive_boxes.dart';
import 'toast_provider.dart';

/// Mirrors `addExpense` in `LedgerContext.tsx:727-738`.
class ExpensesNotifier extends Notifier<List<ExpenseRecord>> {
  @override
  List<ExpenseRecord> build() => expensesBox.values.toList();

  // See the known-limitation comment on OrdersNotifier._commit.
  void _commit(List<ExpenseRecord> next) {
    for (final e in next) {
      expensesBox.put(e.id, e);
    }
    state = next;
  }

  /// `expenseData`'s `id`/`expenseNumber` are placeholders — both are
  /// overwritten here, matching `Omit<ExpenseRecord, 'id' | 'expenseNumber'>`
  /// in the original.
  ExpenseRecord addExpense(ExpenseRecord expenseData) {
    // Note: numbering literally hardcodes "2026" in the source app, not the
    // current year — preserved as-is for parity with LedgerContext.tsx:728.
    final expenseNumber = 'EXP-2026-${(state.length + 52).toString().padLeft(3, '0')}';
    final newExpense = expenseData.copyWith(
      id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      expenseNumber: expenseNumber,
    );
    _commit([newExpense, ...state]);
    ref.read(toastProvider.notifier).show(
          'Recorded ${expenseData.category.jsonValue} expense of ₹${expenseData.amount.round()}',
        );
    return newExpense;
  }
}

final expensesProvider = NotifierProvider<ExpensesNotifier, List<ExpenseRecord>>(ExpensesNotifier.new);
