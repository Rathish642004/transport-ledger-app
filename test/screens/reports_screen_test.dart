import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  Future<GoRouter> pumpReports(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;
    router.push('/reports');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('P&L tab shows the FY 2026-27 net profit computed from all 5 seed orders', (tester) async {
    await pumpReports(tester);

    // Bill: 5500+6000+7000+5000+6000=29500; driver: 4200+4500+5200+3800+4500=22200;
    // other direct: 200+200+300+200+200=1100; net = 29500-23300 = 6200.
    expect(find.text('₹6,200'), findsWidgets);
    expect(find.text('21.0% Margin'), findsOneWidget);
    expect(find.text('₹29,500'), findsWidgets);
  });

  testWidgets('TDS tab shows zero TDS since no seed order has tdsApplicable', (tester) async {
    await pumpReports(tester);

    await tester.tap(find.text('TDS 194C'));
    await tester.pumpAndSettle();

    expect(find.text('TDS TRANSACTION REGISTER (0 ORDERS)'), findsOneWidget);
    expect(find.text('₹0'), findsOneWidget);
  });

  testWidgets('Dues tab lists the 2 orders with a positive pending balance', (tester) async {
    await pumpReports(tester);

    await tester.tap(find.text('Dues'));
    await tester.pumpAndSettle();

    expect(find.text('2 unpaid / pending trips'), findsOneWidget);
    expect(find.text('₹11,500'), findsOneWidget); // 5500 (ord-162) + 6000 (ord-163)
    expect(find.text('KST/27/162'), findsOneWidget);
    expect(find.text('KST/27/163'), findsOneWidget);
  });

  testWidgets('Trip Margin tab lists all 5 FY orders with per-trip profit', (tester) async {
    await pumpReports(tester);

    await tester.tap(find.text('Trip Margin'));
    await tester.pumpAndSettle();

    expect(find.text('5 Trips Recorded'), findsOneWidget);
    expect(find.text('KST/27/162'), findsOneWidget);
    expect(find.text('₹1,100'), findsOneWidget); // ord-162's estimatedProfit
  });

  testWidgets('switching to a FY with no orders shows a zeroed-out report', (tester) async {
    await pumpReports(tester);

    await tester.tap(find.text('FY 2026-27 (Current)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FY 2025-26').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trip Margin'));
    await tester.pumpAndSettle();
    expect(find.text('0 Trips Recorded'), findsOneWidget);
  });
}
