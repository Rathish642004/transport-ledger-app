import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/company.dart';
import '../models/customer.dart';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../providers/companies_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/drivers_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/toast_provider.dart';
import '../router/app_router.dart';
import '../utils/formatters.dart';

/// Ported from `src/screens/CreateOrderScreen.tsx`. [existingOrder] non-null
/// means edit-in-place, matching the resolved `/orders/create` `extra`
/// payload shape (`Order?`) in the implementation plan.
class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key, this.existingOrder});

  final Order? existingOrder;

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

/// The first order gets `KST/01/001`; after that, whatever the highest
/// existing `KST/01/NNN` number is, plus one — not `orders.length + 1`,
/// which would hand out a number that already exists (or is now free again)
/// the moment an order in the middle of the sequence gets deleted.
String _nextOrderNumber(List<Order> orders) {
  const prefix = 'KST/01/';
  final pattern = RegExp('^${RegExp.escape(prefix)}(\\d+)\$');
  var highest = 0;
  for (final order in orders) {
    final match = pattern.firstMatch(order.orderNumber);
    if (match == null) continue;
    final n = int.parse(match.group(1)!);
    if (n > highest) highest = n;
  }
  return '$prefix${(highest + 1).toString().padLeft(3, '0')}';
}

/// Distinct goods descriptions already used on other orders, filtered by
/// [query] (case-insensitive substring match) — the Autocomplete's
/// `optionsBuilder`. A `Set` (not just dropping later repeats) is what keeps
/// e.g. 20 past orders that all shipped "Cotton Yarn,10s/2 KW" from listing
/// that same suggestion 20 times.
Iterable<String> _previousGoodsDescriptions(List<Order> orders, String query) {
  final distinct = <String>{};
  for (final order in orders) {
    final desc = (order.goodsDescription?.trim().isNotEmpty ?? false) ? order.goodsDescription!.trim() : order.bagType.trim();
    if (desc.isNotEmpty) distinct.add(desc);
  }
  final options = distinct.toList()..sort();
  if (query.isEmpty) return options;
  final lowerQuery = query.toLowerCase();
  return options.where((g) => g.toLowerCase().contains(lowerQuery));
}

