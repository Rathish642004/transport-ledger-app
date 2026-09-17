import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/utils/formatters.dart';

void main() {
  group('formatINR', () {
    test('groups digits Indian-style (lakh/crore)', () {
      expect(formatINR(100), '₹100');
      expect(formatINR(1234), '₹1,234');
      expect(formatINR(12345), '₹12,345');
      expect(formatINR(123456), '₹1,23,456');
      expect(formatINR(1234567), '₹12,34,567');
      expect(formatINR(12345678), '₹1,23,45,678');
    });

    test('handles sign and null/NaN', () {
      expect(formatINR(-500), '-₹500');
      expect(formatINR(500, showSign: true), '+₹500');
      expect(formatINR(0, showSign: true), '₹0');
      expect(formatINR(null), '₹0');
      expect(formatINR(double.nan), '₹0');
    });

    test('rounds fractional amounts', () {
      expect(formatINR(1234.6), '₹1,235');
    });
  });

  group('date formatters', () {
    test('formatDate', () {
      expect(formatDate('2026-09-11'), '11 Sep 2026');
      expect(formatDate(null), '—');
      expect(formatDate('not-a-date'), 'not-a-date');
    });

    test('formatShortDate', () {
      expect(formatShortDate('2026-09-11'), '11/09/26');
    });

    test('formatLRDate', () {
      expect(formatLRDate('2026-09-11'), '11-SEP-2026');
    });

    test('getTodayDateString', () {
      final result = getTodayDateString(DateTime(2026, 3, 5));
      expect(result, '2026-03-05');
    });
  });

  group('getFinancialYear', () {
    test('April onward is the FY starting that year', () {
      expect(getFinancialYear('2026-04-01'), 'FY 2026-27');
      expect(getFinancialYear('2026-09-15'), 'FY 2026-27');
      expect(getFinancialYear('2026-12-31'), 'FY 2026-27');
    });

    test('Jan-Mar belongs to the FY that started the previous year', () {
      expect(getFinancialYear('2026-01-15'), 'FY 2025-26');
      expect(getFinancialYear('2026-03-31'), 'FY 2025-26');
    });
  });

  group('numberToWordsINR', () {
    test('handles simple hundreds/thousands', () {
      // Note: the outer "AND" only appears when the trailing hundred-chunk
      // does *not* itself contain "HUNDRED" (see the original's comment in
      // formatters.ts:199) — "FIVE HUNDRED" does, so no extra "AND" here.
      expect(numberToWordsINR(5500), 'RUPEES FIVE THOUSAND FIVE HUNDRED ONLY');
      expect(numberToWordsINR(0), 'RUPEES ZERO ONLY');
      expect(numberToWordsINR(100), 'RUPEES ONE HUNDRED ONLY');
    });

    test('handles lakhs and crores', () {
      expect(numberToWordsINR(150000), 'RUPEES ONE LAKH FIFTY THOUSAND ONLY');
      // "AND" here comes from inside the hundreds chunk itself (SIX HUNDRED
      // AND SEVENTY EIGHT), not the outer join, for the same reason as above.
      expect(numberToWordsINR(12345678),
          'RUPEES ONE CRORE TWENTY THREE LAKH FORTY FIVE THOUSAND SIX HUNDRED AND SEVENTY EIGHT ONLY');
    });
  });
}
