import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/formatters.dart';

/// Mirrors `selectedFinancialYear`/`setSelectedFinancialYear` in
/// `LedgerContext.tsx:219`.
class SelectedFinancialYearNotifier extends Notifier<String> {
  @override
  String build() => getFinancialYear();

  void set(String fy) => state = fy;
}

final selectedFinancialYearProvider =
    NotifierProvider<SelectedFinancialYearNotifier, String>(SelectedFinancialYearNotifier.new);

/// Mirrors `selectedMonth`/`setSelectedMonth` in `LedgerContext.tsx:220`.
class SelectedMonthNotifier extends Notifier<String> {
  @override
  String build() => 'All Months';

  void set(String month) => state = month;
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, String>(SelectedMonthNotifier.new);
