import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'router/app_router.dart';
import 'services/backup_background_task.dart';
import 'storage/hive_boxes.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  try {
    await Workmanager().initialize(backupCallbackDispatcher);
  } catch (_) {
    // Registers the periodic Google Drive backup task's entry point. Never
    // fatal — the app is fully usable without background auto-sync (manual
    // "Sync Now" in Settings doesn't depend on this).
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Transport Ledger',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
