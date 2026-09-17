import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/main.dart';
import 'package:flutter_app/storage/hive_boxes.dart';

import '../test_helpers/hive_test_env.dart';

/// Widget tests for `AppShell` — the Phase 3 acceptance criteria from the
/// implementation plan: tab switching, back-button visibility (verified
/// against the source: it's *never* shown — see `app_shell.dart`'s doc
/// comment), and FAB visibility per route.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await openTestHive();
    // DashboardScreen (Phase 4) reads profileProvider et al., which assume
    // a seeded box, matching the real app's first-launch behavior.
    await seedIfEmpty();
  });

  tearDown(() async {
    await closeTestHive(tempDir);
  });

  GoRouter routerOf(WidgetTester tester) {
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    return app.routerConfig! as GoRouter;
  }

  testWidgets('starts on Dashboard with the FAB visible and no back button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets); // placeholder body + nav label
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('tapping the Orders tab navigates there, highlights it, and keeps the FAB', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.local_shipping_outlined));
    await tester.pumpAndSettle();

    expect(routerOf(tester).routerDelegate.currentConfiguration.uri.path, '/orders');
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
    expect(find.text('Orders'), findsWidgets); // nav label + placeholder body
    expect(find.byType(FloatingActionButton), findsOneWidget); // FAB shows on Orders too
  });

  testWidgets('tapping the Ledger tab hides the FAB', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    expect(routerOf(tester).routerDelegate.currentConfiguration.uri.path, '/ledger');
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('a pushed sub-screen keeps the shell chrome, hides the FAB, and never shows a back button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Land on Orders first (so the "sticky last tab" has something to stick to).
    await tester.tap(find.byIcon(Icons.local_shipping_outlined));
    await tester.pumpAndSettle();

    routerOf(tester).push('/orders/ord-kst-162');
    await tester.pumpAndSettle();

    expect(find.text('KST/27/162'), findsWidgets); // real OrderDetailsScreen content
    // Bottom nav persists even on a drill-in screen (the shell wraps every route).
    expect(find.byType(NavigationBar), findsOneWidget);
    // /orders/ord-1 isn't a "main" tab path, so the highlight stays on Orders.
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
    // Not the Dashboard/Orders routes exactly, so no FAB.
    expect(find.byType(FloatingActionButton), findsNothing);
    // The shell's app bar never shows a back button, even with a pop-able
    // route — scoped to the AppBar specifically, since OrderDetailsScreen
    // legitimately renders its own in-content back button (by design: see
    // AppShell's doc comment).
    expect(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.arrow_back)), findsNothing);
    expect(find.descendant(of: find.byType(AppBar), matching: find.byType(BackButton)), findsNothing);
  });

  testWidgets('the notification bell navigates to Reports (which ignores the tab param, matching the source)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Financial Reports & Tax'), findsOneWidget);
  });
}
