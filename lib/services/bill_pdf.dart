import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/bank_account.dart';
import '../models/transporter_profile.dart';

const _navy = PdfColor.fromInt(0xFF0F172A);
const _slate600 = PdfColor.fromInt(0xFF475569);
const _slate200 = PdfColor.fromInt(0xFFCBD5E1);
const _slateBg = PdfColor.fromInt(0xFFF8FAFC);
const _accent = PdfColor.fromInt(0xFF0369A1);
const _white = PdfColors.white;

/// Renders the transport bill as a PDF for `Printing.layoutPdf` — new, not
/// in the source (there's no native equivalent to a browser's
/// `window.print()`; see `BillPreviewScreen`'s doc comment). Content mirrors
/// `_BillDocument`'s fields, laid out for print rather than pixel-matched to
/// the on-screen widget.
///
/// The outer `Column` is split into a fixed-height header band, an
/// `Expanded` body (so the bill always fills the full page height instead
/// of collapsing to the top half when the content is short), and a footer
/// band — with a `Spacer` inside the body pushing the signature block down
/// to sit just above the footer.
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
  final cardBorder = pw.BoxDecoration(
    color: _white,
    border: pw.Border.all(color: _slate200),
    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
  );
  final cellBorder = pw.BoxDecoration(border: pw.Border.all(color: _slate200, width: 0.6));

  pw.Widget field(String label, String value, {bool mono = false, double labelSize = 8, double valueSize = 10}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: labelSize, color: _slate600, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
        pw.SizedBox(height: 3),
        pw.Text(
          value.isNotEmpty ? value.toUpperCase() : '-',
          style: pw.TextStyle(fontSize: valueSize, fontWeight: pw.FontWeight.bold, font: mono ? pw.Font.courier() : null),
        ),
      ],
    );
  }

  pw.Widget cell(pw.Widget child) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: cellBorder,
        child: child,
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ---- Header band ---------------------------------------------------
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(28, 22, 28, 18),
            decoration: const pw.BoxDecoration(color: _navy),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TRANSPORT BILL', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _white, letterSpacing: 1)),
                    pw.SizedBox(height: 3),
                    pw.Text('Consignment Note / Lorry Receipt', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(profile.businessName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: _white)),
                    pw.SizedBox(height: 2),
                    pw.Text(profile.address, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
                    pw.Text('${profile.city}, ${profile.state} - ${profile.pincode}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
                    if (profile.phone.isNotEmpty || profile.gstin.isNotEmpty)
                      pw.Text(
                        [if (profile.phone.isNotEmpty) 'Ph: ${profile.phone}', if (profile.gstin.isNotEmpty) 'GSTIN: ${profile.gstin}'].join('   •   '),
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ---- Body (fills all remaining height) ------------------------------
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(28, 18, 28, 0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // LR / Date strip
                  pw.Container(
                    width: double.infinity,
                    decoration: cardBorder,
                    child: pw.Row(children: [
                      cell(field('LR No.', lrNumber, mono: true, valueSize: 12)),
                      cell(field('Date', lrDate, mono: true, valueSize: 12)),
                      cell(field('Vehicle No.', vehicleNumber, mono: true, valueSize: 12)),
                    ]),
                  ),
                  pw.SizedBox(height: 10),

                  // Consignor / consignee
                  pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: cardBorder,
                        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          field('Consignor (From)', consignorName),
                          if (consignorDivision?.isNotEmpty ?? false) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(consignorDivision!.toUpperCase(), style: const pw.TextStyle(fontSize: 9, color: _slate600)),
                          ],
                          pw.SizedBox(height: 6),
                          pw.Text(consignorAddress.toUpperCase(), style: const pw.TextStyle(fontSize: 9, color: _slate600)),
                        ]),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: cardBorder,
                        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          field('Consignee (To)', consigneeName),
                          pw.SizedBox(height: 6),
                          pw.Text(consigneeAddress.toUpperCase(), style: const pw.TextStyle(fontSize: 9, color: _slate600)),
                        ]),
                      ),
                    ),
                  ]),
                  pw.SizedBox(height: 10),

                  // Delivery / invoice
                  pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: cardBorder,
                        child: field('Delivery Address', deliveryAddress),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: cardBorder,
                        child: field('Invoice Details', invoiceDetails),
                      ),
                    ),
                  ]),
                  pw.SizedBox(height: 14),

                  // Goods table
                  pw.Table(
                    border: pw.TableBorder.all(color: _slate200, width: 0.6),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(5),
                      1: pw.FlexColumnWidth(2),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: _navy),
                        children: [
                          _th('GOODS DESCRIPTION'),
                          _th('QTY', align: pw.Alignment.center),
                          _th('RATE', align: pw.Alignment.center),
                          _th('AMOUNT', align: pw.Alignment.centerRight),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _td(goodsDescription.toUpperCase()),
                          _td('$numberOfBags BAGS', align: pw.Alignment.center, mono: true),
                          _td('Rs.${ratePerBag.round()}/BAG', align: pw.Alignment.center, mono: true),
                          _td('Rs.${totalBillAmount.round()}/-', align: pw.Alignment.centerRight, mono: true, bold: true),
                        ],
                      ),
                    ],
                  ),

                  // Total row
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: const pw.BoxDecoration(
                      color: _slateBg,
                      border: pw.Border(left: pw.BorderSide(color: _slate200, width: 0.6), right: pw.BorderSide(color: _slate200, width: 0.6), bottom: pw.BorderSide(color: _slate200, width: 0.6)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL BILL AMOUNT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _slate600)),
                        pw.Text('Rs. ${totalBillAmount.round()}/-', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _accent)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Amount in words
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: cardBorder,
                    child: pw.RichText(text: pw.TextSpan(children: [
                      pw.TextSpan(text: 'Amount in Words:  ', style: const pw.TextStyle(fontSize: 9, color: _slate600)),
                      pw.TextSpan(text: amountInWords, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ])),
                  ),
                  pw.SizedBox(height: 10),

                  // Bank + PAN details
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: cardBorder,
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('PAYMENT DETAILS', style: pw.TextStyle(fontSize: 8, color: _slate600, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                      pw.SizedBox(height: 6),
                      pw.Wrap(
                        spacing: 18,
                        runSpacing: 4,
                        children: [
                          if (bank != null) ...[
                            _kv('Bank', bank.bankName),
                            _kv('A/c No', bank.accountNumber, mono: true),
                            _kv('Name', bank.accountHolderName),
                            _kv('IFSC', bank.ifscCode, mono: true),
                          ],
                          _kv('PAN', profile.pan, mono: true),
                          if (profile.upiId.isNotEmpty) _kv('UPI', profile.upiId, mono: true),
                        ],
                      ),
                    ]),
                  ),

                  if (profile.termsAndConditions.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Terms & Conditions: ${profile.termsAndConditions}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],

                  pw.Spacer(),

                  // Signature row
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 16),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(width: 140, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _slate600)))),
                            pw.SizedBox(height: 4),
                            pw.Text('Receiver\'s Signature', style: const pw.TextStyle(fontSize: 9, color: _slate600)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Container(width: 160, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _slate600)))),
                            pw.SizedBox(height: 4),
                            pw.Text('For ${profile.businessName}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8, color: _slate600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Footer band -----------------------------------------------------
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            decoration: const pw.BoxDecoration(color: _navy),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('This is a computer-generated bill.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey400)),
                pw.Text(profile.businessName, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey400)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

pw.Widget _th(String text, {pw.Alignment align = pw.Alignment.centerLeft}) {
  return pw.Container(
    alignment: align,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: pw.Text(text, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.4)),
  );
}

pw.Widget _td(String text, {pw.Alignment align = pw.Alignment.centerLeft, bool mono = false, bool bold = false}) {
  return pw.Container(
    alignment: align,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, font: mono ? pw.Font.courier() : null),
    ),
  );
}

pw.Widget _kv(String label, String value, {bool mono = false}) {
  return pw.RichText(text: pw.TextSpan(children: [
    pw.TextSpan(text: '$label: ', style: const pw.TextStyle(fontSize: 9, color: _slate600)),
    pw.TextSpan(text: value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: mono ? pw.Font.courier() : null)),
  ]));
}
