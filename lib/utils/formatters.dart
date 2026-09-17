/// Indian Rupee & transport accounting formatters — ported from
/// `src/utils/formatters.ts`.
library;

const monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `formatINR` (`formatters.ts:5-29`) — Indian lakh/crore digit grouping.
String formatINR(num? amount, {bool showSign = false}) {
  if (amount == null || amount.isNaN) return '₹0';

  final isNegative = amount < 0;
  final absAmount = amount.abs().round();

  final amountStr = absAmount.toString();
  final otherNumbers = amountStr.length > 3 ? amountStr.substring(0, amountStr.length - 3) : '';
  var lastThree = amountStr.length > 3 ? amountStr.substring(amountStr.length - 3) : amountStr;
  if (otherNumbers.isNotEmpty) {
    lastThree = ',$lastThree';
  }

  final groupedOther = StringBuffer();
  for (var i = 0; i < otherNumbers.length; i++) {
    final remaining = otherNumbers.length - i;
    if (i > 0 && remaining % 2 == 0) {
      groupedOther.write(',');
    }
    groupedOther.write(otherNumbers[i]);
  }
  final formattedAbs = '$groupedOther$lastThree';

  if (isNegative) return '-₹$formattedAbs';
  if (showSign && amount > 0) return '+₹$formattedAbs';
  return '₹$formattedAbs';
}

/// `formatDate` (`formatters.ts:31-44`) — e.g. "11 Sep 2026".
String formatDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '—';
  final d = DateTime.tryParse(dateString);
  if (d == null) return dateString;
  return '${d.day} ${monthAbbreviations[d.month - 1]} ${d.year}';
}

/// `formatShortDate` (`formatters.ts:46-59`) — e.g. "11/09/26".
String formatShortDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '—';
  final d = DateTime.tryParse(dateString);
  if (d == null) return dateString;
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final year = (d.year % 100).toString().padLeft(2, '0');
  return '$day/$month/$year';
}

/// `getTodayDateString` (`formatters.ts:61-67`) — `YYYY-MM-DD`.
String getTodayDateString([DateTime? now]) {
  final n = now ?? DateTime.now();
  final month = n.month.toString().padLeft(2, '0');
  final day = n.day.toString().padLeft(2, '0');
  return '${n.year}-$month-$day';
}

/// `getFinancialYear` (`formatters.ts:72-87`) — Indian FY runs Apr 1–Mar 31.
String getFinancialYear([Object? dateInput]) {
  DateTime? date;
  if (dateInput == null) {
    date = DateTime.now();
  } else if (dateInput is DateTime) {
    date = dateInput;
  } else if (dateInput is String) {
    date = DateTime.tryParse(dateInput);
  }
  if (date == null) return 'FY 2026-27';

  final month = date.month; // 1 = Jan, 4 = Apr
  final year = date.year;
  if (month >= 4) {
    return 'FY $year-${(year + 1).toString().substring(2)}';
  }
  return 'FY ${year - 1}-${year.toString().substring(2)}';
}

/// Approximates `toLocaleDateString('en-IN', {day:'numeric', month:'short',
/// year:'numeric', hour:'2-digit', minute:'2-digit'}) + ' IST'` from
/// `triggerGoogleDriveBackup` (`LedgerContext.tsx:861-868`) — e.g.
/// "15 Sep 2026, 10:30 am IST". Shared by the foreground (`BackupNotifier`)
/// and background (`backup_background_task.dart`) Drive-sync paths so a
/// manual "Sync Now" and a periodic background sync stamp the same way.
/// Never actually shown in the UI — see `BackupNotifier`'s doc comment on
/// the source's `lastBackupTimestamp`/`lastBackupDate` field-name bug — so
/// exact locale fidelity isn't load-bearing, just internal consistency.
String formatBackupTimestamp(DateTime now) {
  final hour24 = now.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final ampm = hour24 < 12 ? 'am' : 'pm';
  final minute = now.minute.toString().padLeft(2, '0');
  return '${now.day} ${monthAbbreviations[now.month - 1]} ${now.year}, $hour12:$minute $ampm IST';
}

const financialYears = ['FY 2026-27', 'FY 2025-26', 'FY 2024-25'];

const monthNames = [
  'All Months',
  'April', 'May', 'June', 'July', 'August', 'September', //
  'October', 'November', 'December', 'January', 'February', 'March',
];

/// `formatLRDate` (`formatters.ts:114-126`) — e.g. "11-SEP-2026".
String formatLRDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '—';
  final d = DateTime.tryParse(dateString);
  if (d == null) return dateString.toUpperCase();
  final day = d.day.toString().padLeft(2, '0');
  final month = monthAbbreviations[d.month - 1].toUpperCase();
  return '$day-$month-${d.year}';
}

const _ones = [
  '', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE', //
  'TEN', 'ELEVEN', 'TWELVE', 'THIRTEEN', 'FOURTEEN', 'FIFTEEN', 'SIXTEEN', //
  'SEVENTEEN', 'EIGHTEEN', 'NINETEEN',
];

const _tens = ['', '', 'TWENTY', 'THIRTY', 'FORTY', 'FIFTY', 'SIXTY', 'SEVENTY', 'EIGHTY', 'NINETY'];

String _convertTwoDigits(int num) {
  if (num < 20) return _ones[num];
  final ten = num ~/ 10;
  final unit = num % 10;
  return _tens[ten] + (unit != 0 ? ' ${_ones[unit]}' : '');
}

String _convertThreeDigits(int num) {
  final hundred = num ~/ 100;
  final rest = num % 100;
  var str = '';
  if (hundred != 0) {
    str += '${_ones[hundred]} HUNDRED';
    if (rest != 0) str += ' AND ';
  }
  if (rest != 0) {
    str += _convertTwoDigits(rest);
  }
  return str;
}

/// `numberToWordsINR` (`formatters.ts:132-209`) — e.g. 5500 ->
/// "RUPEES FIVE THOUSAND AND FIVE HUNDRED ONLY".
String numberToWordsINR(num? amount) {
  if (amount == null || amount.isNaN) return 'RUPEES ZERO ONLY';

  var num = amount.abs().round();
  if (num == 0) return 'RUPEES ZERO ONLY';

  final parts = <String>[];

  final crore = num ~/ 10000000;
  if (crore > 0) {
    final croreWords = numberToWordsINR(crore)
        .replaceFirst(RegExp(r'^RUPEES\s+'), '')
        .replaceFirst(RegExp(r'\s+ONLY$'), '');
    parts.add('$croreWords CRORE');
    num %= 10000000;
  }

  final lakh = num ~/ 100000;
  if (lakh > 0) {
    parts.add('${_convertTwoDigits(lakh)} LAKH');
    num %= 100000;
  }

  final thousand = num ~/ 1000;
  if (thousand > 0) {
    parts.add('${_convertTwoDigits(thousand)} THOUSAND');
    num %= 1000;
  }

  if (num > 0) {
    final hundredAndBelow = _convertThreeDigits(num);
    if (hundredAndBelow.isNotEmpty) {
      if (parts.isNotEmpty && !hundredAndBelow.contains('HUNDRED') && !hundredAndBelow.startsWith('AND')) {
        parts.add('AND $hundredAndBelow');
      } else {
        parts.add(hundredAndBelow);
      }
    }
  }

  final joined = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  return 'RUPEES $joined ONLY';
}
