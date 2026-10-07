import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bytestreak/data/fake/fake_backend.dart';
import 'package:bytestreak/data/repositories.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/lesson_session.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/state/providers.dart';

/// A container with the fake backend, a controllable clock, and (optionally)
/// a fresh signed-in player instead of the demo account.
Future<({ProviderContainer c, void Function(Duration) advance})> setUpApp({bool fresh = true}) async {
  var now = DateTime(2026, 10, 7, 14, 30);
  final services = AppServices.fake(clock: () => now, signedIn: !fresh);
  final overrides = await bootstrap(services);
  final c = ProviderContainer(overrides: overrides);
  addTearDown(c.dispose);
  if (fresh) {
    await c
        .read(playerProvider.notifier)
        .signUp(
          const SignupDraft(
            username: 'newbie',
            email: 'newbie@example.com',
            password: 'password1',
            dailyGoal: DailyGoal.serious,
          ),
        );
  }
  return (c: c, advance: (Duration d) => now = now.add(d));
}

LessonSession sessionFor(ProviderContainer c, String lessonId, SessionMode mode) {
  final lesson = c.read(coursePathProvider).lesson(lessonId)!;
  return LessonSession(mode: mode, questions: lesson.questions, lesson: lesson);
}

void main() {
  test('sign-up creates a fresh player with full hearts and no XP', () async {
    final app = await setUpApp();
    final p = app.c.read(currentPlayerProvider);
    expect(p.profile.username, 'newbie');
    expect(p.profile.dailyGoal, DailyGoal.serious);
    expect(p.xp, 0);
    expect(p.hearts, GameRules.maxHearts);
  });

  test('a taken username is rejected', () async {
    final app = await setUpApp(fresh: false);
    await app.c.read(playerProvider.notifier).signOut();
    await expectLater(
      app.c
          .read(playerProvider.notifier)
          .signUp(const SignupDraft(username: demoUsername, email: 'x@y.com', password: 'password1')),
      throwsA(isA<AuthException>()),
    );
  });

  test('log in with the demo account, wrong password fails', () async {
    final app = await setUpApp();
    final ctrl = app.c.read(playerProvider.notifier);
    await ctrl.signOut();
    expect(app.c.read(signedInProvider), isFalse);
    await expectLater(ctrl.signIn(demoUsername, 'nope'), throwsA(isA<AuthException>()));
    await ctrl.signIn(demoEmail, demoPassword);
    expect(app.c.read(currentPlayerProvider).profile.username, demoUsername);
  });

  test('correct answers earn XP; wrong ones cost a heart and start the regen clock', () async {
    final app = await setUpApp();
    final ctrl = app.c.read(playerProvider.notifier);
    final s = sessionFor(app.c, 'arrays-1', SessionMode.lesson);

    final first = ctrl.answer(s, correct: true);
    expect(first.xpAwarded, s.questions[0].xpReward);
    expect(app.c.read(currentPlayerProvider).xp, first.xpAwarded);

    s.advance();
    final second = ctrl.answer(s, correct: false);
    expect(second.heartLost, isTrue);
    final p = app.c.read(currentPlayerProvider);
    expect(p.hearts, 4);
    expect(p.nextHeartAt, isNotNull);
    expect(p.answers.length, 2);
  });

  test('hearts regenerate over time', () async {
    final app = await setUpApp();
    final ctrl = app.c.read(playerProvider.notifier);
    final s = sessionFor(app.c, 'arrays-1', SessionMode.lesson);
    ctrl.answer(s, correct: false);
    expect(app.c.read(currentPlayerProvider).hearts, 4);
    app.advance(GameRules.heartRegen);
    ctrl.tick();
    expect(app.c.read(currentPlayerProvider).hearts, 5);
  });

  test('review, practice and replay never cost hearts or award XP', () async {
    final app = await setUpApp();
    final ctrl = app.c.read(playerProvider.notifier);
    for (final mode in [SessionMode.review, SessionMode.practice, SessionMode.replay]) {
      final s = sessionFor(app.c, 'arrays-1', mode);
      expect(ctrl.answer(s, correct: true).xpAwarded, 0);
      s.advance();
      expect(ctrl.answer(s, correct: false).heartLost, isFalse);
    }
    final p = app.c.read(currentPlayerProvider);
    expect(p.xp, 0);
    expect(p.hearts, GameRules.maxHearts);
  });

  test('viewing the solution makes the question worth 0 XP', () async {
    final app = await setUpApp();
    final ctrl = app.c.read(playerProvider.notifier);
    final s = sessionFor(app.c, 'arrays-1', SessionMode.lesson);
    ctrl.viewSolution(s.current);
    expect(ctrl.answer(s, correct: true).xpAwarded, 0);
  });

  test('hints cost 10 XP in lessons, are free in review, and need enough XP', () async {
    final app = await setUpApp();
    final ctrl = app.c.read(playerProvider.notifier);
    final s = sessionFor(app.c, 'arrays-1', SessionMode.lesson);
    final q = s.current;

    expect(ctrl.revealHint(q, SessionMode.lesson), isFalse, reason: 'a new player has 0 XP');
    expect(ctrl.revealHint(q, SessionMode.review), isTrue, reason: 'free outside XP modes');

    ctrl.answer(s, correct: true); // earns some XP
    final xp = app.c.read(currentPlayerProvider).xp;
    expect(ctrl.revealHint(q, SessionMode.lesson), isTrue);
    expect(app.c.read(currentPlayerProvider).xp, xp - GameRules.hintCost);
    expect(app.c.read(currentPlayerProvider).progressOf(q.id).hintsRevealed, 2);
    expect(ctrl.revealHint(q, SessionMode.lesson), isFalse, reason: 'no hints left');
  });

  test('refilling hearts costs 120 XP and can drop your level', () async {
    final app = await setUpApp(fresh: false); // demo: 2480 XP
    final ctrl = app.c.read(playerProvider.notifier);
    final before = app.c.read(currentPlayerProvider);
    expect(ctrl.refillHearts(), isTrue);
    final after = app.c.read(currentPlayerProvider);
    expect(after.xp, before.xp - GameRules.heartRefillCost);
    expect(after.hearts, GameRules.maxHearts);
    expect(after.nextHeartAt, isNull);
  });

  test('refill fails without enough XP', () async {
    final app = await setUpApp();
    expect(app.c.read(playerProvider.notifier).refillHearts(), isFalse);
  });

  test('finishing a lesson completes it, adds the bonus, starts the streak and earns First Spark', () async {
    final app = await setUpApp();
    final ctrl = app.c.read(playerProvider.notifier);
    final s = sessionFor(app.c, 'arrays-1', SessionMode.lesson);
    var answerXp = 0;
    while (true) {
      answerXp += ctrl.answer(s, correct: true).xpAwarded;
      if (!s.advance()) break;
    }
    final result = ctrl.finishSession(s);
    final p = app.c.read(currentPlayerProvider);

    expect(p.completedLessons, contains('arrays-1'));
    expect(result.xpEarned, answerXp + GameRules.lessonBonus);
    expect(p.xp, answerXp + GameRules.lessonBonus);
    expect(p.streak, 1);
    expect(result.streak, 1);
    expect(result.newAchievements, contains('First Spark'));
    expect(p.achievements.keys, contains('first_spark'));
    expect(result.dailyGoalDone, s.questions.length);
    expect(result.dailyGoalTarget, DailyGoal.serious.questions);
    expect(app.c.read(pathProgressProvider).current?.id, 'arrays-2');
  });

  test('passing a chapter quiz unlocks the next chapter; failing it does not', () async {
    final app = await setUpApp();
    final ctrl = app.c.read(playerProvider.notifier);

    final fail = sessionFor(app.c, 'arrays-quiz', SessionMode.quiz);
    while (true) {
      ctrl.answer(fail, correct: fail.index.isEven); // 50%: below the 80% pass mark
      if (!fail.advance()) break;
    }
    expect(ctrl.finishSession(fail).passedQuiz, isFalse);
    expect(app.c.read(currentPlayerProvider).passedQuizzes, isEmpty);

    final pass = sessionFor(app.c, 'arrays-quiz', SessionMode.quiz);
    while (true) {
      ctrl.answer(pass, correct: true);
      if (!pass.advance()) break;
    }
    final result = ctrl.finishSession(pass);
    expect(result.passedQuiz, isTrue);
    final progress = app.c.read(pathProgressProvider);
    expect(progress.current?.id, 'hashing-1');
  });

  test('practice earns one heart', () async {
    final app = await setUpApp(fresh: false); // demo player: 4 hearts
    final ctrl = app.c.read(playerProvider.notifier);
    final questions = ctrl.practiceQuestions();
    expect(questions.length, GameRules.practiceSize);
    final s = LessonSession(mode: SessionMode.practice, questions: questions);
    while (true) {
      ctrl.answer(s, correct: true);
      if (!s.advance()) break;
    }
    ctrl.finishSession(s);
    expect(app.c.read(currentPlayerProvider).hearts, 5);
  });

  test('reaching the top 10 earns the Gold League badge', () async {
    final app = await setUpApp(fresh: false);
    final ctrl = app.c.read(playerProvider.notifier);
    expect(app.c.read(currentPlayerProvider).achievements.containsKey('gold_league'), isFalse);
    ctrl.recordRank(6);
    expect(app.c.read(currentPlayerProvider).achievements.containsKey('gold_league'), isTrue);
  });

  test('the leaderboard ranks the demo player 6th (Gold) and hides them when sharing is off', () async {
    final app = await setUpApp(fresh: false);
    final page = await app.c.read(leaderboardProvider.future);
    expect(page.myRank, 6);
    expect(app.c.read(leagueProvider), League.gold);

    app.c.read(settingsProvider.notifier).setShareStats(false);
    final hidden = await app.c.read(leaderboardProvider.future);
    expect(hidden.myRank, isNull);
    expect(hidden.entries.any((e) => e.isMe), isFalse);
  });

  test('the fake code runner fails untouched starter code and passes edited code', () async {
    final app = await setUpApp();
    final runner = app.c.read(servicesProvider).codeRunner;
    final q = app.c.read(coursePathProvider).question('arr-1-5')! as CodingQuestion;
    final starter = await runner.run(
      question: q,
      language: 'python',
      code: q.starterCode['python']!,
      includeHidden: false,
    );
    expect(starter.allPassed, isFalse);
    expect(starter.results.length, q.testCases.where((t) => !t.hidden).length);
    final solved = await runner.run(question: q, language: 'python', code: q.solution, includeHidden: true);
    expect(solved.allPassed, isTrue);
    expect(solved.results.length, q.testCases.length);
  });
}
