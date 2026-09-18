import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/bank_account.dart';
import '../models/transporter_profile.dart';

/// Renders the transport bill as a PDF for `Printing.layoutPdf` — new, not
/// in the source (there's no native equivalent to a browser's
/// `window.print()`; see `BillPreviewScreen`'s doc comment). Content mirrors
/// `_BillDocument`'s fields, laid out for print rather than pixel-matched to
/// the on-screen widget.
Future<Uint8List> buildBillPdfBytes({
  required TransporterProfile profile,
  required BankAccount? bank,
  required String lrNumber,
  required String lrDate,
  required String consignorName,
  required String? consignorDivision,
  required String consignorAddress,
  required String consigneeName,
  required String consigneeAddress,
  required String deliveryAddress,
  required String vehicleNumber,
  required String invoiceDetails,
  required String goodsDescription,
  required int numberOfBags,
  required double ratePerBag,
  required double totalBillAmount,
  required String amountInWords,
}) async {
  final doc = pw.Document();
  final border = pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black));

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TRANSPORT BILL', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(profile.businessName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  pw.Text(profile.address, style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('${profile.city} - ${profile.pincode}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            decoration: border,
            child: pw.Column(
              children: [
                pw.Row(children: [
                  pw.Expanded(child: pw.Container(padding: const pw.EdgeInsets.all(6), decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(), bottom: pw.BorderSide())), child: pw.Text('LR NO: $lrNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)))),
                  pw.Expanded(child: pw.Container(padding: const pw.EdgeInsets.all(6), decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())), child: pw.Text('DATE: $lrDate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)))),
                ]),
                pw.Row(children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(), bottom: pw.BorderSide())),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text('Consignor (From):', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text(consignorName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        if (consignorDivision?.isNotEmpty ?? false) pw.Text(consignorDivision!.toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 4),
                        pw.Text(consignorAddress.toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
                      ]),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text('Consignee (To):', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text(consigneeName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(consigneeAddress.toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
                      ]),
                    ),
                  ),
                ]),
                pw.Row(children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(), bottom: pw.BorderSide())),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text('Delivery Address:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text(deliveryAddress.toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
                      ]),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text('VEHICLE NO: $vehicleNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text('INVOICE DETAILS: $invoiceDetails', style: const pw.TextStyle(fontSize: 9)),
                      ]),
                    ),
                  ),
                ]),
                pw.TableHelper.fromTextArray(
                  border: null,
                  headers: ['GOODS', 'QTY', 'RATE', 'AMOUNT'],
                  data: [
                    [goodsDescription, '$numberOfBags BAGS', '${ratePerBag.round()}/BAG', '${totalBillAmount.round()} /-'],
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.centerRight},
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                ),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(), bottom: pw.BorderSide())),
                  child: pw.Text('Amount in Words: $amountInWords', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Wrap(
                    spacing: 12,
                    children: [
                      if (bank != null) ...[
                        pw.Text('Bank: ${bank.bankName}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('A/c No: ${bank.accountNumber}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Name: ${bank.accountHolderName}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('IFSC: ${bank.ifscCode}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                      pw.Text('PAN: ${profile.pan}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Container(
            width: 160,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Divider(),
                pw.Text('For ${profile.businessName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}
