// Screenshots of every screen, in light and dark mode, at 1280 x 800.
//
// Skipped in a normal `flutter test` run, because tiny font-rendering
// differences between machines would make them fail. Generate or refresh
// them with:
//
//   flutter test test/screenshots --update-goldens
//
// The images land in test/screenshots/goldens/. Useful for reviewing the UI
// and for the class report.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show testWidgets;
import 'package:bytestreak/domain/models.dart';

import '../helpers.dart';

void testWidgets(String name, WidgetTesterCallback body) => ft.testWidgets(name, body, skip: !autoUpdateGoldenFiles);

Future<void> shot(WidgetTester tester, String name) async {
  await settle(tester, 12);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first);
  await settle(tester);
}

void main() {
  for (final theme in [ThemePreference.light, ThemePreference.dark]) {
    final t = theme.name;
    final settings = AppSettings(theme: theme, reduceMotion: true);

    group(t, () {
      for (final (route, name) in [
        ('/welcome', '01_onboarding'),
        ('/signup', '02_signup_step1'),
        ('/login', '13_login'),
      ]) {
        testWidgets(name, (tester) async {
          await pumpApp(tester, location: route, signedIn: false, settings: settings);
          await shot(tester, '${name}_$t');
        });
      }

      testWidgets('02b_signup_step2', (tester) async {
        await pumpApp(tester, location: '/signup', signedIn: false, settings: settings);
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'fresh_coder');
        await tester.enterText(fields.at(1), 'fresh@example.com');
        await tester.enterText(fields.at(2), 'supersecret');
        await tester.pump(const Duration(milliseconds: 400));
        await tap(tester, find.text('Continue'));
        await tap(tester, find.text('Intermediate'));
        await tap(tester, find.text('Daily habit'));
        await shot(tester, '02b_signup_step2_$t');
      });

      for (final (route, name) in [
        ('/home', '03_home'),
        ('/quiz/trees-quiz', '04_quiz_intro'),
        ('/play/arrays-1?mode=lesson', '05_mcq'),
        ('/achievements', '08_achievements'),
        ('/leaderboard', '09_leaderboard'),
        ('/stats', '10_stats'),
        ('/settings', '11_settings'),
        ('/profile', '12_profile'),
      ]) {
        testWidgets(name, (tester) async {
          await pumpApp(tester, location: route, settings: settings);
          await shot(tester, '${name}_$t');
        });
      }

      testWidgets('05b_mcq_feedback', (tester) async {
        await pumpApp(tester, location: '/play/arrays-1?mode=lesson', settings: settings);
        await tap(tester, find.text('O(n)'));
        await tap(tester, find.text('Check answer'));
        await shot(tester, '05b_mcq_wrong_$t');
      });

      testWidgets('06_code_editor', (tester) async {
        await pumpApp(tester, location: '/play/two-pointers-2?mode=lesson', settings: settings);
        await tap(tester, find.text('Detect a cycle'));
        await tap(tester, find.text('Check answer'));
        await tap(tester, find.text('Continue'));
        await tap(tester, find.text('Run'));
        await shot(tester, '06_code_editor_$t');
        await tap(tester, find.text('Submit'));
        await shot(tester, '06b_code_submitted_$t');
      });

      testWidgets('07_hints', (tester) async {
        await pumpApp(tester, location: '/play/arrays-1?mode=lesson', settings: settings);
        await tap(tester, find.text('Hint'));
        await tap(tester, find.text('Reveal · 10 XP'));
        await shot(tester, '07_hints_$t');
      });

      testWidgets('14_lesson_complete', (tester) async {
        await pumpApp(tester, location: '/play/trees-2?mode=lesson', settings: settings);
        await tap(tester, find.text('An empty (None) node'));
        await tap(tester, find.text('Check answer'));
        await tap(tester, find.text('Continue'));
        await tap(tester, find.text('Submit'));
        await tap(tester, find.text('Finish'));
        await shot(tester, '14_lesson_complete_$t');
      });

      testWidgets('15_out_of_hearts', (tester) async {
        await pumpApp(
          tester,
          location: '/play/trees-2?mode=lesson',
          settings: settings,
          editPlayer: (p) =>
              p.copyWith(hearts: 0, nextHeartAt: () => testNow.add(const Duration(minutes: 23, seconds: 41))),
        );
        await shot(tester, '15_out_of_hearts_$t');
      });

      testWidgets('16_badge_detail', (tester) async {
        await pumpApp(tester, location: '/achievements', settings: settings);
        await tap(tester, find.text('Week Warrior'));
        await shot(tester, '16_badge_detail_$t');
      });

      testWidgets('17_share_preview', (tester) async {
        await pumpApp(tester, location: '/profile', settings: settings);
        await tap(tester, find.text('Share progress'));
        await shot(tester, '17_share_preview_$t');
      });
    });
  }
}
