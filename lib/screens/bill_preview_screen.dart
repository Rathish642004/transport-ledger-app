import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bank_account.dart';
import '../models/order.dart';
import '../models/transporter_profile.dart';
import '../providers/banks_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/toast_provider.dart';
import '../router/app_router.dart';
import '../services/bill_pdf.dart';
import '../utils/formatters.dart';
import '../widgets/delete_order_dialog.dart';
import '../widgets/order_notes_dialog.dart';
import '../widgets/share_format_dialog.dart';
import '../widgets/status_badge.dart';

/// Ported from `src/screens/BillPreviewScreen.tsx`. The hand-drawn truck SVG
/// header illustration is replaced with a plain icon — a decorative-only
/// flourish not worth a custom `CustomPainter` recreation. `Print` renders
/// this same bill as a PDF (via `package:pdf`) and hands it to the OS print
/// framework (via `package:printing`) — new, not in the source (a web
/// `window.print()` has no native equivalent worth faking with a toast).
/// The printed bill's bank details come from the first `BankAccount` on
/// file (see `SettingsScreen`'s doc comment) rather than the old single
/// profile-level bank fields.
class BillPreviewScreen extends ConsumerStatefulWidget {
  const BillPreviewScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

enum _ViewMode { standard, detailed }

class _BillPreviewScreenState extends ConsumerState<BillPreviewScreen> {
  _ViewMode _viewMode = _ViewMode.standard;

  Future<void> _handleShare(Order order, String lrNumber, String lrDate, String consignorName, String? consignorDivision,
      String consignorAddress, String consigneeName, String consigneeAddress, String deliveryAddress, String vehicleNumber,
      String invoiceDetails, String goodsDescription, int numberOfBags, double ratePerBag, double totalBillAmount,
      String amountInWords) async {
    final format = await showShareFormatDialog(context);
    if (format == null || !mounted) return;

    final profile = ref.read(profileProvider);
    final bank = ref.read(banksProvider).firstOrNull;

    if (format == ShareFormat.pdf) {
      final bytes = await buildBillPdfBytes(
        profile: profile,
        bank: bank,
        lrNumber: lrNumber,
        lrDate: lrDate,
        consignorName: consignorName,
        consignorDivision: consignorDivision,
        consignorAddress: consignorAddress,
        consigneeName: consigneeName,
        consigneeAddress: consigneeAddress,
        deliveryAddress: deliveryAddress,
        vehicleNumber: vehicleNumber,
        invoiceDetails: invoiceDetails,
        goodsDescription: goodsDescription,
        numberOfBags: numberOfBags,
        ratePerBag: ratePerBag,
        totalBillAmount: totalBillAmount,
        amountInWords: amountInWords,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Transport_Bill_$lrNumber.pdf');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Transport Bill $lrNumber'));
    } else {
      final bankLines = bank != null
          ? '*Bank Details:*\nBank: ${bank.bankName} | A/c No: ${bank.accountNumber}\n'
              'Name: ${bank.accountHolderName} | IFSC: ${bank.ifscCode} | PAN: ${profile.pan}'
          : '*PAN:* ${profile.pan}';
      final text = '*${profile.businessName}*\n*LR NO:* $lrNumber | *DATE:* $lrDate\n\n'
          '*Consignor (From):*\n$consignorName\n'
          '${(consignorDivision?.isNotEmpty ?? false) ? '$consignorDivision\n' : ''}$consignorAddress\n\n'
          '*Consignee (To):*\n$consigneeName\n$consigneeAddress\n\n'
          '*Delivery Address:*\n$deliveryAddress\n\n'
          '*Vehicle No:* $vehicleNumber\n*Invoice Details:* $invoiceDetails\n'
          '*Goods:* $goodsDescription\n*Qty:* $numberOfBags BAGS\n*Rate:* ${ratePerBag.round()}/BAG\n'
          '*Amount:* ₹${totalBillAmount.round()} /-\n*Amount in Words:* $amountInWords\n\n'
          '$bankLines';
      await SharePlus.instance.share(ShareParams(text: text, subject: 'Transport Bill $lrNumber'));
    }

