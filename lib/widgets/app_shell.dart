import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/metrics_provider.dart';
import '../providers/navigation_provider.dart';
import '../router/app_router.dart';
import 'toast_overlay.dart';

/// Replaces `MobileFrame.tsx`. Verified against the source rather than
/// assumed:
///
/// - The top app bar is *always* "Transport Ledger" with *no* back button —
///   `App.tsx`'s `MainNavigator` never passes `title`/`subtitle`/
///   `showBackButton` to `MobileFrame`, so those props are permanently at
///   their defaults. Individual screens render their own in-content
///   headers/back-arrows (Phase 4), separate from this shell.
/// - The bottom nav + FAB chrome wraps *every* route, not just the 5 tab
///   screens (`MainNavigator` wraps every `ActiveScreen` in one
///   `MobileFrame`) — see the router's doc comment.
/// - The FAB only shows on the Dashboard and Orders routes
///   (`shouldShowFAB` in `MobileFrame.tsx:63-64`).
/// - The Orders tab gets a numeric badge from `ordersInProgressCount`; the
///   notification bell gets a dot badge when `overdueBillsCount > 0`
///   (`MobileFrame.tsx:171-173,241-245`).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  /// The `navigateTo`-driven tab sync (`LedgerContext.tsx:279-291`): only
  /// these paths re-sync the highlighted tab; everything else (order
  /// details, create order, receive payment, ...) leaves it on whichever
  /// tab it already was.
  static NavigationTab? _mainTabForPath(String path) {
    switch (path) {
      case AppRoutes.dashboard:
        return NavigationTab.dashboard;
      case AppRoutes.orders:
        return NavigationTab.orders;
      case AppRoutes.ledger:
        return NavigationTab.ledger;
      case AppRoutes.reports:
        return NavigationTab.reports;
      case AppRoutes.settings:
      case AppRoutes.companies:
      case AppRoutes.customers:
      case AppRoutes.banks:
        return NavigationTab.more;
      default:
        return null;
    }
  }

  static const _tabRoutes = {
    NavigationTab.dashboard: AppRoutes.dashboard,
    NavigationTab.orders: AppRoutes.orders,
    NavigationTab.ledger: AppRoutes.ledger,
    NavigationTab.reports: AppRoutes.reports,
    NavigationTab.more: AppRoutes.settings,
  };

  void _onTabSelected(WidgetRef ref, BuildContext context, NavigationTab tab) {
    ref.read(activeTabProvider.notifier).set(tab);
    context.go(_tabRoutes[tab]!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    final syncedTab = _mainTabForPath(location);
    if (syncedTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(activeTabProvider) != syncedTab) {
          ref.read(activeTabProvider.notifier).set(syncedTab);
        }
      });
    }

    final activeTab = ref.watch(activeTabProvider);
    final metrics = ref.watch(metricsProvider);
    final showFab = location == AppRoutes.dashboard || location == AppRoutes.orders;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Transport Ledger'),
        actions: [
          IconButton(
            tooltip: 'Notifications & Outstanding Alerts',
            onPressed: () => context.push('${AppRoutes.reports}?tab=notifications'),
            icon: Badge(
              isLabelVisible: metrics.overdueBillsCount > 0,
              smallSize: 10,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: ToastOverlay(child: child),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.createOrder),
              icon: const Icon(Icons.add),
              label: const Text('Create Order'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab.index,
        onDestinationSelected: (index) => _onTabSelected(ref, context, NavigationTab.values[index]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: metrics.ordersInProgressCount > 0,
              label: Text('${metrics.ordersInProgressCount}'),
              child: const Icon(Icons.local_shipping_outlined),
            ),
            selectedIcon: const Icon(Icons.local_shipping),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Ledger',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
