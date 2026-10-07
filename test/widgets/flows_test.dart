// End-to-end journeys through the real UI: tapping buttons, typing, and
// checking what appears, with the fake backend behind it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bytestreak/data/fake/fake_backend.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/state/providers.dart';

import '../helpers.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).first;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await settle(tester);
}

/// Answers whatever question is showing: picks option A for multiple choice,
/// or submits the starter code (which the fake runner fails) for coding.
Future<void> answerAndContinue(WidgetTester tester) async {
  if (find.text('Check answer').evaluate().isNotEmpty) {
    await tester.tap(find.text('A').first);
    await tester.pump();
    await tapText(tester, 'Check answer');
  } else {
    await tapText(tester, 'Submit');
  }
  final next = find.text('Continue').evaluate().isNotEmpty ? 'Continue' : 'Finish';
  await tapText(tester, next);
}

void main() {
  group('accounts', () {
    testWidgets('sign up in two steps lands on Home with a fresh player', (tester) async {
      final app = await pumpApp(tester, location: '/welcome', signedIn: false);
      await tapText(tester, 'Get Started');
      expect(find.text('Step 1 of 2'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'fresh_coder');
      await tester.pump(const Duration(milliseconds: 400)); // username check debounce
      await tester.enterText(fields.at(1), 'fresh@example.com');
      await tester.enterText(fields.at(2), 'supersecret');
      await settle(tester);
      expect(find.text('✓ available'), findsOneWidget);

      await tapText(tester, 'Continue');
      expect(find.text('Step 2 of 2'), findsOneWidget);
      await tapText(tester, 'Advanced');
      await tapText(tester, 'Interview prep');
      await tapText(tester, 'Intense');
      await tapText(tester, 'Create account');

      expect(find.text('Continue where you left off'), findsOneWidget);
      expect(find.text('Array basics'), findsWidgets);
      expect(app.player.xp, 0);
      expect(app.player.profile.experienceLevel, ExperienceLevel.advanced);
      expect(app.player.profile.dailyGoal, DailyGoal.intense);
      expect(app.player.profile.goals, contains('Interview prep'));
    });

    testWidgets('sign-up shows validation errors and spots taken usernames', (tester) async {
      await pumpApp(tester, location: '/signup', signedIn: false);
      await tapText(tester, 'Continue');
      expect(find.text('Pick a username'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Choose a password'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), demoUsername);
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      expect(find.text('That username is taken'), findsOneWidget);
    });

    testWidgets('"Skip for now" creates the account with default settings', (tester) async {
      final app = await pumpApp(tester, location: '/signup', signedIn: false);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'skipper');
      await tester.enterText(fields.at(1), 'skip@example.com');
      await tester.enterText(fields.at(2), 'supersecret');
      await tester.pump(const Duration(milliseconds: 400));
      await tapText(tester, 'Skip for now');
      expect(find.text('Continue where you left off'), findsOneWidget);
      expect(app.player.profile.dailyGoal, DailyGoal.regular);
    });

    testWidgets('log in: wrong password shows an error, right one goes Home', (tester) async {
      await pumpApp(tester, location: '/login', signedIn: false);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), demoUsername);
      await tester.enterText(fields.at(1), 'wrong');
      await tapText(tester, 'Log in');
      expect(find.text('That password isn\'t right.'), findsOneWidget);

      await tester.enterText(fields.at(1), demoPassword);
      await tapText(tester, 'Log in');
      expect(find.text('Continue where you left off'), findsOneWidget);
    });

    testWidgets('log out from Settings returns to the welcome screen', (tester) async {
      await pumpApp(tester, location: '/settings');
      final logOut = find.widgetWithText(OutlinedButton, 'Log out');
      await tester.ensureVisible(logOut);
      await tester.pump();
      await tester.tap(logOut);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await settle(tester);
      expect(find.text('Get Started'), findsOneWidget);
    });
  });

  group('lessons', () {
    testWidgets('play a lesson, review the mistake, and the path moves on', (tester) async {
      final app = await pumpApp(tester);
      final xpBefore = app.player.xp;

      // Demo player's current lesson: Trees · Recursion on trees (MCQ, then coding).
      await tapText(tester, 'Continue');
      expect(find.text('Question 1 of 2'), findsOneWidget);

      await tester.tap(find.text('An empty (None) node'));
      await tester.pump();
      await tapText(tester, 'Check answer');
      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('+10 XP'), findsOneWidget);
      await tapText(tester, 'Continue');

      // Coding: the untouched starter code fails, which costs a heart.
      expect(find.text('Count Leaves'), findsOneWidget);
      await tapText(tester, 'Run');
      expect(find.textContaining('expected 2, got None'), findsOneWidget);
      await tapText(tester, 'Submit');
      expect(find.text('0 of 2 tests passed'), findsOneWidget);
      expect(find.text('−1 heart'), findsOneWidget);
      await tapText(tester, 'Finish');

      expect(find.text('Lesson complete!'), findsOneWidget);
      expect(find.text('PASS'), findsOneWidget);
      expect(find.text('MISS'), findsOneWidget);
      expect(app.player.xp, xpBefore + 10 + GameRules.lessonBonus);
      expect(app.player.hearts, 3);
      expect(app.player.completedLessons, contains('trees-2'));

      // Review mistakes replays only the coding question, for free.
      await tapText(tester, 'Review 1 mistake');
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Count Leaves'), findsOneWidget);
      await tapText(tester, 'Submit');
      expect(find.text('−1 heart'), findsNothing);
      await tapText(tester, 'Finish');
      expect(find.text('Review complete'), findsOneWidget);
      expect(app.player.hearts, 3);

      await tapText(tester, 'Continue');
      expect(find.text('Trees quiz'), findsOneWidget, reason: 'the chapter quiz is now current');
    });

    testWidgets('keyboard: number keys pick an option and Enter checks', (tester) async {
      await pumpApp(tester, location: '/play/trees-2?mode=lesson');
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.text('Correct!'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.text('Count Leaves'), findsOneWidget);
    });

    testWidgets('a wrong MCQ answer shows the right one', (tester) async {
      await pumpApp(tester, location: '/play/trees-2?mode=lesson');
      await tester.tap(find.text('The root'));
      await tester.pump();
      await tapText(tester, 'Check answer');
      expect(find.text('Not quite'), findsOneWidget);
      expect(find.textContaining('Answer: A.'), findsOneWidget);
    });

    testWidgets('hints cost 10 XP each and stay revealed', (tester) async {
      final app = await pumpApp(tester, location: '/play/arrays-1?mode=lesson');
      final xp = app.player.xp;
      await tapText(tester, 'Hint');
      expect(find.text('Need a nudge?'), findsOneWidget);
      await tapText(tester, 'Reveal · 10 XP');
      expect(find.text('Arrays store elements next to each other in memory.'), findsOneWidget);
      expect(app.player.xp, xp - GameRules.hintCost);
      await tester.tap(find.byTooltip('Close (Esc)'));
      await settle(tester);
      expect(find.text('Need a nudge?'), findsNothing);
    });

    testWidgets('viewing a coding solution warns about XP, then shows it', (tester) async {
      final app = await pumpApp(tester, location: '/play/trees-2?mode=lesson');
      await tester.tap(find.text('An empty (None) node'));
      await tester.pump();
      await tapText(tester, 'Check answer');
      await tapText(tester, 'Continue');
      await tapText(tester, 'View solution');
      expect(find.textContaining('will then earn 0 XP'), findsOneWidget);
      await tapText(tester, 'Show solution');
      expect(find.textContaining('def count_leaves'), findsOneWidget);
      expect(app.player.progressOf('tree-2-2').solutionViewed, isTrue);
    });

    testWidgets('quitting mid-lesson asks first', (tester) async {
      await pumpApp(tester);
      await tapText(tester, 'Continue');
      await tester.tap(find.text('An empty (None) node'));
      await tester.pump();
      await tapText(tester, 'Check answer');
      await tester.tap(find.byTooltip('Quit (Esc)'));
      await settle(tester);
      expect(find.text('Quit this lesson?'), findsOneWidget);
      await tapText(tester, 'Quit');
      expect(find.text('Continue where you left off'), findsOneWidget);
    });

    testWidgets('chapter quiz intro starts the quiz', (tester) async {
      await pumpApp(tester, location: '/quiz/trees-quiz');
      expect(find.textContaining('Wrong answers cost a heart. You have 4 left.'), findsOneWidget);
      await tapText(tester, 'Start quiz');
      expect(find.textContaining('Question 1 of'), findsOneWidget);
    });
  });

  group('hearts', () {
    PlayerState noHearts(PlayerState p) =>
        p.copyWith(hearts: 0, nextHeartAt: () => testNow.add(const Duration(minutes: 12)));

    testWidgets('starting with no hearts offers a refill, which costs 120 XP', (tester) async {
      final app = await pumpApp(tester, location: '/play/trees-2?mode=lesson', editPlayer: noHearts);
      expect(find.text('You\'re out of hearts'), findsOneWidget);
      expect(find.text('Next heart in 12:00'), findsOneWidget);
      final xp = app.player.xp;
      await tapText(tester, 'Refill now');
      expect(find.text('You\'re out of hearts'), findsNothing);
      expect(app.player.hearts, GameRules.maxHearts);
      expect(app.player.xp, xp - GameRules.heartRefillCost);
      expect(find.text('Question 1 of 2'), findsOneWidget);
    });

    testWidgets('practising earns a heart back', (tester) async {
      final app = await pumpApp(tester, location: '/play/trees-2?mode=lesson', editPlayer: noHearts);
      await tapText(tester, 'Practice to earn a heart');
      expect(find.text('Practice'), findsOneWidget);
      for (var i = 0; i < GameRules.practiceSize; i++) {
        await answerAndContinue(tester);
      }
      expect(find.text('+1 heart earned!'), findsOneWidget);
      expect(app.player.hearts, 1);
    });

    testWidgets('"Back to home" leaves the lesson', (tester) async {
      await pumpApp(tester, location: '/play/trees-2?mode=lesson', editPlayer: noHearts);
      await tapText(tester, 'Back to home');
      expect(find.text('Continue where you left off'), findsOneWidget);
    });
  });

  group('other screens', () {
    testWidgets('top bar theme button switches to dark mode', (tester) async {
      await pumpApp(tester);
      expect(Theme.of(tester.element(find.text('Continue where you left off'))).brightness, Brightness.light);
      await tester.tap(find.byTooltip('Switch to dark mode'));
      await settle(tester);
      expect(Theme.of(tester.element(find.text('Continue where you left off'))).brightness, Brightness.dark);
    });

    testWidgets('nav rail moves between the main screens', (tester) async {
      await pumpApp(tester);
      for (final (label, title) in [
        ('Badges', 'Achievements'),
        ('Ranks', 'Leaderboard'),
        ('Stats', 'Your stats'),
        ('Settings', 'Settings'),
      ]) {
        await tapText(tester, label);
        expect(find.text(title), findsWidgets);
      }
      await tester.tap(find.byTooltip('Profile'));
      await settle(tester);
      expect(find.text('Recent activity'), findsOneWidget);
    });

    testWidgets('badge detail shows the next tier', (tester) async {
      await pumpApp(tester, location: '/achievements');
      await tapText(tester, 'Week Warrior');
      expect(find.text('Achievement'), findsOneWidget);
      expect(find.text('Next: Century'), findsOneWidget);
    });

    testWidgets('leaderboard ranks you 6th in Gold and unlocks the Gold League badge', (tester) async {
      final app = await pumpApp(tester, location: '/leaderboard');
      expect(find.textContaining('You\'re #6 of'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(app.player.achievements.containsKey('gold_league'), isTrue);
    });

    testWidgets('hiding your stats removes you from the leaderboard', (tester) async {
      final app = await pumpApp(tester, location: '/leaderboard');
      app.container.read(settingsProvider.notifier).setShareStats(false);
      await settle(tester);
      expect(find.textContaining('hidden from the leaderboard'), findsOneWidget);
      expect(find.text('You'), findsNothing);
    });

    testWidgets('share preview renders the story card', (tester) async {
      await pumpApp(tester, location: '/profile');
      await tapText(tester, 'Share progress');
      expect(find.text('Share your progress'), findsOneWidget);
      expect(find.text('@$demoUsername'), findsOneWidget);
      expect(find.text('Save image'), findsOneWidget);
    });

    testWidgets('edit profile changes the username', (tester) async {
      final app = await pumpApp(tester, location: '/profile');
      await tapText(tester, 'Edit profile');
      await tester.enterText(find.byType(TextFormField), 'renamed_dev');
      await tapText(tester, 'Save');
      expect(app.player.profile.username, 'renamed_dev');
      expect(find.text('renamed_dev'), findsOneWidget);
    });

    testWidgets('Stats "Practise" button jumps to that chapter on Home', (tester) async {
      await pumpApp(tester, location: '/stats');
      await tester.tap(find.textContaining('Practise '));
      await settle(tester);
      expect(find.text('Continue where you left off'), findsOneWidget);
    });

    testWidgets('changing the daily goal in Settings updates the profile', (tester) async {
      final app = await pumpApp(tester, location: '/settings');
      await tester.tap(find.text('Serious'));
      await settle(tester);
      await tester.tap(find.text('Casual').last);
      await settle(tester);
      expect(app.player.profile.dailyGoal, DailyGoal.casual);
    });
  });
}
