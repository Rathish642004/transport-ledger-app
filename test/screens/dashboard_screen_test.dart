import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/seed_data.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/storage/hive_boxes.dart';
import 'package:flutter_app/utils/formatters.dart';

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

  testWidgets('renders the business name, net profit, and recent orders from seed data', (tester) async {
    // Tall viewport so the whole scrollable dashboard is built at once,
    // rather than needing to scroll to reach off-screen list content.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text(initialProfile.businessName), findsOneWidget);

    // Net profit = totalRevenue (5500+6000+7000+5000+6000=29500) minus
    // totalExpenses: driver freight (4200+4500+5200+3800+4500=22200) +
    // additional/other transport expense (1100) + direct expenses
    // (200+200+1800+450+3500=6150) = 29450. netProfit = 29500-29450 = 50.
    expect(find.text(formatINR(50)), findsOneWidget);

    // Recent orders section shows the first 4 orders in seed order — this is
    // a regression check for a real bug: Hive's Box iterates in key-sorted
    // order ("159" < "160" < "161" < "162" alphabetically), NOT the seed's
    // authored order, which put "162" first. Without `OrderedBoxIndex`
    // preserving the explicit order, these would render 159/160/161/162
    // instead of the correct 162/161/160/159.
    expect(find.text('KST/27/163'), findsNothing); // 5th order, not in the top-4 slice
    final orderNumbers = ['KST/27/162', 'KST/27/161', 'KST/27/160', 'KST/27/159'];
    final verticalPositions = [
      for (final n in orderNumbers) tester.getTopLeft(find.text(n)).dy,
    ];
    expect(
      verticalPositions,
      orderedEquals(List<double>.from(verticalPositions)..sort()),
      reason: 'orders must render top-to-bottom in the order $orderNumbers',
    );

    // Recent payments (top 3 of the 3 seeded receipts).
    expect(find.text('PRABHU SPINNING MILLS PRIVATE LIMITED'), findsWidgets);
  });

  testWidgets('quick actions navigate to the right routes', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Order'));
    await tester.pumpAndSettle();

    expect(find.text('NEW LR TRANSPORT BOOKING'), findsOneWidget);
  });
}
