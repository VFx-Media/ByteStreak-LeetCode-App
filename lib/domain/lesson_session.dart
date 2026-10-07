import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';

/// Why the player is answering questions. It decides whether answers cost
/// hearts and earn XP.
enum SessionMode {
  /// A normal lesson: hearts and XP.
  lesson,

  /// A chapter quiz: hearts and XP; 80% unlocks the next chapter.
  quiz,

  /// "Review mistakes": the questions you missed. No hearts, no XP.
  review,

  /// "Practise to earn a heart": 3 questions you got right before. No hearts,
  /// no XP; finishing earns one heart.
  practice,

  /// Replaying a finished lesson. No hearts, no XP (stops XP farming).
  replay;

  bool get costsHearts => this == lesson || this == quiz;
  bool get awardsXp => this == lesson || this == quiz;
}

class AnswerOutcome {
  const AnswerOutcome({
    required this.question,
    required this.correct,
    required this.xpAwarded,
    required this.heartLost,
  });

  final Question question;
  final bool correct;
  final int xpAwarded;
  final bool heartLost;
}

/// One run through a list of questions. Pure logic: it records answers and
/// moves forward, but never touches hearts or XP itself; the PlayerController
/// applies those so there is a single place that changes player data.
class LessonSession {
  LessonSession({required this.mode, required this.questions, this.lesson})
    : assert(questions.isNotEmpty, 'A session needs at least one question');

  final SessionMode mode;
  final List<Question> questions;

  /// The lesson or quiz being played. Null for practice sessions.
  final Lesson? lesson;

  final outcomes = <AnswerOutcome>[];
  var _index = 0;

  int get index => _index;
  Question get current => questions[_index];
  bool get answeredCurrent => outcomes.length > _index;
  bool get isLast => _index == questions.length - 1;
  bool get isFinished => outcomes.length == questions.length;

  int get correctCount => outcomes.where((o) => o.correct).length;
  int get xpEarned => outcomes.fold(0, (sum, o) => sum + o.xpAwarded);
  double get accuracy => outcomes.isEmpty ? 0 : correctCount / outcomes.length;
  List<Question> get missed => [
    for (final o in outcomes)
      if (!o.correct) o.question,
  ];

  bool get passedQuiz => mode == SessionMode.quiz && isFinished && accuracy >= GameRules.quizPassMark;

  void record(AnswerOutcome outcome) {
    if (answeredCurrent) {
      throw StateError('Question ${current.id} was already answered');
    }
    outcomes.add(outcome);
  }

  /// Moves to the next question. Returns false if this was the last one.
  bool advance() {
    if (isLast) return false;
    _index++;
    return true;
  }
}

/// What the Lesson complete screen shows.
class LessonResult {
  const LessonResult({
    required this.mode,
    required this.lesson,
    required this.outcomes,
    required this.xpEarned,
    required this.streak,
    required this.passedQuiz,
    required this.newAchievements,
    required this.dailyGoalDone,
    required this.dailyGoalTarget,
  });

  final SessionMode mode;
  final Lesson? lesson;
  final List<AnswerOutcome> outcomes;

  /// Answers plus completion bonuses.
  final int xpEarned;
  final int streak;
  final bool passedQuiz;
  final List<String> newAchievements;
  final int dailyGoalDone;
  final int dailyGoalTarget;

  int get correct => outcomes.where((o) => o.correct).length;
  double get accuracy => outcomes.isEmpty ? 0 : correct / outcomes.length;
  List<Question> get missed => [
    for (final o in outcomes)
      if (!o.correct) o.question,
  ];
}
