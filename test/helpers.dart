import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bytestreak/app.dart';
import 'package:bytestreak/data/fake/fake_backend.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/router/app_router.dart';
import 'package:bytestreak/state/providers.dart';

/// Every widget test runs at this fixed moment, so hearts, streaks and
/// "time ago" labels are deterministic.
final testNow = DateTime(2026, 10, 7, 14, 30);
DateTime testClock() => testNow;

const designSize = Size(1280, 800);
const minimumSize = Size(1100, 720);

class TestApp {
  TestApp(this.container);
  final ProviderContainer container;

  PlayerState get player => container.read(currentPlayerProvider);

  Future<void> go(WidgetTester tester, String location) async {
    container.read(routerProvider).go(location);
    await settle(tester);
  }
}

/// Pumps frames until transitions finish. Not `pumpAndSettle`: a few
/// widgets repeat forever (e.g. the current node's pulse) and would hang it.
Future<void> settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Starts the whole app (router, theme, fake backend) at [location].
Future<TestApp> pumpApp(
  WidgetTester tester, {
  String location = '/home',
  bool signedIn = true,
  Size size = designSize,
  AppSettings settings = const AppSettings(reduceMotion: true),
  PlayerState Function(PlayerState p)? editPlayer,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final services = AppServices.fake(clock: testClock, signedIn: signedIn, settings: settings);
  final path = await services.content.loadPath();
  var player = signedIn ? await services.players.load(demoUserId) : null;
  if (player != null && editPlayer != null) {
    player = editPlayer(player);
    await services.players.save(player);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        servicesProvider.overrideWithValue(services),
        coursePathProvider.overrideWithValue(path),
        initialSettingsProvider.overrideWithValue(settings),
        initialPlayerProvider.overrideWithValue(player),
      ],
      child: const ByteStreakApp(),
    ),
  );
  final app = TestApp(ProviderScope.containerOf(tester.element(find.byType(ByteStreakApp))));
  await settle(tester);
  if (location != '/home') await app.go(tester, location);
  return app;
}
