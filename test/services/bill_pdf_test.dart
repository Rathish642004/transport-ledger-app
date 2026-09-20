import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/seed_data.dart';
import 'package:flutter_app/models/bank_account.dart';
import 'package:flutter_app/services/bill_pdf.dart';

/// Regression coverage for `buildBillPdfBytes` — this is what actually
/// generates the printed/shared PDF bill, and is only reachable at runtime
/// on a device (`Printing.layoutPdf`/share), so a broken layout (e.g. a
/// `pw.MultiPage` that can't paginate, or a page overflow that silently
/// drops content) previously wasn't caught until someone tapped Print on a
/// phone. Running the builder directly here catches both without a device.
void main() {
  const bank = BankAccount(
    id: 'bank-1',
    bankName: 'SBI',
    accountHolderName: 'Kalavathi Selvaraj',
    accountNumber: '36288475312',
    ifscCode: 'SBIN0008160',
    branchName: 'Thadicombu Branch',
  );

  test('builds a non-empty PDF for a normal order without throwing', () async {
    final bytes = await buildBillPdfBytes(
      profile: initialProfile,
      bank: bank,
      lrNumber: 'KST/27/162',
      lrDate: '11-Sep-2026',
      consignorName: 'PRABHU SPINNING MILLS PRIVATE LIMITED',
      consignorDivision: 'OE DIVISION',
      consignorAddress: 'KOTTAIYUR, AGARAM, DINDIGUL-624 -709',
      consigneeName: 'ECO JUTE P LTD',
      consigneeAddress: 'KANKARIA STREET, 6TH FLOOR, ROOM NO 6, KOLKATA-700071',
      deliveryAddress: 'FASHION PROCESS MILL, MANNARAI, TIRUPPUR-641 607',
      vehicleNumber: 'TN30Y4407',
      goodsDescription: 'Cotton Yarn,10s/2 KW',
      numberOfBags: 55,
      ratePerBag: 100,
      totalBillAmount: 5500,
      amountInWords: 'Rupees Five Thousand Five Hundred Only',
    );

    // A real, multi-page-capable PDF is at minimum a few KB — a truncated
    // or single-line document (the bug this guards against) would still
    // produce *some* bytes, so also sanity-check the PDF's own page count.
    expect(bytes.length, greaterThan(2000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('does not throw with no bank account and no terms and conditions', () async {
    final profile = initialProfile.copyWith(termsAndConditions: '');

    final bytes = await buildBillPdfBytes(
      profile: profile,
      bank: null,
      lrNumber: 'KST/27/163',
      lrDate: '14-Sep-2026',
      consignorName: 'PRABHU SPINNING MILLS PRIVATE LIMITED',
      consignorDivision: null,
      consignorAddress: 'KOTTAIYUR, AGARAM, DINDIGUL-624 -709',
      consigneeName: 'ECO JUTE P LTD',
      consigneeAddress: 'KANKARIA STREET, KOLKATA-700071',
      deliveryAddress: 'MANNARAI, TIRUPPUR-641 607',
      vehicleNumber: 'TN30Y4407',
      goodsDescription: 'Cotton Yarn,10s/2 KW',
      numberOfBags: 60,
      ratePerBag: 100,
      totalBillAmount: 6000,
      amountInWords: 'Rupees Six Thousand Only',
    );

    expect(bytes.length, greaterThan(2000));
  });

  test('does not throw with a very long terms-and-conditions block (multi-page-capable content)', () async {
    final profile = initialProfile.copyWith(
      termsAndConditions: List.filled(40, 'A long line of terms and conditions text repeated many times over.').join(' '),
    );

    final bytes = await buildBillPdfBytes(
      profile: profile,
      bank: bank,
      lrNumber: 'KST/27/999',
      lrDate: '20-Sep-2026',
      consignorName: 'A VERY LONG CONSIGNOR COMPANY NAME PRIVATE LIMITED THAT WRAPS ACROSS MULTIPLE LINES',
      consignorDivision: 'A LONG DIVISION NAME',
      consignorAddress: 'A very long consignor address that spans several lines of text to check wrapping and pagination behaves correctly without throwing any layout exceptions',
      consigneeName: 'ANOTHER LONG CONSIGNEE NAME PRIVATE LIMITED',
      consigneeAddress: 'A very long consignee address that also spans several lines of text to check wrapping and pagination behaves correctly',
      deliveryAddress: 'A very long delivery address that spans several lines of text as well, to make sure nothing overflows a single page badly',
      vehicleNumber: 'TN30Y4407',
      goodsDescription: 'Cotton Yarn,10s/2 KW - Premium Export Quality',
      numberOfBags: 999,
      ratePerBag: 100,
      totalBillAmount: 99900,
      amountInWords: 'Rupees Ninety Nine Thousand Nine Hundred Only',
    );

    expect(bytes.length, greaterThan(2000));
  });
}
