import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bytestreak/app.dart';
import 'package:bytestreak/state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window: the design is 1280 x 800; below 1100 x 720 the two-column
  // screens get cramped, so that's the minimum.
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(title: 'ByteStreak', size: Size(1280, 800), minimumSize: Size(1100, 720), center: true),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  // Person B: replace AppServices.fake() with the real services.
  final services = AppServices.fake(latency: const Duration(milliseconds: 350));
  final overrides = await bootstrap(services);

  runApp(ProviderScope(overrides: overrides, child: const ByteStreakApp()));
}
