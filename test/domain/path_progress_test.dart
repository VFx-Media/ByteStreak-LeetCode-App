import 'package:flutter_test/flutter_test.dart';
import 'package:bytestreak/data/fake/fake_content.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/lesson_session.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/domain/path_progress.dart';

PlayerState player({Set<String> done = const {}, Set<String> passed = const {}}) {
  return PlayerState.fresh(
    Profile(
      userId: 'u',
      username: 'u',
      email: 'u@x.com',
      avatarIndex: 0,
      experienceLevel: ExperienceLevel.beginner,
      goals: const {},
      dailyGoal: DailyGoal.regular,
      memberSince: DateTime(2026),
    ),
  ).copyWith(completedLessons: done, passedQuizzes: passed);
}

void main() {
  final path = buildSamplePath();
  final arrays = path.chapters[0];
  final hashing = path.chapters[1];

  group('sample content follows the plan', () {
    test('six chapters, each ending in a quiz', () {
      expect(path.chapters.map((c) => c.title), [
        'Arrays',
        'Hashing',
        'Two Pointers',
        'Trees',
        'Graphs',
        'Dynamic Programming',
      ]);
      for (final c in path.chapters) {
        expect(c.quiz.isQuiz, isTrue);
        expect(c.nodes.last, c.quiz);
      }
    });

    test('every lesson and quiz mixes MCQ and coding questions', () {
      for (final c in path.chapters) {
        for (final l in c.nodes) {
          final types = l.questions.map((q) => q.type).toSet();
          expect(types, {QuestionType.mcq, QuestionType.coding}, reason: l.id);
        }
      }
    });

    test('quizzes have at most ${GameRules.quizSize} questions', () {
      for (final c in path.chapters) {
        expect(c.quiz.questions.length, lessThanOrEqualTo(GameRules.quizSize));
      }
    });
  });

  group('unlocking', () {
    test('a new player starts on Arrays lesson 1; the quiz is open; Hashing is locked', () {
      final p = PathProgress(path, player());
      expect(p.current, arrays.lessons[0]);
      expect(p.stateOf(arrays.lessons[0].id), NodeState.current);
      expect(p.stateOf(arrays.lessons[1].id), NodeState.locked);
      expect(p.stateOf(arrays.quiz.id), NodeState.available);
      expect(p.stateOf(hashing.lessons[0].id), NodeState.locked);
      expect(p.isChapterUnlocked(hashing), isFalse);
    });

    test('finishing a lesson opens the next one', () {
      final p = PathProgress(path, player(done: {arrays.lessons[0].id}));
      expect(p.stateOf(arrays.lessons[0].id), NodeState.done);
      expect(p.current, arrays.lessons[1]);
    });

    test('after all lessons, the quiz is current and the next chapter still locked', () {
      final p = PathProgress(path, player(done: {for (final l in arrays.lessons) l.id}));
      expect(p.current, arrays.quiz);
      expect(p.isChapterUnlocked(hashing), isFalse);
    });

    test('passing the quiz early skips ahead: next chapter is current, skipped lessons stay open', () {
      final p = PathProgress(path, player(passed: {arrays.quiz.id}));
      expect(p.isChapterUnlocked(hashing), isTrue);
      expect(p.current, hashing.lessons[0]);
      expect(p.stateOf(arrays.lessons[0].id), NodeState.available);
      expect(p.stateOf(arrays.lessons[1].id), NodeState.available);
      expect(p.stateOf(arrays.quiz.id), NodeState.done);
    });

    test('finishing everything leaves nothing current', () {
      final p = PathProgress(
        path,
        player(
          done: {for (final c in path.chapters) ...c.lessons.map((l) => l.id)},
          passed: {for (final c in path.chapters) c.quiz.id},
        ),
      );
      expect(p.current, isNull);
    });
  });

  group('lesson session', () {
    test('records answers, advances, and computes accuracy', () {
      final lesson = arrays.lessons[0];
      final s = LessonSession(mode: SessionMode.lesson, questions: lesson.questions, lesson: lesson);
      for (var i = 0; i < lesson.questions.length; i++) {
        s.record(
          AnswerOutcome(question: s.current, correct: i.isEven, xpAwarded: i.isEven ? 10 : 0, heartLost: i.isOdd),
        );
        if (!s.isLast) s.advance();
      }
      expect(s.isFinished, isTrue);
      expect(s.correctCount, 3);
      expect(s.accuracy, 0.5);
      expect(s.missed.length, 3);
      expect(s.xpEarned, 30);
    });

    test('a question can only be answered once', () {
      final lesson = arrays.lessons[0];
      final s = LessonSession(mode: SessionMode.lesson, questions: lesson.questions, lesson: lesson);
      final o = AnswerOutcome(question: s.current, correct: true, xpAwarded: 10, heartLost: false);
      s.record(o);
      expect(() => s.record(o), throwsStateError);
    });

    test('a quiz passes at 80%', () {
      final quiz = arrays.quiz;
      final s = LessonSession(mode: SessionMode.quiz, questions: quiz.questions, lesson: quiz);
      final n = quiz.questions.length;
      for (var i = 0; i < n; i++) {
        s.record(AnswerOutcome(question: s.current, correct: i < (n * 0.8).ceil(), xpAwarded: 0, heartLost: false));
        if (!s.isLast) s.advance();
      }
      expect(s.passedQuiz, isTrue);
    });

    test('only lessons and quizzes cost hearts or award XP', () {
      expect(SessionMode.lesson.costsHearts && SessionMode.lesson.awardsXp, isTrue);
      expect(SessionMode.quiz.costsHearts && SessionMode.quiz.awardsXp, isTrue);
      for (final m in [SessionMode.review, SessionMode.practice, SessionMode.replay]) {
        expect(m.costsHearts || m.awardsXp, isFalse, reason: m.name);
      }
    });
  });
}