    if (!mounted) return;
    ref.read(toastProvider.notifier).show('Bill shared successfully');
  }

  Future<void> _handlePrint(String lrNumber, String lrDate, String consignorName, String? consignorDivision,
      String consignorAddress, String consigneeName, String consigneeAddress, String deliveryAddress, String vehicleNumber,
      String invoiceDetails, String goodsDescription, int numberOfBags, double ratePerBag, double totalBillAmount,
      String amountInWords) async {
    final profile = ref.read(profileProvider);
    final bank = ref.read(banksProvider).firstOrNull;
    await Printing.layoutPdf(
      name: 'Transport Bill $lrNumber',
      onLayout: (format) => buildBillPdfBytes(
        profile: profile,
        bank: bank,
        lrNumber: lrNumber,
        lrDate: lrDate,
        consignorName: consignorName,
        consignorDivision: consignorDivision,
        consignorAddress: consignorAddress,
        consigneeName: consigneeName,
        consigneeAddress: consigneeAddress,
        deliveryAddress: deliveryAddress,
        vehicleNumber: vehicleNumber,
        invoiceDetails: invoiceDetails,
        goodsDescription: goodsDescription,
        numberOfBags: numberOfBags,
        ratePerBag: ratePerBag,
        totalBillAmount: totalBillAmount,
        amountInWords: amountInWords,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final profile = ref.watch(profileProvider);
    Order? order;
    for (final o in orders) {
      if (o.id == widget.orderId) {
        order = o;
        break;
      }
    }

    if (order == null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Order record not found', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                onPressed: () => context.pop(),
                child: const Text('Return to Orders'),
              ),
            ],
          ),
        ),
      );
    }

    final lrNumber = (order.lrNumber?.isNotEmpty ?? false) ? order.lrNumber! : order.orderNumber;
    final lrDate = formatLRDate(order.orderDate);
    final consignorName = order.companyName;
    final consignorDivision = order.consignorDivision ?? '';
    final consignorAddress = order.consignorAddress ?? order.pickupLocation;
    final consigneeName = order.customerName;
    final consigneeAddress = order.consigneeAddress ?? '';
    final deliveryAddress = order.deliveryAddress ?? '';
    final vehicleNumber = order.vehicleNumber;
    final invoiceDetails = order.invoiceDetails ?? '';
    final goodsDescription = (order.goodsDescription?.isNotEmpty ?? false) ? order.goodsDescription! : order.bagType;
    final numberOfBags = order.numberOfBags > 0 ? order.numberOfBags : 0;
    final ratePerBag = order.ratePerBag ?? (numberOfBags > 0 ? (order.charges.totalCustomerBill / numberOfBags).roundToDouble() : 0);
    final totalBillAmount = order.charges.totalCustomerBill > 0 ? order.charges.totalCustomerBill : 0.0;
    final amountInWords = numberToWordsINR(totalBillAmount);
    final notesCount = order.notes.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Toolbar(
          order: order,
          viewMode: _viewMode,
          onViewModeChanged: (m) => setState(() => _viewMode = m),
          onShare: () => _handleShare(order!, lrNumber, lrDate, consignorName, consignorDivision, consignorAddress,
              consigneeName, consigneeAddress, deliveryAddress, vehicleNumber, invoiceDetails, goodsDescription,
              numberOfBags, ratePerBag, totalBillAmount, amountInWords),
          onPrint: () => _handlePrint(lrNumber, lrDate, consignorName, consignorDivision, consignorAddress,
              consigneeName, consigneeAddress, deliveryAddress, vehicleNumber, invoiceDetails, goodsDescription,
              numberOfBags, ratePerBag, totalBillAmount, amountInWords),
        ),
        const SizedBox(height: 12),
        _BillDocument(
          profile: profile,
          bank: ref.watch(banksProvider).firstOrNull,
          lrNumber: lrNumber,
          lrDate: lrDate,
          consignorName: consignorName,
          consignorDivision: consignorDivision,
          consignorAddress: consignorAddress,
          consigneeName: consigneeName,
          consigneeAddress: consigneeAddress,
          deliveryAddress: deliveryAddress,
          vehicleNumber: vehicleNumber,
          invoiceDetails: invoiceDetails,
          goodsDescription: goodsDescription,
          numberOfBags: numberOfBags,
          ratePerBag: ratePerBag,
          totalBillAmount: totalBillAmount,
          amountInWords: amountInWords,
        ),
        if (_viewMode == _ViewMode.detailed) ...[
          const SizedBox(height: 12),
          _DetailedLedgerPanel(order: order, numberOfBags: numberOfBags, ratePerBag: ratePerBag, totalBillAmount: totalBillAmount, consignorName: consignorName),
        ],
        const SizedBox(height: 12),
        _NotesPreviewPanel(order: order, lrNumber: lrNumber, consignorName: consignorName, consigneeName: consigneeName, notesCount: notesCount),
      ],
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.order, required this.viewMode, required this.onViewModeChanged, required this.onShare, required this.onPrint});

  final Order order;
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onViewModeChanged;
  final VoidCallback onShare;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, size: 14), label: const Text('Back')),
          // Two individually-Wrap-friendly buttons instead of a single
          // `SegmentedButton`: that widget doesn't shrink or wrap internally,
          // so on a narrow phone its two longer labels overflowed the
          // toolbar (a real "RenderFlex overflowed on the right" reported
          // on-device) — each button here can wrap to its own line instead.
          _ViewModeButton(label: 'Standard Bill', selected: viewMode == _ViewMode.standard, onTap: () => onViewModeChanged(_ViewMode.standard)),
          _ViewModeButton(label: 'Ledger & Profit', selected: viewMode == _ViewMode.detailed, onTap: () => onViewModeChanged(_ViewMode.detailed)),
          IconButton(
            tooltip: 'Edit Order Details',
            onPressed: () => context.push(AppRoutes.createOrder, extra: order),
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0369A1)),
          ),
          IconButton(
            tooltip: 'Add or View Notes',
            onPressed: () => showOrderNotesDialog(context, ref, order),
            icon: const Icon(Icons.sticky_note_2_outlined, size: 18, color: Color(0xFFB45309)),
          ),
          IconButton(
            tooltip: 'Delete this Order',
            onPressed: () async {
              final deleted = await showDeleteOrderDialog(context, ref, order);
              if (deleted && context.mounted) context.go(AppRoutes.orders);
            },
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
          ),
          IconButton(
            tooltip: 'View Full Order Breakdown',
            onPressed: () => context.push(AppRoutes.orderDetailsPath(order.id)),
            icon: const Icon(Icons.visibility_outlined, size: 18),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
            onPressed: onPrint,
            icon: const Icon(Icons.print_outlined, size: 14),
            label: const Text('Print'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined, size: 14),
            label: const Text('WhatsApp'),
          ),
          FilledButton.icon(
            onPressed: () => context.push(
                '${AppRoutes.receivePayment}?orderId=${order.id}&partyType=${(order.billing.billPayer).toJson()}&partyId=${order.companyId}'),
            icon: const Icon(Icons.credit_card, size: 14),
            label: const Text('Receive Payment'),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0369A1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF0369A1) : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF334155))),
      ),
    );
  }
}

