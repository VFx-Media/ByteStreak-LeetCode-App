import 'package:flutter_test/flutter_test.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';

void main() {
  final now = DateTime(2026, 10, 7, 14, 30);

  group('levels', () {
    test('start at level 1 and follow 60 * (L-1)^2', () {
      expect(GameRules.levelForXp(0), 1);
      expect(GameRules.levelForXp(59), 1);
      expect(GameRules.levelForXp(60), 2);
      expect(GameRules.levelForXp(240), 3);
      expect(GameRules.levelForXp(2480), 7); // the design's example
    });

    test('drop when XP is spent (plan: one XP number)', () {
      expect(GameRules.levelForXp(2160), 7);
      expect(GameRules.levelForXp(2160 - GameRules.heartRefillCost), 6);
    });

    test('progress runs 0..1 within a level', () {
      expect(GameRules.levelProgress(60), 0);
      expect(GameRules.levelProgress(150), closeTo(0.5, 0.001));
    });
  });

  group('leagues come from rank', () {
    test('cut-offs', () {
      expect(GameRules.leagueForRank(1), League.gold);
      expect(GameRules.leagueForRank(10), League.gold);
      expect(GameRules.leagueForRank(11), League.silver);
      expect(GameRules.leagueForRank(50), League.silver);
      expect(GameRules.leagueForRank(51), League.bronze);
      expect(GameRules.leagueForRank(null), League.unranked);
    });
  });

  group('hearts', () {
    test('losing the first heart starts the 30-minute clock', () {
      final r = GameRules.loseHeart(hearts: 5, nextHeartAt: null, now: now);
      expect(r.hearts, 4);
      expect(r.nextHeartAt, now.add(GameRules.heartRegen));
    });

    test('losing more hearts keeps the existing clock', () {
      final clock = now.add(const Duration(minutes: 10));
      final r = GameRules.loseHeart(hearts: 3, nextHeartAt: clock, now: now);
      expect(r.hearts, 2);
      expect(r.nextHeartAt, clock);
    });

    test('never goes below zero', () {
      expect(GameRules.loseHeart(hearts: 0, nextHeartAt: now, now: now).hearts, 0);
    });

    test('regenerate one per 30 minutes, then stop at full', () {
      final start = now;
      var r = GameRules.regenerate(hearts: 2, nextHeartAt: start, now: start.subtract(const Duration(minutes: 1)));
      expect(r.hearts, 2);
      r = GameRules.regenerate(hearts: 2, nextHeartAt: start, now: start);
      expect(r.hearts, 3);
      expect(r.nextHeartAt, start.add(GameRules.heartRegen));
      r = GameRules.regenerate(hearts: 2, nextHeartAt: start, now: start.add(const Duration(hours: 5)));
      expect(r.hearts, GameRules.maxHearts);
      expect(r.nextHeartAt, isNull);
    });
  });

  group('xp for an answer', () {
    const q = McqQuestion(
      id: 'q',
      difficulty: Difficulty.medium,
      prompt: '?',
      hints: [],
      solution: '',
      xpReward: 15,
      topic: 'Arrays',
      options: ['a', 'b'],
      correctIndex: 0,
    );

    test('correct answers in XP modes earn the reward', () {
      expect(GameRules.xpForAnswer(question: q, correct: true, solutionViewed: false, awardsXp: true), 15);
    });

    test('wrong answers, viewed solutions and practice modes earn nothing', () {
      expect(GameRules.xpForAnswer(question: q, correct: false, solutionViewed: false, awardsXp: true), 0);
      expect(GameRules.xpForAnswer(question: q, correct: true, solutionViewed: true, awardsXp: true), 0);
      expect(GameRules.xpForAnswer(question: q, correct: true, solutionViewed: false, awardsXp: false), 0);
    });

    test('default rewards: coding is worth more than MCQ', () {
      expect(GameRules.defaultXpReward(QuestionType.mcq, Difficulty.easy), 10);
      expect(GameRules.defaultXpReward(QuestionType.coding, Difficulty.medium), 25);
    });
  });

  group('streaks', () {
    final today = GameRules.dayOf(now);
    final yesterday = today.subtract(const Duration(days: 1));

    test('first practice starts a streak of 1', () {
      expect(GameRules.recordPractice(streak: 0, lastPracticeDay: null, now: now).streak, 1);
    });

    test('practising again the same day changes nothing', () {
      expect(GameRules.recordPractice(streak: 5, lastPracticeDay: today, now: now).streak, 5);
    });

    test('practising the next day extends it', () {
      expect(GameRules.recordPractice(streak: 5, lastPracticeDay: yesterday, now: now).streak, 6);
    });

    test('missing a day resets to 1', () {
      final r = GameRules.recordPractice(streak: 5, lastPracticeDay: today.subtract(const Duration(days: 2)), now: now);
      expect(r.streak, 1);
    });

    test('the displayed streak survives until the end of the next day', () {
      expect(GameRules.effectiveStreak(streak: 12, lastPracticeDay: yesterday, now: now), 12);
      expect(
        GameRules.effectiveStreak(streak: 12, lastPracticeDay: today.subtract(const Duration(days: 2)), now: now),
        0,
      );
    });
  });
}