enum _Section { details, charges, driver, billing }

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  _Section _openSection = _Section.details;

  /// Lets the section widgets below (in the same file, but not `State`
  /// subclasses) trigger a rebuild without calling the `@protected`
  /// `setState` directly.
  void applyChange(VoidCallback mutator) => setState(mutator);

  Order? get _initial => widget.existingOrder;

  // All fields below are assigned once, eagerly, in initState — NOT via
  // lazy `late` field initializers. Several of these controllers were never
  // touched during build() when their accordion section stayed closed for
  // the whole session (e.g. Section 4's fields when the user never opens
  // it), so a lazy `late` initializer — one that reads `ref` — would only
  // run on first access, which happened to be inside `dispose()`'s cleanup
  // loop. `ref` is unsafe to use once the widget is unmounted, so that
  // crashed. Eager assignment in initState sidesteps this entirely.

  // Section 1
  late final TextEditingController _lrNumberCtrl;
  late String _orderNumber;
  late String _orderDate;

  late String _companyId;
  late String _companyName;
  late final TextEditingController _consignorDivisionCtrl;
  late final TextEditingController _consignorAddressCtrl;

  late String _customerId;
  late String _customerName;
  late final TextEditingController _consigneeAddressCtrl;

  late final TextEditingController _deliveryAddressCtrl;
  late final TextEditingController _pickupLocationCtrl;
  late final TextEditingController _deliveryLocationCtrl;
  late final TextEditingController _vehicleNumberCtrl;
  late final TextEditingController _invoiceDetailsCtrl;

  late String _driverId;
  late String _driverName;

  late int _numberOfBags;
  late final TextEditingController _goodsDescriptionCtrl;
  late double _ratePerBag;
  late final TextEditingController _orderNotesCtrl;

  // Section 2
  late double _loadingCharges;
  late double _transportationCharges;
  late double _otherCharges;

  double get _totalCustomerBill => _loadingCharges + _transportationCharges + _otherCharges;

  // Section 3
  late double _driverFreight;
  late double _driverPaidAmount;
  late final TextEditingController _driverBillNumberCtrl;
  // No UI input for these three in the source either — carried through from
  // initialData (edit) or defaulted, never user-editable on this screen.
  late final String _driverBillDate;
  late final double _additionalLoadingExpense;
  late final double _otherTransportExpense;
  late final String _driverBillAttachmentName;

  // Section 4
  late PayerType _billPayer;
  late final TextEditingController _billRecipientNameCtrl;
  late final TextEditingController _billNumberCtrl;
  // No UI input for these four in the source either — same as the driver
  // fields above.
  late final String _billDate;
  late final bool _tdsApplicable;
  late final double _tdsPercentage;
  late final double _otherDeductions;
  late final TextEditingController _paymentTermsCtrl;
  late final TextEditingController _billingNotesCtrl;

  double get _tdsAmount => _tdsApplicable ? ((_totalCustomerBill * _tdsPercentage) / 100).roundToDouble() : 0;
  double get _netExpectedReceipt => _totalCustomerBill - _tdsAmount - _otherDeductions;

  @override
  void initState() {
    super.initState();
    final initial = _initial;
    final companies = ref.read(companiesProvider);
    final customers = ref.read(customersProvider);
    final drivers = ref.read(driversProvider);
    final nextOrderNumber = _nextOrderNumber(ref.read(ordersProvider));

    _orderNumber = initial?.orderNumber ?? nextOrderNumber;
    _lrNumberCtrl = TextEditingController(text: initial?.lrNumber ?? initial?.orderNumber ?? nextOrderNumber);
    _orderDate = initial?.orderDate ?? getTodayDateString();

    // On a brand-new order (no `initial`), the first company/customer in
    // each list is auto-selected — matching `_onCompanyChanged`/
    // `_onCustomerChanged`'s own address-building logic, so the fields it
    // fills in look the same whether that "selection" happened by default or
    // because the user actually picked from the dropdown.
    final autoCompany = initial == null && companies.isNotEmpty ? companies.first : null;
    final autoCustomer = initial == null && customers.isNotEmpty ? customers.first : null;

    _companyId = initial?.companyId ?? autoCompany?.id ?? '';
    _companyName = initial?.companyName ?? autoCompany?.name ?? '';
    _consignorDivisionCtrl = TextEditingController(text: initial?.consignorDivision ?? 'OE Division');
    final autoCompanyAddress = autoCompany == null
        ? null
        : (autoCompany.address.isNotEmpty ? '${autoCompany.address}, ${autoCompany.city}' : autoCompany.city);
    _consignorAddressCtrl = TextEditingController(text: initial?.consignorAddress ?? initial?.pickupLocation ?? autoCompanyAddress ?? '');

    _customerId = initial?.customerId ?? autoCustomer?.id ?? '';
    _customerName = initial?.customerName ?? autoCustomer?.name ?? '';
    final autoCustomerAddress = autoCustomer == null
        ? null
        : (autoCustomer.deliveryAddress.isNotEmpty ? '${autoCustomer.deliveryAddress}, ${autoCustomer.city}' : autoCustomer.city);
    _consigneeAddressCtrl = TextEditingController(text: initial?.consigneeAddress ?? autoCustomerAddress ?? '');

    _deliveryAddressCtrl = TextEditingController(text: initial?.deliveryAddress ?? autoCustomerAddress ?? '');
    _pickupLocationCtrl = TextEditingController(text: initial?.pickupLocation ?? autoCompanyAddress ?? '');
    _deliveryLocationCtrl = TextEditingController(text: initial?.deliveryLocation ?? autoCustomerAddress ?? '');
    _invoiceDetailsCtrl = TextEditingController(text: initial?.invoiceDetails ?? '');

    final autoDriver = initial == null && drivers.isNotEmpty ? drivers.first : null;
    _driverId = initial?.driverId ?? autoDriver?.id ?? '';
    _driverName = initial?.driverName ?? autoDriver?.name ?? '';
    // Auto-selecting the first driver should also auto-fill their (first)
    // vehicle, the same as actually picking them from the dropdown does —
    // see `_onDriverChanged`.
    _vehicleNumberCtrl = TextEditingController(text: initial?.vehicleNumber ?? autoDriver?.vehicleNumber ?? '');

    _numberOfBags = initial?.numberOfBags ?? 55;
    _goodsDescriptionCtrl = TextEditingController(text: initial?.goodsDescription ?? initial?.bagType ?? '');
    _ratePerBag = initial?.ratePerBag ?? 100;
    _orderNotesCtrl = TextEditingController(text: initial?.notes ?? '');

    _loadingCharges = initial?.charges.loadingCharges ?? 0;
    _transportationCharges = initial?.charges.transportationCharges ??
        ((initial != null && initial.numberOfBags > 0) ? initial.numberOfBags * (initial.ratePerBag ?? 100) : 5500);
    _otherCharges = initial?.charges.otherCharges ?? 0;

    _driverFreight = initial?.driverExpense.driverFreight ?? 4200;
    _driverPaidAmount = initial?.driverExpense.driverPaidAmount ?? 3000;
    _driverBillNumberCtrl = TextEditingController(text: initial?.driverExpense.driverBillNumber ?? '');
    _driverBillDate = initial?.driverExpense.driverBillDate ?? getTodayDateString();
    _additionalLoadingExpense = initial?.driverExpense.additionalLoadingExpense ?? 0;
    _otherTransportExpense = initial?.driverExpense.otherTransportExpense ?? 200;
    _driverBillAttachmentName = initial?.driverExpense.driverBillAttachment ?? '';

    _billPayer = initial?.billing.billPayer ?? PayerType.company;
    _billRecipientNameCtrl = TextEditingController(text: initial?.billing.billRecipientName ?? _companyName);
    _billNumberCtrl = TextEditingController(text: initial?.billing.billNumber ?? _lrNumberCtrl.text);
    _billDate = initial?.billing.billDate ?? getTodayDateString();
    _tdsApplicable = initial?.billing.tdsApplicable ?? false;
    _tdsPercentage = initial?.billing.tdsPercentage ?? 0;
    _otherDeductions = initial?.billing.otherDeductions ?? 0;
    _paymentTermsCtrl = TextEditingController(text: initial?.billing.paymentTerms ?? '15 Days Credit');
    _billingNotesCtrl = TextEditingController(text: initial?.billing.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _lrNumberCtrl,
      _consignorDivisionCtrl,
      _consignorAddressCtrl,
      _consigneeAddressCtrl,
      _deliveryAddressCtrl,
      _pickupLocationCtrl,
      _deliveryLocationCtrl,
      _vehicleNumberCtrl,
      _invoiceDetailsCtrl,
      _goodsDescriptionCtrl,
      _orderNotesCtrl,
      _driverBillNumberCtrl,
      _billRecipientNameCtrl,
      _billNumberCtrl,
      _paymentTermsCtrl,
      _billingNotesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onLrNumberChanged(String v) {
    setState(() {
      _orderNumber = v;
      // Auto-sync bill number with LR number, unless editing an order that
      // already had one — matches the `useEffect` in the original.
      if (_initial?.billing.billNumber == null ||
          _initial!.billing.billNumber.isEmpty) {
        _billNumberCtrl.text = v;
      }
    });
  }

  void _onCompanyChanged(String id) {
    final company = ref.read(companiesProvider).firstWhere((c) => c.id == id);
    setState(() {
      _companyId = id;
      _companyName = company.name;
      final addr = company.address.isNotEmpty
          ? '${company.address}, ${company.city}'
          : company.city;
      _consignorAddressCtrl.text = addr;
      _pickupLocationCtrl.text = addr;
      if (_billPayer == PayerType.company) {
        _billRecipientNameCtrl.text = company.name;
      }
    });
  }

  void _onCustomerChanged(String id) {
    final customer = ref.read(customersProvider).firstWhere((c) => c.id == id);
    setState(() {
      _customerId = id;
      _customerName = customer.name;
      final addr = customer.deliveryAddress.isNotEmpty
          ? '${customer.deliveryAddress}, ${customer.city}'
          : customer.city;
      _consigneeAddressCtrl.text = addr;
      _deliveryLocationCtrl.text = addr;
      _deliveryAddressCtrl.text = addr;
      if (_billPayer == PayerType.customer) {
        _billRecipientNameCtrl.text = customer.name;
      }
    });
  }

  void _onDriverChanged(String id) {
    final driver = ref.read(driversProvider).firstWhere((d) => d.id == id);
    setState(() {
      _driverId = id;
      _driverName = driver.name;
      if (driver.vehicleNumber.isNotEmpty) {
        _vehicleNumberCtrl.text = driver.vehicleNumber;
      }
    });
  }

  void _onBillPayerChanged(PayerType payer) {
    setState(() {
      _billPayer = payer;
      _billRecipientNameCtrl.text = payer == PayerType.company
          ? _companyName
          : _customerName;
    });
  }

  void _onBagsOrRateChanged() {
    setState(() {
      if (_ratePerBag > 0) {
        _transportationCharges = _numberOfBags * _ratePerBag;
      }
    });
  }

  void _handleSave(OrderStatus status) {
    if (_companyName.trim().isEmpty) {
      ref
          .read(toastProvider.notifier)
          .show(
            'Please select or specify the Consignor (Company) name',
            ToastType.warning,
          );
      return;
    }
    if (_customerName.trim().isEmpty) {
      ref
          .read(toastProvider.notifier)
          .show(
            'Please select or specify the Consignee (Customer) name',
            ToastType.warning,
          );
      return;
    }
    if (_numberOfBags <= 0) {
      ref
          .read(toastProvider.notifier)
          .show('Please enter a valid bag quantity', ToastType.warning);
      return;
    }
    if (_totalCustomerBill <= 0) {
      ref
          .read(toastProvider.notifier)
          .show('Total bill amount must be greater than ₹0', ToastType.warning);
      return;
    }

    final lrNumber = _lrNumberCtrl.text.isNotEmpty
        ? _lrNumberCtrl.text
        : _orderNumber;
    final vehicleNumber = _vehicleNumberCtrl.text;

    DriverPaymentStatus driverPaymentStatus;
    if (_driverPaidAmount >= _driverFreight && _driverFreight > 0) {
      driverPaymentStatus = DriverPaymentStatus.paidInFull;
    } else if (_driverPaidAmount > 0) {
      driverPaymentStatus = DriverPaymentStatus.advancePaid;
    } else {
      driverPaymentStatus = DriverPaymentStatus.unpaid;
    }

    final driverBillNumber = _driverBillNumberCtrl.text.isNotEmpty
        ? _driverBillNumberCtrl.text
        : 'DB-${vehicleNumber.length >= 4 ? vehicleNumber.substring(vehicleNumber.length - 4) : vehicleNumber}/'
              '${_orderNumber.length >= 3 ? _orderNumber.substring(_orderNumber.length - 3) : _orderNumber}';

    final payload = Order(
      id: _initial?.id ?? '',
      orderNumber: _orderNumber,
      lrNumber: lrNumber,
      orderDate: _orderDate,
      companyId: _companyId.isNotEmpty ? _companyId : 'comp-custom',
      companyName: _companyName,
      consignorDivision: _consignorDivisionCtrl.text,
      consignorAddress: _consignorAddressCtrl.text,
      customerId: _customerId.isNotEmpty ? _customerId : 'cust-custom',
      customerName: _customerName,
      consigneeAddress: _consigneeAddressCtrl.text,
      deliveryAddress: _deliveryAddressCtrl.text,
      pickupLocation: _pickupLocationCtrl.text,
      deliveryLocation: _deliveryLocationCtrl.text,
      vehicleNumber: vehicleNumber,
      invoiceDetails: _invoiceDetailsCtrl.text,
      driverId: _driverId.isNotEmpty ? _driverId : 'drv-custom',
      driverName: _driverName,
      numberOfBags: _numberOfBags,
      bagType: _goodsDescriptionCtrl.text,
      goodsDescription: _goodsDescriptionCtrl.text,
      ratePerBag: _ratePerBag,
      rateUnit: '/BAG',
      notes: _orderNotesCtrl.text,
      notesHistory: _initial?.notesHistory ?? const [],
      orderStatus: status,
      paymentStatus: _initial?.paymentStatus ?? PaymentStatus.unpaid,
      amountReceived: _initial?.amountReceived ?? 0,
      charges: OrderCharges(
        loadingCharges: _loadingCharges,
        transportationCharges: _transportationCharges,
        otherCharges: _otherCharges,
        totalCustomerBill: _totalCustomerBill,
      ),
      driverExpense: DriverExpense(
        driverId: _driverId.isNotEmpty ? _driverId : 'drv-custom',
        driverName: _driverName,
        driverFreight: _driverFreight,
        driverPaidAmount: _driverPaidAmount,
        driverPaymentStatus: driverPaymentStatus,
        driverBillNumber: driverBillNumber,
        driverBillDate: _driverBillDate,
        driverBillAttachment: _driverBillAttachmentName,
        additionalLoadingExpense: _additionalLoadingExpense,
        otherTransportExpense: _otherTransportExpense,
      ),
      billing: BillingDetails(
        billPayer: _billPayer,
        billRecipientName: _billRecipientNameCtrl.text,
        billNumber: _billNumberCtrl.text.isNotEmpty
            ? _billNumberCtrl.text
            : lrNumber,
        billDate: _billDate,
        tdsApplicable: _tdsApplicable,
        tdsPercentage: _tdsPercentage,
        tdsAmount: _tdsAmount,
        otherDeductions: _otherDeductions,
        netExpectedReceipt: _netExpectedReceipt,
        paymentTerms: _paymentTermsCtrl.text,
        notes: _billingNotesCtrl.text,
      ),
      financialSummary: FinancialSummary(
        grossBill: _totalCustomerBill,
        driverExpenseTotal: _driverFreight,
        otherExpenseTotal: _additionalLoadingExpense + _otherTransportExpense,
        expectedTds: _tdsAmount,
        expectedNetReceipt: _netExpectedReceipt,
        estimatedProfit:
            _totalCustomerBill -
            _driverFreight -
            _additionalLoadingExpense -
            _otherTransportExpense,
      ),
      createdAt: _initial?.createdAt ?? '',
      updatedAt: _initial?.updatedAt ?? '',
    );

    final initial = _initial;
    final String targetOrderId;
    if (initial != null && initial.id.isNotEmpty) {
      ref.read(ordersProvider.notifier).updateOrder(initial.id, payload);
      targetOrderId = initial.id;
    } else {
      final created = ref.read(ordersProvider.notifier).createOrder(payload);
      targetOrderId = created.id;
    }
    context.pushReplacement(AppRoutes.billPreviewPath(targetOrderId));
  }

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(companiesProvider);
    final customers = ref.watch(customersProvider);
    final drivers = ref.watch(driversProvider);
    final orders = ref.watch(ordersProvider);
    final estimatedProfit =
        _totalCustomerBill -
        _driverFreight -
        _additionalLoadingExpense -
        _otherTransportExpense;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TopBanner(
          isEdit: _initial != null,
          lrNumber: _lrNumberCtrl.text,
          orderDate: _orderDate,
          onDateChanged: (d) => setState(() => _orderDate = d),
        ),
        const SizedBox(height: 12),
        _LiveBillSummary(
          numberOfBags: _numberOfBags,
          ratePerBag: _ratePerBag,
          totalCustomerBill: _totalCustomerBill,
          driverFreight: _driverFreight,
          driverPaidAmount: _driverPaidAmount,
          estimatedProfit: estimatedProfit,
        ),
        const SizedBox(height: 12),
        _AccordionSection(
          index: 1,
          color: const Color(0xFF0369A1),
          title: 'Section 1: LR Header, Parties & Delivery Address',
          isOpen: _openSection == _Section.details,
          onToggle: () => setState(
            () => _openSection = _openSection == _Section.details
                ? _Section.charges
                : _Section.details,
          ),
          child: _Section1Details(
            state: this,
            companies: companies,
            customers: customers,
            drivers: drivers,
            orders: orders,
          ),
        ),
        const SizedBox(height: 12),
        _AccordionSection(
          index: 2,
          color: const Color(0xFF059669),
          title: 'Section 2: Bill Summary & Additional Charges',
          isOpen: _openSection == _Section.charges,
          onToggle: () => setState(
            () => _openSection = _openSection == _Section.charges
                ? _Section.driver
                : _Section.charges,
          ),
          child: _Section2Charges(state: this),
        ),
        const SizedBox(height: 12),
        _AccordionSection(
          index: 3,
          color: const Color(0xFFD97706),
          title: 'Section 3: Driver Freight & Advance Expense',
          isOpen: _openSection == _Section.driver,
          onToggle: () => setState(
            () => _openSection = _openSection == _Section.driver
                ? _Section.billing
                : _Section.driver,
          ),
          child: _Section3Driver(state: this),
        ),
        const SizedBox(height: 12),
        _AccordionSection(
          index: 4,
          color: const Color(0xFF4F46E5),
          title: 'Section 4: Billing, TDS & Bank Terms',
          isOpen: _openSection == _Section.billing,
          onToggle: () => setState(
            () => _openSection = _openSection == _Section.billing
                ? _Section.details
                : _Section.billing,
          ),
          child: _Section4Billing(state: this),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleSave(OrderStatus.draft),
                child: const Text('Save as Draft'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                ),
                onPressed: () => _handleSave(OrderStatus.booked),
                icon: const Icon(Icons.check, size: 16),
                label: Text(
                  _initial != null
                      ? 'Update & View Bill'
                      : 'Save & Generate Official Bill',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.isEdit,
    required this.lrNumber,
    required this.orderDate,
    required this.onDateChanged,
  });

  final bool isEdit;
  final String lrNumber;
  final String orderDate;
  final ValueChanged<String> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit
                      ? 'EDIT TRANSPORT LR / BILL'
                      : 'NEW LR TRANSPORT BOOKING',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1),
                  ),
                ),
                Text(
                  lrNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(orderDate) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) onDateChanged(getTodayDateString(picked));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                orderDate,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBillSummary extends StatelessWidget {
  const _LiveBillSummary({
    required this.numberOfBags,
    required this.ratePerBag,
    required this.totalCustomerBill,
    required this.driverFreight,
    required this.driverPaidAmount,
    required this.estimatedProfit,
  });

  final int numberOfBags;
  final double ratePerBag;
  final double totalCustomerBill;
  final double driverFreight;
  final double driverPaidAmount;
  final double estimatedProfit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Bill & Financial Calculation',
                style: TextStyle(
                  color: Color(0xFF7DD3FC),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '$numberOfBags Bags @ ₹${ratePerBag.round()}/bag',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  'Customer Bill',
                  formatINR(totalCustomerBill),
                  Colors.white,
                  big: true,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  'Driver Freight',
                  formatINR(driverFreight),
                  const Color(0xFFFCD34D),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  'Advance Paid',
                  formatINR(driverPaidAmount),
                  const Color(0xFF7DD3FC),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  'Est. Profit',
                  formatINR(estimatedProfit),
                  estimatedProfit >= 0
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFCA5A5),
                  big: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color, {this.big = false});

  final String label;
  final String value;
  final Color color;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 14 : 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.index,
    required this.color,
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });

  final int index;
  final Color color;
  final String title;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(14),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
  hintText: hint,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
  ),
);