class _BillDocument extends StatelessWidget {
  const _BillDocument({
    required this.profile,
    required this.bank,
    required this.lrNumber,
    required this.lrDate,
    required this.consignorName,
    required this.consignorDivision,
    required this.consignorAddress,
    required this.consigneeName,
    required this.consigneeAddress,
    required this.deliveryAddress,
    required this.vehicleNumber,
    required this.invoiceDetails,
    required this.goodsDescription,
    required this.numberOfBags,
    required this.ratePerBag,
    required this.totalBillAmount,
    required this.amountInWords,
  });

  final TransporterProfile profile;
  final BankAccount? bank;
  final String lrNumber;
  final String lrDate;
  final String consignorName;
  final String? consignorDivision;
  final String consignorAddress;
  final String consigneeName;
  final String consigneeAddress;
  final String deliveryAddress;
  final String vehicleNumber;
  final String invoiceDetails;
  final String goodsDescription;
  final int numberOfBags;
  final double ratePerBag;
  final double totalBillAmount;
  final String amountInWords;

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(color: Color(0xFF0F172A));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFCBD5E1), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.local_shipping, size: 56, color: Color(0xFF0F172A)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      (profile.businessName).toUpperCase(),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    Text(profile.address, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11)),
                    Text(
                      (profile.pincode).isNotEmpty ? 'Thadicombu-${profile.pincode}' : 'Thadicombu-624 709',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                    const Text('Dindigul |', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0F172A))),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(border: Border(right: border, bottom: border)),
                          child: Text.rich(TextSpan(children: [
                            const TextSpan(text: 'LR NO: ', style: TextStyle(fontWeight: FontWeight.w600)),
                            TextSpan(text: lrNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                          ])),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(border: Border(bottom: border)),
                          child: Text.rich(TextSpan(children: [
                            const TextSpan(text: 'DATE: ', style: TextStyle(fontWeight: FontWeight.w600)),
                            TextSpan(text: lrDate, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                          ])),
                        ),
                      ),
                    ],
                  ),
                ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(border: Border(right: border, bottom: border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Consignor (From):', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                              Text(consignorName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
                              if (consignorDivision?.isNotEmpty ?? false)
                                Text(consignorDivision!.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 8),
                              Text(consignorAddress.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(border: Border(bottom: border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Consignee (To Address):', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                              Text(consigneeName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 8),
                              Text(consigneeAddress.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(border: Border(right: border, bottom: border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivery Address', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                              Text(deliveryAddress.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(border: Border(bottom: border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(TextSpan(children: [
                                const TextSpan(text: 'VEHICLE NO: ', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                TextSpan(text: vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                              ])),
                              const SizedBox(height: 8),
                              Text('INVOICE DETAILS-$invoiceDetails', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: border)),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Padding(padding: const EdgeInsets.all(6), child: Text('GOODS', style: _thStyle))),
                      Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(6), child: Text('QTY', textAlign: TextAlign.center, style: _thStyle))),
                      Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(6), child: Text('RATE', textAlign: TextAlign.center, style: _thStyle))),
                      Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(6), child: Text('AMOUNT', textAlign: TextAlign.right, style: _thStyle))),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(border: Border(bottom: border)),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Padding(padding: const EdgeInsets.all(8), child: Text(goodsDescription, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                      Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(8), child: Text('$numberOfBags BAGS', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11)))),
                      Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(8), child: Text('${ratePerBag.round()}/BAG', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11)))),
                      Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(8), child: Text('${totalBillAmount.round()} /-', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace')))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(border: Border(bottom: border)),
                  child: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Amount in Words: ', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    TextSpan(text: amountInWords, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  ])),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (bank != null) ...[
                        Text.rich(TextSpan(children: [const TextSpan(text: 'Bank: '), TextSpan(text: bank!.bankName, style: const TextStyle(fontWeight: FontWeight.bold))]), style: const TextStyle(fontSize: 10)),
                        Text.rich(TextSpan(children: [const TextSpan(text: 'A/c No: '), TextSpan(text: bank!.accountNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'))]), style: const TextStyle(fontSize: 10)),
                        Text.rich(TextSpan(children: [const TextSpan(text: 'Name: '), TextSpan(text: bank!.accountHolderName, style: const TextStyle(fontWeight: FontWeight.bold))]), style: const TextStyle(fontSize: 10)),
                        Text.rich(TextSpan(children: [const TextSpan(text: 'IFSC: '), TextSpan(text: bank!.ifscCode, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'))]), style: const TextStyle(fontSize: 10)),
                      ],
                      Text.rich(TextSpan(children: [const TextSpan(text: 'PAN: '), TextSpan(text: profile.pan, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'))]), style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Color(0xFF334155)),
                Text('For ${profile.businessName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _thStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569));

class _DetailedLedgerPanel extends StatelessWidget {
  const _DetailedLedgerPanel({required this.order, required this.numberOfBags, required this.ratePerBag, required this.totalBillAmount, required this.consignorName});

  final Order order;
  final int numberOfBags;
  final double ratePerBag;
  final double totalBillAmount;
  final String consignorName;

  @override
  Widget build(BuildContext context) {
    final totalExpenses = order.orderExpenses.total;
    final netProfit = totalBillAmount - totalExpenses;
    final margin = totalBillAmount > 0 ? (netProfit / totalBillAmount * 100).round() : 0;
    final balanceDue = (totalBillAmount - order.amountReceived).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text('Trip Ledger & Margins Breakdown', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(status: order.paymentStatus.jsonValue, type: StatusBadgeType.payment),
                  const SizedBox(width: 4),
                  StatusBadge(status: order.orderStatus.jsonValue),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _LedgerStat('Total Freight Revenue', formatINR(totalBillAmount), '$numberOfBags bags @ ₹${ratePerBag.round()}/bag', const Color(0xFFF8FAFC), const Color(0xFF64748B), const Color(0xFF0F172A))),
              const SizedBox(width: 8),
              Expanded(child: _LedgerStat('Trip Expenses', formatINR(totalExpenses), 'Vehicle: ${order.vehicleNumber}', const Color(0xFFFFFBEB), const Color(0xFFB45309), const Color(0xFF92400E))),
              const SizedBox(width: 8),
              Expanded(child: _LedgerStat(netProfit >= 0 ? 'Net Trip Profit' : 'Net Trip Loss', formatINR(netProfit), 'Margin: $margin%', const Color(0xFFECFDF5), const Color(0xFF047857), const Color(0xFF065F46))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                _LedgerRow('Customer / Mill Receivable:', formatINR(totalBillAmount)),
                _LedgerRow('Amount Received to Date:', formatINR(order.amountReceived), color: const Color(0xFF047857)),
                const Divider(height: 14),
                _LedgerRow('Balance Due from $consignorName:', formatINR(balanceDue), bold: true, color: const Color(0xFFBE123C)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerStat extends StatelessWidget {
  const _LedgerStat(this.label, this.value, this.subtitle, this.bg, this.labelColor, this.valueColor);

  final String label;
  final String value;
  final String subtitle;
  final Color bg;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: labelColor)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: valueColor)),
          Text(subtitle, style: TextStyle(fontSize: 9, color: labelColor)),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow(this.label, this.value, {this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: bold ? 13 : 11, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

class _NotesPreviewPanel extends ConsumerWidget {
  const _NotesPreviewPanel({required this.order, required this.lrNumber, required this.consignorName, required this.consigneeName, required this.notesCount});

  final Order order;
  final String lrNumber;
  final String consignorName;
  final String consigneeName;
  final int notesCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteLines = order.notes.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.check_circle, size: 18, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Transport Order #$lrNumber', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            StatusBadge(status: order.orderStatus.jsonValue),
                            StatusBadge(status: order.paymentStatus.jsonValue, type: StatusBadgeType.payment),
                          ],
                        ),
                        Text(
                          '$consignorName → $consigneeName (${order.vehicleNumber})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.createOrder, extra: order),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit Order', style: TextStyle(fontSize: 11)),
                  ),
                  TextButton.icon(
                    onPressed: () => showOrderNotesDialog(context, ref, order),
                    icon: const Icon(Icons.sticky_note_2_outlined, size: 14),
                    label: const Text('Add / View Notes', style: TextStyle(fontSize: 11)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final deleted = await showDeleteOrderDialog(context, ref, order);
                      if (deleted && context.mounted) context.go(AppRoutes.orders);
                    },
                    icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFDC2626)),
                    label: const Text('Delete Order', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Order Notes & Remarks ($notesCount)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => showOrderNotesDialog(context, ref, order),
                      child: Text(order.notes.isNotEmpty ? 'Manage Notes' : 'Add Note', style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                if (noteLines.isEmpty)
                  const Text(
                    'No remarks or notes recorded for this order yet. Click "Add Note" to log trip updates, loading notes, or driver cash advances.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: noteLines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, i) => Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Text(noteLines[i], style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
