import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/order.dart';
import '../utils/formatters.dart';

/// New capability — not in the React source. Exports the Orders list
/// (whatever the user currently has filtered) as CSV (opens directly in
/// Excel/Sheets) or PDF, via the same share-sheet handoff pattern already
/// used for local JSON/CSV backups (`BackupNotifier`).
String _csvNum(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

List<List<String>> _rows(List<Order> orders) {
  return [
    ['Order No', 'Date', 'Company', 'Customer', 'Vehicle', 'Bags', 'Status', 'Payment', 'Bill (INR)', 'Received (INR)', 'Due (INR)'],
    for (final o in orders)
      [
        o.orderNumber,
        o.orderDate,
        o.companyName,
        o.customerName,
        o.vehicleNumber,
        '${o.numberOfBags}',
        o.orderStatus.jsonValue,
        o.paymentStatus.jsonValue,
        _csvNum(o.charges.totalCustomerBill),
        _csvNum(o.amountReceived),
        _csvNum((o.charges.totalCustomerBill - o.amountReceived).clamp(0, double.infinity)),
      ],
  ];
}

Future<void> exportOrdersCsv(List<Order> orders) async {
  final rows = _rows(orders);
  final buffer = StringBuffer();
  for (final row in rows) {
    buffer.writeln(row.map((c) => c.contains(',') ? '"${c.replaceAll('"', '""')}"' : c).join(','));
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/Transport_Orders_${getTodayDateString()}.csv');
  await file.writeAsString(buffer.toString());

  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Transport Orders Export'));
}

Future<void> exportOrdersPdf(List<Order> orders) async {
  final rows = _rows(orders);
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => [
        pw.Text('Transport Orders Export', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text('Generated ${formatDate(getTodayDateString())} • ${orders.length} orders', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: rows.first,
          data: rows.skip(1).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          cellAlignments: {5: pw.Alignment.centerRight, 8: pw.Alignment.centerRight, 9: pw.Alignment.centerRight, 10: pw.Alignment.centerRight},
        ),
      ],
    ),
  );

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/Transport_Orders_${getTodayDateString()}.pdf');
  await file.writeAsBytes(await doc.save());

  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Transport Orders Export'));
}
