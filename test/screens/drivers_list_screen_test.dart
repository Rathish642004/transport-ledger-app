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

  Future<GoRouter> pumpDrivers(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;
    router.push('/drivers');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('lists all 4 drivers with freight/paid stats and payable dues', (tester) async {
    await pumpDrivers(tester);

    expect(find.text('K. Selvaraj'), findsOneWidget);
    expect(find.text('M. Murugesan'), findsOneWidget);
    expect(find.text('P. Kannan'), findsOneWidget);
    expect(find.text('R. Karuppasamy'), findsOneWidget);
    expect(find.text('TN30Y4407'), findsOneWidget);
    expect(find.text('₹4,200'), findsOneWidget);
    expect(find.text('8 Completed Trips'), findsOneWidget);
    // Only drv-1 and drv-4 have outstanding dues.
    expect(find.text('Pay Driver'), findsNWidgets(2));
  });

  testWidgets('search filters by vehicle number', (tester) async {
    await pumpDrivers(tester);

    await tester.enterText(find.byType(TextField), 'TN57AZ8819');
    await tester.pumpAndSettle();

    expect(find.text('M. Murugesan'), findsOneWidget);
    expect(find.text('K. Selvaraj'), findsNothing);
  });

  testWidgets('tapping Pay Driver navigates with the driverId query param', (tester) async {
    await pumpDrivers(tester);

    await tester.tap(find.text('Pay Driver').first);
    await tester.pumpAndSettle();

    expect(find.text('Pay Truck Driver'), findsOneWidget);
    expect(find.text('K. Selvaraj'), findsWidgets);
  });

  testWidgets('Add Driver navigates to the register form and saving registers a new driver', (tester) async {
    await pumpDrivers(tester);

    await tester.tap(find.text('Add Driver'));
    await tester.pumpAndSettle();

    expect(find.text('Register Truck Driver'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'New Test Driver');
    await tester.enterText(find.byType(TextField).at(1), '9999900000');
    await tester.enterText(find.byType(TextField).at(2), 'mh12ab3456');
    await tester.pumpAndSettle();

    final before = driversBox.length;
    await tester.tap(find.text('Save Driver Details'));
    await tester.pumpAndSettle();

    expect(driversBox.length, before + 1);
    final saved = driversBox.values.firstWhere((d) => d.name == 'New Test Driver');
    expect(saved.vehicleNumber, 'MH12AB3456');
    expect(find.text('Truck Drivers Ledger'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // flush saveDriver's toast timer
  });

  testWidgets('validation blocks an empty vehicle number with a warning toast', (tester) async {
    await pumpDrivers(tester);

    await tester.tap(find.text('Add Driver'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Name Only Driver');
    await tester.pumpAndSettle();

    final before = driversBox.length;
    await tester.tap(find.text('Save Driver Details'));
    await tester.pumpAndSettle();

    expect(driversBox.length, before);
    expect(find.text('Vehicle number is required'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });
}
