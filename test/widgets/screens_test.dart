// Renders every screen at the design size and the minimum window size, in
// light and dark mode. Flutter reports layout overflows ("RenderFlex
// overflowed by N pixels") as errors, so these tests fail on any of them.

import 'package:flutter_test/flutter_test.dart';
import 'package:bytestreak/domain/models.dart';

import '../helpers.dart';

void main() {
  const signedInScreens = {
    '/home': 'Continue where you left off',
    '/achievements': 'earned',
    '/leaderboard': 'Leaderboard',
    '/stats': 'Topic mastery',
    '/settings': 'Appearance',
    '/profile': 'Recent activity',
    '/quiz/trees-quiz': 'Trees — Chapter quiz',
    '/play/arrays-1?mode=replay': 'Question 1 of 6',
  };
  const signedOutScreens = {'/welcome': 'ByteStreak', '/signup': 'Create your profile', '/login': 'Welcome back'};

  for (final size in [designSize, minimumSize]) {
    for (final theme in [ThemePreference.light, ThemePreference.dark]) {
      final label = '${size.width.toInt()}x${size.height.toInt()} ${theme.name}';
      final settings = AppSettings(theme: theme, reduceMotion: true);

      for (final MapEntry(key: route, value: expected) in signedInScreens.entries) {
        testWidgets('$route renders ($label)', (tester) async {
          await pumpApp(tester, location: route, size: size, settings: settings);
          expect(find.textContaining(expected), findsWidgets);
        });
      }

      for (final MapEntry(key: route, value: expected) in signedOutScreens.entries) {
        testWidgets('$route renders signed out ($label)', (tester) async {
          await pumpApp(tester, location: route, signedIn: false, size: size, settings: settings);
          expect(find.textContaining(expected), findsWidgets);
        });
      }
    }
  }

  testWidgets('signed-out users are sent to the welcome screen', (tester) async {
    await pumpApp(tester, location: '/stats', signedIn: false);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('signed-in users skip the welcome screen', (tester) async {
    await pumpApp(tester, location: '/welcome');
    expect(find.text('Continue where you left off'), findsOneWidget);
  });

  testWidgets('sign-up step 2 without step 1 goes back to step 1', (tester) async {
    await pumpApp(tester, location: '/signup/details', signedIn: false);
    expect(find.text('Create your profile'), findsOneWidget);
  });

  testWidgets('the code editor screen renders at the minimum size', (tester) async {
    // Placeholder lessons are [MCQ, coding]: answer the MCQ to reach the editor.
    await pumpApp(tester, location: '/play/trees-2?mode=replay', size: minimumSize);
    await tester.tap(find.text('An empty (None) node'));
    await tester.pump();
    await tester.tap(find.text('Check answer'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Count Leaves'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
    expect(find.text('Test results'), findsOneWidget);
  });

  testWidgets('home with animations on still renders', (tester) async {
    await pumpApp(tester, settings: const AppSettings(reduceMotion: false));
    expect(find.text('START'), findsOneWidget);
  });
}
