import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/main.dart';
import 'package:flutter_app/providers/backup_provider.dart';
import 'package:flutter_app/providers/profile_provider.dart';
import 'package:flutter_app/services/drive_backup_client.dart';
import 'package:flutter_app/storage/hive_boxes.dart';

import '../test_helpers/hive_test_env.dart';

class _FakeDriveBackupClient implements DriveBackupClient {
  @override
  Future<String> connect() async => 'trucker@example.com';

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> uploadBackup(String jsonContent) async {}

  @override
  Future<String?> downloadBackup() async => null;

  @override
  Future<bool> trySilentUpload(String jsonContent) async => true;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await openTestHive();
    await seedIfEmpty();
  });

  tearDown(() async {
    await closeTestHive(tempDir);
  });

  Future<GoRouter> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [driveBackupClientProvider.overrideWithValue(_FakeDriveBackupClient())],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;
    router.push('/settings');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('starts disconnected from Drive, matching a fresh install with no real session', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Not linked to Google Drive'), findsOneWidget);
    expect(find.text('Connect Drive'), findsOneWidget);
    expect(find.text('KALAVATHI SELVARAJ TRANSPORT'), findsOneWidget);
  });

  testWidgets('the Bank Accounts tile is the only "Manage" entry, and it opens Banks', (tester) async {
    await pumpSettings(tester);

    // Companies/Customers/Drivers tiles were removed from here — the Ledger
    // tabs are now the one place to browse and edit them (see
    // `_ManageRow`'s doc comment).
    expect(find.text('Companies'), findsNothing);
    expect(find.text('Customers'), findsNothing);
    expect(find.text('Drivers'), findsNothing);
    expect(find.text('Bank Accounts'), findsOneWidget);

    await tester.tap(find.text('Bank Accounts'));
    await tester.pumpAndSettle();

    expect(find.text('Your Bank Accounts'), findsOneWidget);
  });

  testWidgets('Connect Drive signs in and immediately syncs', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Connect Drive'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Connected as trucker@example.com'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // flush the sync-success toast timer
  });

  testWidgets('saving the profile form preserves tagline/state/accountName, which have no inputs', (tester) async {
    await pumpSettings(tester);

    await tester.enterText(find.widgetWithText(TextField, 'KALAVATHI SELVARAJ TRANSPORT'), 'New Transport Co');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    final saved = ProviderScope.containerOf(tester.element(find.text('Settings & Cloud Backup'))).read(profileProvider);
    expect(saved.businessName, 'New Transport Co');
    // Regression check for the source's TS-type-mismatch bug (SettingsScreen.tsx:57-73
    // omits tagline/state/accountName from the object it saves).
    expect(saved.tagline, 'Safe, Prompt Cotton Yarn & Bag Transport Service');
    expect(saved.state, 'Tamil Nadu');
    expect(saved.accountName, 'Kalavathi Selvaraj');
    expect(find.text('Saved'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // flush both the toast and the "Saved" reset timers
  });

}