class _Section1Details extends StatelessWidget {
  const _Section1Details({
    required this.state,
    required this.companies,
    required this.customers,
    required this.drivers,
    required this.orders,
  });

  final _CreateOrderScreenState state;
  final List<Company> companies;
  final List<Customer> customers;
  final List<Driver> drivers;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('LR Number *'),
                  TextField(
                    controller: state._lrNumberCtrl,
                    onChanged: state._onLrNumberChanged,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: _fieldDecoration(hint: 'e.g. KST/27/162'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Invoice Details *'),
                  TextField(
                    controller: state._invoiceDetailsCtrl,
                    decoration: _fieldDecoration(hint: 'e.g. OYIS/26-27/168'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Consignor (From / Mill) *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.companiesEdit),
                    child: const Text(
                      '+ New Company',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: companies.any((c) => c.id == state._companyId)
                    ? state._companyId
                    : null,
                decoration: _fieldDecoration(),
                items: [
                  for (final c in companies)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${c.name} (${c.city})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) state._onCompanyChanged(v);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Division'),
                        TextField(
                          controller: state._consignorDivisionCtrl,
                          decoration: _fieldDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Consignor Address'),
                        TextField(
                          controller: state._consignorAddressCtrl,
                          decoration: _fieldDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Consignee (To Party) *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.customersEdit),
                    child: const Text(
                      '+ New Customer',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: customers.any((c) => c.id == state._customerId)
                    ? state._customerId
                    : null,
                decoration: _fieldDecoration(),
                items: [
                  for (final c in customers)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${c.name} (${c.city})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) state._onCustomerChanged(v);
                },
              ),
              const SizedBox(height: 8),
              const _FieldLabel('Consignee Address'),
              TextField(
                controller: state._consigneeAddressCtrl,
                maxLines: 2,
                decoration: _fieldDecoration(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _FieldLabel('Delivery Address (Unloading Destination) *'),
        TextField(
          controller: state._deliveryAddressCtrl,
          maxLines: 2,
          decoration: _fieldDecoration(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Vehicle Number *'),
                  Builder(builder: (context) {
                    final driverMatches = drivers.where((d) => d.id == state._driverId);
                    final vehicles = driverMatches.isNotEmpty ? driverMatches.first.allVehicleNumbers : const <String>[];
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: vehicles.contains(state._vehicleNumberCtrl.text) ? state._vehicleNumberCtrl.text : null,
                      decoration: _fieldDecoration(hint: vehicles.isEmpty ? 'Select a driver first' : null),
                      items: [
                        for (final v in vehicles)
                          DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                      ],
                      onChanged: vehicles.isEmpty ? null : (v) => state.applyChange(() => state._vehicleNumberCtrl.text = v!),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Driver Name'),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: drivers.any((d) => d.id == state._driverId)
                        ? state._driverId
                        : null,
                    decoration: _fieldDecoration(),
                    items: [
                      for (final d in drivers)
                        DropdownMenuItem(
                          value: d.id,
                          child: Text(
                            '${d.name} (${d.vehicleNumber})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) state._onDriverChanged(v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    size: 16,
                    color: Color(0xFF0369A1),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Goods & Freight Billing Math',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _FieldLabel('Goods Description *'),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: state._goodsDescriptionCtrl.text),
                optionsBuilder: (query) => _previousGoodsDescriptions(orders, query.text),
                onSelected: (selection) => state._goodsDescriptionCtrl.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: _fieldDecoration(hint: 'e.g. Cotton Yarn,10s/2 KW'),
                    onChanged: (v) => state._goodsDescriptionCtrl.text = v,
                  );
                },
              ),
              const SizedBox(height: 8),
              _GoodsMathRow(state: state),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () =>
                state.applyChange(() => state._openSection = _Section.charges),
            child: const Text('Next: Check Other Charges →'),
          ),
        ),
      ],
    );
  }
}

class _GoodsMathRow extends StatefulWidget {
  const _GoodsMathRow({required this.state});

  final _CreateOrderScreenState state;

  @override
  State<_GoodsMathRow> createState() => _GoodsMathRowState();
}

class _GoodsMathRowState extends State<_GoodsMathRow> {
  late final _bagsCtrl = TextEditingController(
    text: '${widget.state._numberOfBags}',
  );
  late final _rateCtrl = TextEditingController(
    text: widget.state._ratePerBag == widget.state._ratePerBag.roundToDouble()
        ? '${widget.state._ratePerBag.round()}'
        : '${widget.state._ratePerBag}',
  );
  late final _freightCtrl = TextEditingController(
    text: '${widget.state._transportationCharges.round()}',
  );

  @override
  void dispose() {
    _bagsCtrl.dispose();
    _rateCtrl.dispose();
    _freightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Qty (Bags) *'),
              TextField(
                controller: _bagsCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
                decoration: _fieldDecoration(hint: '55'),
                onChanged: (v) {
                  widget.state.applyChange(() {
                    widget.state._numberOfBags = int.tryParse(v) ?? 0;
                    widget.state._onBagsOrRateChanged();
                  });
                  _freightCtrl.text =
                      '${widget.state._transportationCharges.round()}';
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Rate/Bag (₹) *'),
              TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
                decoration: _fieldDecoration(hint: '100'),
                onChanged: (v) {
                  widget.state.applyChange(() {
                    widget.state._ratePerBag = double.tryParse(v) ?? 0;
                    widget.state._onBagsOrRateChanged();
                  });
                  _freightCtrl.text =
                      '${widget.state._transportationCharges.round()}';
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Total Freight (₹)'),
              TextField(
                controller: _freightCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0369A1),
                ),
                decoration: _fieldDecoration(hint: '5500'),
                onChanged: (v) => widget.state.applyChange(
                  () => widget.state._transportationCharges =
                      double.tryParse(v) ?? 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section2Charges extends StatelessWidget {
  const _Section2Charges({required this.state});

  final _CreateOrderScreenState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Transportation Charges (₹) *',
                initialValue: state._transportationCharges,
                onChanged: (v) =>
                    state.applyChange(() => state._transportationCharges = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberField(
                label: 'Loading / Hamali (₹)',
                initialValue: state._loadingCharges,
                onChanged: (v) =>
                    state.applyChange(() => state._loadingCharges = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberField(
                label: 'Other / Toll / Detention (₹)',
                initialValue: state._otherCharges,
                onChanged: (v) =>
                    state.applyChange(() => state._otherCharges = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Customer Bill Amount:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
              Text(
                formatINR(state._totalCustomerBill),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () =>
                state.applyChange(() => state._openSection = _Section.driver),
            child: const Text('Next: Driver Freight & Expenses →'),
          ),
        ),
      ],
    );
  }
}

class _Section3Driver extends StatelessWidget {
  const _Section3Driver({required this.state});

  final _CreateOrderScreenState state;

  @override
  Widget build(BuildContext context) {
    final balance = (state._driverFreight - state._driverPaidAmount).clamp(
      0,
      double.infinity,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Driver Freight (₹) *',
                initialValue: state._driverFreight,
                onChanged: (v) =>
                    state.applyChange(() => state._driverFreight = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberField(
                label: 'Advance Paid to Driver (₹)',
                initialValue: state._driverPaidAmount,
                onChanged: (v) =>
                    state.applyChange(() => state._driverPaidAmount = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Driver Balance to be Settled:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
              Text(
                formatINR(balance),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () =>
                state.applyChange(() => state._openSection = _Section.billing),
            child: const Text('Next: Payment Terms & Billing →'),
          ),
        ),
      ],
    );
  }
}

class _Section4Billing extends StatelessWidget {
  const _Section4Billing({required this.state});

  final _CreateOrderScreenState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Who will pay the transport bill? *'),
        Row(
          children: [
            Expanded(
              child: _PayerButton(
                label: 'Company (Consignor)',
                icon: Icons.business,
                selected: state._billPayer == PayerType.company,
                onTap: () => state._onBillPayerChanged(PayerType.company),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PayerButton(
                label: 'Customer (Consignee)',
                icon: Icons.local_shipping,
                selected: state._billPayer == PayerType.customer,
                onTap: () => state._onBillPayerChanged(PayerType.customer),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Bill Recipient'),
                  TextField(
                    controller: state._billRecipientNameCtrl,
                    decoration: _fieldDecoration(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Payment Terms'),
                  TextField(
                    controller: state._paymentTermsCtrl,
                    decoration: _fieldDecoration(hint: 'e.g. 15 Days Credit'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Receivable Bill Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C4A6E),
                    ),
                  ),
                  Text(
                    'Payable via NEFT / RTGS to SBI Account',
                    style: TextStyle(fontSize: 10, color: Color(0xFF0369A1)),
                  ),
                ],
              ),
              Text(
                formatINR(state._netExpectedReceipt),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF075985),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PayerButton extends StatelessWidget {
  const _PayerButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0369A1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF0369A1) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : const Color(0xFF334155),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final double initialValue;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _controller = TextEditingController(
    text: widget.initialValue == 0 ? '' : '${widget.initialValue.round()}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.label),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: _fieldDecoration(hint: '0'),
          onChanged: (v) => widget.onChanged(double.tryParse(v) ?? 0),
        ),
      ],
    );
  }
}
