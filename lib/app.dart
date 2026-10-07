import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/router/app_router.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/state/settings_controller.dart';
import 'package:bytestreak/theme/app_theme.dart';

class ByteStreakApp extends ConsumerWidget {
  const ByteStreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    return MaterialApp.router(
      title: 'ByteStreak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.mode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
