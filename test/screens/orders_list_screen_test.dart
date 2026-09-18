import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';
import 'package:flutter_app/storage/hive_boxes.dart';

import '../test_helpers/hive_test_env.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await openTestHive();
    await seedIfEmpty();
  });

  tearDown(() async {
    await closeTestHive(tempDir);
  });

  Future<void> pumpOrdersList(WidgetTester tester) async {
    // Wide enough that all 6 filter chips fit without needing to scroll.
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.local_shipping_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('lists every seeded order with its order number', (tester) async {
    await pumpOrdersList(tester);

    expect(find.text('Showing 5 orders'), findsOneWidget);
    for (final n in ['KST/27/159', 'KST/27/160', 'KST/27/161', 'KST/27/162', 'KST/27/163']) {
      expect(find.text(n), findsOneWidget);
    }
  });

  testWidgets('search filters to matching orders only', (tester) async {
    await pumpOrdersList(tester);

    await tester.enterText(find.byType(TextField).first, 'ECO JUTE');
    await tester.pumpAndSettle();

    expect(find.text('Showing 2 orders'), findsOneWidget); // 162 and 163 ship to ECO JUTE P LTD
    expect(find.text('KST/27/162'), findsOneWidget);
    expect(find.text('KST/27/163'), findsOneWidget);
    expect(find.text('KST/27/159'), findsNothing);
  });

  testWidgets('a search with no matches shows the empty state with the query echoed back', (tester) async {
    await pumpOrdersList(tester);

    await tester.enterText(find.byType(TextField).first, 'zzz-no-such-order');
    await tester.pumpAndSettle();

    expect(find.text('No Orders Found'), findsOneWidget);
    expect(find.text('No orders matching "zzz-no-such-order". Try adjusting your search.'), findsOneWidget);
  });

  testWidgets('status filter chip narrows the list to unpaid/overdue orders', (tester) async {
    await pumpOrdersList(tester);

    await tester.tap(find.text('Unpaid / Due'));
    await tester.pumpAndSettle();

    expect(find.text('Showing 2 orders'), findsOneWidget);
    expect(find.text('KST/27/162'), findsOneWidget);
    expect(find.text('KST/27/163'), findsOneWidget);
    expect(find.text('KST/27/159'), findsNothing);
  });

  testWidgets('Company filter narrows the list to that company\'s orders', (tester) async {
    await pumpOrdersList(tester);

    await tester.tap(find.text('All Companies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PRABHU SPINNING MILLS PRIVATE LIMITED').last);
    await tester.pumpAndSettle();

    // comp-1 (PRABHU) is the company on orders 161, 162, and 163.
    expect(find.text('Showing 3 orders'), findsOneWidget);
    expect(find.text('KST/27/161'), findsOneWidget);
    expect(find.text('KST/27/162'), findsOneWidget);
    expect(find.text('KST/27/163'), findsOneWidget);
    expect(find.text('KST/27/159'), findsNothing);
  });

  testWidgets('Customer filter narrows the list to that customer\'s orders', (tester) async {
    await pumpOrdersList(tester);

    await tester.tap(find.text('All Customers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ECO JUTE P LTD').last);
    await tester.pumpAndSettle();

    expect(find.text('Showing 2 orders'), findsOneWidget);
    expect(find.text('KST/27/162'), findsOneWidget);
    expect(find.text('KST/27/163'), findsOneWidget);
  });

  testWidgets('the export menu offers PDF and Excel options', (tester) async {
    await pumpOrdersList(tester);

    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();

    expect(find.text('Export as PDF'), findsOneWidget);
    expect(find.text('Export as Excel (CSV)'), findsOneWidget);
  });

  testWidgets('tapping Filter by Date opens the date range picker', (tester) async {
    await pumpOrdersList(tester);

    await tester.tap(find.text('Filter by Date'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget); // the date range picker's confirm action
  });

  testWidgets('delete dialog removes the order after confirming', (tester) async {
    await pumpOrdersList(tester);

    // The delete button is the trailing icon-only action on each card; the
    // first card in the (correctly ordered) list is order 162.
    expect(ordersBox.containsKey('ord-kst-162'), isTrue);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Delete Transport Order'), findsOneWidget);

    await tester.tap(find.text('Yes, Delete Order'));
    await tester.pumpAndSettle();

    expect(find.text('Showing 4 orders'), findsOneWidget);
    expect(ordersBox.containsKey('ord-kst-162'), isFalse);

    // deleteOrder shows a toast with a real 3.8s auto-dismiss timer (see
    // ToastNotifier.show) — flush it so the test doesn't end with a pending
    // Timer, which AutomatedTestWidgetsFlutterBinding treats as a failure.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('notes dialog opens and adding a note calls through to the provider', (tester) async {
    await pumpOrdersList(tester);

    await tester.tap(find.byIcon(Icons.sticky_note_2_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Order Notes & Remarks'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Type note...'), 'Test note from widget test');
    await tester.pump(); // rebuild so the "Add" button's onPressed enables before tapping
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final updated = ordersBox.get('ord-kst-162')!;
    expect(updated.notes, contains('Test note from widget test'));

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Order Notes & Remarks'), findsNothing);

    // addOrderNote shows a toast with a real 3.8s auto-dismiss timer — flush
    // it so the test doesn't end with a pending Timer (see the delete test).
    await tester.pump(const Duration(seconds: 4));
  });
}
