import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mirrors `NavigationTab` in `LedgerContext.tsx:31`.
enum NavigationTab { dashboard, orders, ledger, reports, more }

/// Mirrors `activeTab`/`setActiveTab` in `LedgerContext.tsx`. `setActiveTab`
/// there also calls `navigateTo` for the tab's canonical screen; the route
/// (`go_router`) side of that is done by the bottom-nav's `onTap` in
/// `AppShell`, so this provider only tracks which tab should be highlighted.
///
/// The original's `navigateTo` only re-syncs `activeTab` when landing on one
/// of the 5 "main" screen types — sub-screens (order details, create order,
/// receive payment, ...) leave it untouched, so the highlighted tab stays on
/// whichever section you drilled in from. `AppShell` reproduces that by only
/// writing here when the current route resolves to a main tab.
class ActiveTabNotifier extends Notifier<NavigationTab> {
  @override
  NavigationTab build() => NavigationTab.dashboard;

  void set(NavigationTab tab) => state = tab;
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, NavigationTab>(ActiveTabNotifier.new);
