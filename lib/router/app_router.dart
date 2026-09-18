import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../models/order.dart';
import '../screens/add_edit_company_screen.dart';
import '../screens/add_edit_customer_screen.dart';
import '../screens/add_edit_bank_screen.dart';
import '../screens/add_edit_driver_screen.dart';
import '../screens/bank_transactions_screen.dart';
import '../screens/banks_list_screen.dart';
import '../screens/bill_preview_screen.dart';
import '../screens/companies_list_screen.dart';
import '../screens/create_order_screen.dart';
import '../screens/customers_list_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/drivers_list_screen.dart';
import '../screens/expense_entry_screen.dart';
import '../screens/ledger_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/order_details_screen.dart';
import '../screens/orders_list_screen.dart';
import '../screens/pay_driver_screen.dart';
import '../screens/receive_payment_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../storage/hive_boxes.dart' as hive;
import '../widgets/app_shell.dart';

/// Route paths, named so `AppShell` and tests can reference them without
/// stringly-typed literals scattered around.
class AppRoutes {
  AppRoutes._();

  static const onboarding = '/onboarding';
  static const dashboard = '/';
  static const orders = '/orders';
  static const createOrder = '/orders/create';
  static const orderDetails = '/orders/:id';
  static const billPreview = '/orders/:id/bill';
  static const receivePayment = '/receive-payment';
  static const payDriver = '/pay-driver';
  static const expense = '/expense';
  static const ledger = '/ledger';
  static const reports = '/reports';
  static const settings = '/settings';
  static const companies = '/companies';
  static const customers = '/customers';
  static const drivers = '/drivers';
  static const companiesEdit = '/companies/edit';
  static const customersEdit = '/customers/edit';
  static const driversEdit = '/drivers/edit';
  static const banks = '/banks';
  static const banksEdit = '/banks/edit';
  static const bankTransactions = '/banks/:id/transactions';

  static String orderDetailsPath(String id) => '/orders/$id';
  static String billPreviewPath(String id) => '/orders/$id/bill';
  static String bankTransactionsPath(String id) => '/banks/$id/transactions';
}

/// Resolved route table (see the implementation plan's "Resolved: navigation
/// / `extra` payload shapes" section): every route from `ActiveScreen` in
/// `LedgerContext.tsx:33-55`, minus `splash` (unused) and with `create_order`
/// as the sole route taking a typed `extra` (`Order?`) — every other
/// screen's optional data is scalar path/query params.
///
/// Every route lives under a single `ShellRoute` (`AppShell`) — verified
/// against `App.tsx`: `MainNavigator` wraps *every* `ActiveScreen`, not just
/// the 5 tab screens, in one `MobileFrame`, so the app bar/bottom nav/FAB
/// chrome persists even on drill-in screens like Order Details or Create
/// Order. This is a deliberate fidelity choice, not an oversight.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    // First run (or any launch before a profile has been created/restored)
    // is gated to `OnboardingScreen` — see its doc comment. `profileBox` is
    // opened synchronously in `initHive` before the router is ever built, so
    // this read is safe on every redirect check, not just the first.
    redirect: (context, state) {
      final needsOnboarding = hive.profileBox.isEmpty;
      final onOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (needsOnboarding) return onOnboarding ? null : AppRoutes.onboarding;
      return onOnboarding ? AppRoutes.dashboard : null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (context, state) => const OrdersListScreen(),
          ),
          GoRoute(
            path: AppRoutes.createOrder,
            builder: (context, state) => CreateOrderScreen(existingOrder: state.extra as Order?),
          ),
          GoRoute(
            path: AppRoutes.orderDetails,
            builder: (context, state) => OrderDetailsScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.billPreview,
            builder: (context, state) => BillPreviewScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.receivePayment,
            builder: (context, state) => ReceivePaymentScreen(
              orderId: state.uri.queryParameters['orderId'],
              partyType: state.uri.queryParameters['partyType'] != null
                  ? PayerType.fromJson(state.uri.queryParameters['partyType']!)
                  : null,
              partyId: state.uri.queryParameters['partyId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.payDriver,
            builder: (context, state) => PayDriverScreen(
              orderId: state.uri.queryParameters['orderId'],
              driverId: state.uri.queryParameters['driverId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.expense,
            builder: (context, state) => ExpenseEntryScreen(orderId: state.uri.queryParameters['orderId']),
          ),
          GoRoute(
            path: AppRoutes.ledger,
            builder: (context, state) => LedgerScreen(initialTab: state.uri.queryParameters['tab']),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => ReportsScreen(initialTab: state.uri.queryParameters['tab']),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => SettingsScreen(initialTab: state.uri.queryParameters['tab']),
          ),
          GoRoute(
            path: AppRoutes.companies,
            builder: (context, state) => const CompaniesListScreen(),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (context, state) => const CustomersListScreen(),
          ),
          GoRoute(
            path: AppRoutes.drivers,
            builder: (context, state) => const DriversListScreen(),
          ),
          GoRoute(
            path: AppRoutes.companiesEdit,
            builder: (context, state) => AddEditCompanyScreen(companyId: state.uri.queryParameters['id']),
          ),
          GoRoute(
            path: AppRoutes.customersEdit,
            builder: (context, state) => AddEditCustomerScreen(customerId: state.uri.queryParameters['id']),
          ),
          GoRoute(
            path: AppRoutes.driversEdit,
            builder: (context, state) => AddEditDriverScreen(driverId: state.uri.queryParameters['id']),
          ),
          GoRoute(
            path: AppRoutes.banks,
            builder: (context, state) => const BanksListScreen(),
          ),
          GoRoute(
            path: AppRoutes.banksEdit,
            builder: (context, state) => AddEditBankScreen(bankAccountId: state.uri.queryParameters['id']),
          ),
          GoRoute(
            path: AppRoutes.bankTransactions,
            builder: (context, state) => BankTransactionsScreen(bankAccountId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
