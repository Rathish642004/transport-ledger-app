import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/seed_data.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/providers/backup_provider.dart';
import 'package:flutter_app/services/drive_backup_client.dart';
import 'package:flutter_app/storage/hive_boxes.dart';
import 'package:flutter_app/storage/storage_keys.dart';

import '../test_helpers/hive_test_env.dart';

class _FakeDriveBackupClient implements DriveBackupClient {
  _FakeDriveBackupClient({this.backupJson});

  /// What `downloadBackup` returns — `null` simulates a brand-new Google
  /// account with nothing uploaded yet.
  final String? backupJson;

  @override
  Future<String> connect() async => 'trucker@example.com';

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> uploadBackup(String jsonContent) async {}

  @override
  Future<String?> downloadBackup() async => backupJson;

  @override
  Future<bool> trySilentUpload(String jsonContent) async => true;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await openTestHive();
    // Deliberately do NOT seed `profileBox` — that emptiness is exactly what
    // the router's redirect (`app_router.dart`) uses to route to onboarding.
    // `backupBox` still needs a value, same as `initHive` seeds it
    // unconditionally in the real app.
    await backupBox.put(StorageKeys.singleValueKey, initialBackupSettings);
  });

  tearDown(() async {
    await closeTestHive(tempDir);
  });

  Future<void> pumpApp(WidgetTester tester, {DriveBackupClient? driveClient}) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        if (driveClient != null) driveBackupClientProvider.overrideWithValue(driveClient),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty profile box routes to onboarding instead of the dashboard', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome to Transport Ledger'), findsOneWidget);
    expect(find.text('Connect Google Drive'), findsOneWidget);
    expect(find.text('Continue without Google Drive'), findsOneWidget);
  });

  testWidgets('continuing without Drive collects a profile and lands on the dashboard', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Continue without Google Drive'));
    await tester.pumpAndSettle();

    expect(find.text('Set up your business profile'), findsOneWidget);

    // "Business Name *" is the first field on the form.
    await tester.enterText(find.byType(TextField).first, 'Acme Transport');
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Onboarding is gone, and the router won't route back to it now that a
    // profile exists — the Dashboard renders it as the business name.
    expect(find.text('Welcome to Transport Ledger'), findsNothing);
    expect(find.text('Acme Transport'), findsOneWidget);
    expect(profileBox.get(StorageKeys.singleValueKey)?.businessName, 'Acme Transport');
  });

  testWidgets('entering the profile form without a business name shows a validation error', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue without Google Drive'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Business name is required.'), findsOneWidget);
    // Still on onboarding — nothing was saved.
    expect(profileBox.isEmpty, isTrue);
  });

  testWidgets('connecting Drive and finding an existing backup with a profile skips the form entirely', (tester) async {
    final backupJson = jsonEncode({
      'orders': <dynamic>[],
      'profile': initialProfile.toJson(),
    });
    await pumpApp(tester, driveClient: _FakeDriveBackupClient(backupJson: backupJson));

    // `restoreBackupFromJSON`'s real (non-fake) Hive disk I/O needs the real
    // event loop, not the fake-time zone `testWidgets` normally runs under
    // (see `hive_test_env.dart`'s doc comment for the same class of issue) —
    // `runAsync` steps outside that zone for the tap and its async fallout.
    // The restore also shows a toast whose 3.8s auto-dismiss timer is created
    // in that same real-time zone, so it's waited out here too rather than
    // via a later `tester.pump()` (a *fake*-time advance, which wouldn't
    // touch it) — otherwise it fires during a later test's run instead.
    await tester.runAsync(() async {
      await tester.tap(find.text('Connect Google Drive'));
      await Future<void>.delayed(const Duration(milliseconds: 4000));
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('Set up your business profile'), findsNothing);
    expect(find.text(initialProfile.businessName), findsOneWidget);
    expect(profileBox.get(StorageKeys.singleValueKey)?.businessName, initialProfile.businessName);
  });

  testWidgets('connecting Drive with no existing backup falls through to the profile form', (tester) async {
    await pumpApp(tester, driveClient: _FakeDriveBackupClient(backupJson: null));

    await tester.tap(find.text('Connect Google Drive'));
    await tester.pumpAndSettle();

    expect(find.text('Set up your business profile'), findsOneWidget);
    // Connected, just with nothing to restore yet.
    expect(profileBox.isEmpty, isTrue);
  });
}
