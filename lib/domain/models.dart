// Plain Dart data classes: no Flutter imports, so they can be unit-tested and
// shared with the data layer (drift / Supabase) without dragging UI code along.

enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const Difficulty(this.label);
  final String label;
}

enum QuestionType { mcq, coding }

// ---------------------------------------------------------------------------
// Content: path -> chapters -> lessons -> questions
// ---------------------------------------------------------------------------

/// A question is either multiple-choice or coding. `sealed` means these two
/// are the only kinds, so a `switch` over a Question must handle both.
sealed class Question {
  const Question({
    required this.id,
    required this.difficulty,
    required this.prompt,
    required this.hints,
    required this.solution,
    required this.xpReward,
    required this.topic,
  });

  final String id;
  final Difficulty difficulty;

  /// MCQ: the question. Coding: the problem title.
  final String prompt;

  /// Progressive hints, revealed one at a time.
  final List<String> hints;

  /// MCQ: why the answer is right. Coding: a worked solution.
  final String solution;
  final int xpReward;

  /// Chapter title, used for the topic tag and the Stats screen.
  final String topic;

  QuestionType get type;
}

class McqQuestion extends Question {
  const McqQuestion({
    required super.id,
    required super.difficulty,
    required super.prompt,
    required super.hints,
    required super.solution,
    required super.xpReward,
    required super.topic,
    required this.options,
    required this.correctIndex,
  });

  final List<String> options;
  final int correctIndex;

  @override
  QuestionType get type => QuestionType.mcq;
}

class CodeExample {
  const CodeExample({required this.input, required this.output, this.explanation});
  final String input;
  final String output;
  final String? explanation;
}

class TestCase {
  const TestCase({required this.input, required this.expected, this.hidden = false});
  final String input;
  final String expected;

  /// Hidden cases only run on Submit, never on Run.
  final bool hidden;
}

class CodingQuestion extends Question {
  const CodingQuestion({
    required super.id,
    required super.difficulty,
    required super.prompt,
    required super.hints,
    required super.solution,
    required super.xpReward,
    required super.topic,
    required this.description,
    required this.examples,
    required this.constraints,
    required this.starterCode,
    required this.testCases,
  });

  final String description;
  final List<CodeExample> examples;
  final List<String> constraints;

  /// Language id (`python`, `java`, `cpp`) -> starter code.
  final Map<String, String> starterCode;
  final List<TestCase> testCases;

  @override
  QuestionType get type => QuestionType.coding;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.questions,
    this.isQuiz = false,
  });

  final String id;
  final String chapterId;
  final String title;
  final List<Question> questions;
  final bool isQuiz;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.number,
    required this.title,
    required this.summary,
    required this.lessons,
    required this.quiz,
  });

  final String id;
  final int number;
  final String title;
  final String summary;

  /// Normal lessons, in order. The quiz is kept separately.
  final List<Lesson> lessons;
  final Lesson quiz;

  /// Lessons followed by the quiz: the order nodes appear on the path.
  List<Lesson> get nodes => [...lessons, quiz];
}

/// The single learning path: LeetCode Mastery.
class CoursePath {
  CoursePath({required this.title, required this.chapters}) {
    for (final c in chapters) {
      for (final l in c.nodes) {
        _lessons[l.id] = l;
        _chapterOf[l.id] = c;
        for (final q in l.questions) {
          _questions[q.id] = q;
          _questionChapter.putIfAbsent(q.id, () => c);
        }
      }
    }
  }

  final String title;
  final List<Chapter> chapters;
  final _lessons = <String, Lesson>{};
  final _chapterOf = <String, Chapter>{};
  final _questions = <String, Question>{};
  final _questionChapter = <String, Chapter>{};

  Lesson? lesson(String id) => _lessons[id];
  Chapter? chapterOfLesson(String lessonId) => _chapterOf[lessonId];
  Chapter? chapterOfQuestion(String questionId) => _questionChapter[questionId];
  Question? question(String id) => _questions[id];
  Chapter? chapter(String id) {
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }

  Iterable<Question> get allQuestions => _questions.values;
}

// ---------------------------------------------------------------------------
// The player
// ---------------------------------------------------------------------------

enum ExperienceLevel {
  beginner('Beginner', 'New to DSA'),
  intermediate('Intermediate', 'Some practice'),
  advanced('Advanced', 'Interview ready');

  const ExperienceLevel(this.label, this.blurb);
  final String label;
  final String blurb;
}

enum DailyGoal {
  casual('Casual', 1, '~5 min'),
  regular('Regular', 2, '~10 min'),
  serious('Serious', 3, '~20 min'),
  intense('Intense', 5, '~35 min');

  const DailyGoal(this.label, this.questions, this.time);
  final String label;
  final int questions;
  final String time;
}

const learnerGoals = [
  'Interview prep',
  'Learn DSA basics',
  'Daily habit',
  'Compete on leaderboard',
  'Brush up for a course',
];

class Profile {
  const Profile({
    required this.userId,
    required this.username,
    required this.email,
    required this.avatarIndex,
    required this.experienceLevel,
    required this.goals,
    required this.dailyGoal,
    required this.memberSince,
  });

  final String userId;
  final String username;
  final String email;

  /// 0-11: which preset avatar.
  final int avatarIndex;
  final ExperienceLevel experienceLevel;
  final Set<String> goals;
  final DailyGoal dailyGoal;
  final DateTime memberSince;

  Profile copyWith({
    String? username,
    int? avatarIndex,
    ExperienceLevel? experienceLevel,
    Set<String>? goals,
    DailyGoal? dailyGoal,
  }) {
    return Profile(
      userId: userId,
      username: username ?? this.username,
      email: email,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      goals: goals ?? this.goals,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      memberSince: memberSince,
    );
  }
}

enum XpReason { answer, lessonBonus, quizBonus, hint, heartRefill }

/// Every earn or spend is recorded as an event (plan §4: "XP sync").
class XpEvent {
  const XpEvent({required this.amount, required this.reason, required this.at});
  final int amount;
  final XpReason reason;
  final DateTime at;
}

/// One answered question. Stats (accuracy, heatmap, trend) derive from these.
class AnswerRecord {
  const AnswerRecord({required this.questionId, required this.correct, required this.at});
  final String questionId;
  final bool correct;
  final DateTime at;
}

class QuestionProgress {
  const QuestionProgress({
    this.attempts = 0,
    this.correct = 0,
    this.lastCorrect = false,
    this.solutionViewed = false,
    this.hintsRevealed = 0,
    this.lastAttempted,
  });

  final int attempts;
  final int correct;
  final bool lastCorrect;

  /// Plan §2: viewing the solution makes the question worth 0 XP.
  final bool solutionViewed;
  final int hintsRevealed;
  final DateTime? lastAttempted;

  QuestionProgress copyWith({
    int? attempts,
    int? correct,
    bool? lastCorrect,
    bool? solutionViewed,
    int? hintsRevealed,
    DateTime? lastAttempted,
  }) {
    return QuestionProgress(
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
      lastCorrect: lastCorrect ?? this.lastCorrect,
      solutionViewed: solutionViewed ?? this.solutionViewed,
      hintsRevealed: hintsRevealed ?? this.hintsRevealed,
      lastAttempted: lastAttempted ?? this.lastAttempted,
    );
  }
}

enum ActivityKind { solved, badge, lesson, quiz }

class ActivityItem {
  const ActivityItem({
    required this.kind,
    required this.title,
    required this.detail,
    required this.at,
  });

  final ActivityKind kind;
  final String title;
  final String detail;
  final DateTime at;
}

/// Everything about one player. Immutable: every change makes a new copy,
/// which is what lets Riverpod notice the change and redraw the screen.
class PlayerState {
  const PlayerState({
    required this.profile,
    required this.xp,
    required this.hearts,
    required this.nextHeartAt,
    required this.streak,
    required this.longestStreak,
    required this.lastPracticeDay,
    required this.completedLessons,
    required this.passedQuizzes,
    required this.progress,
    required this.answers,
    required this.xpEvents,
    required this.achievements,
    required this.activity,
    required this.correctRun,
    required this.bestCorrectRun,
  });

  factory PlayerState.fresh(Profile profile) => PlayerState(
        profile: profile,
        xp: 0,
        hearts: 5,
        nextHeartAt: null,
        streak: 0,
        longestStreak: 0,
        lastPracticeDay: null,
        completedLessons: const {},
        passedQuizzes: const {},
        progress: const {},
        answers: const [],
        xpEvents: const [],
        achievements: const {},
        activity: const [],
        correctRun: 0,
        bestCorrectRun: 0,
      );

  final Profile profile;
  final int xp;
  final int hearts;
  final DateTime? nextHeartAt;
  final int streak;
  final int longestStreak;

  /// The last calendar day (midnight) a lesson was completed.
  final DateTime? lastPracticeDay;
  final Set<String> completedLessons;
  final Set<String> passedQuizzes;
  final Map<String, QuestionProgress> progress;
  final List<AnswerRecord> answers;
  final List<XpEvent> xpEvents;

  /// Achievement id -> when it was earned.
  final Map<String, DateTime> achievements;

  /// Newest first.
  final List<ActivityItem> activity;
  final int correctRun;
  final int bestCorrectRun;

  QuestionProgress progressOf(String questionId) =>
      progress[questionId] ?? const QuestionProgress();

  PlayerState copyWith({
    Profile? profile,
    int? xp,
    int? hearts,
    DateTime? Function()? nextHeartAt,
    int? streak,
    int? longestStreak,
    DateTime? Function()? lastPracticeDay,
    Set<String>? completedLessons,
    Set<String>? passedQuizzes,
    Map<String, QuestionProgress>? progress,
    List<AnswerRecord>? answers,
    List<XpEvent>? xpEvents,
    Map<String, DateTime>? achievements,
    List<ActivityItem>? activity,
    int? correctRun,
    int? bestCorrectRun,
  }) {
    return PlayerState(
      profile: profile ?? this.profile,
      xp: xp ?? this.xp,
      hearts: hearts ?? this.hearts,
      // Nullable fields take a function so "set to null" and "leave alone"
      // can be told apart: copyWith(nextHeartAt: () => null) clears it.
      nextHeartAt: nextHeartAt != null ? nextHeartAt() : this.nextHeartAt,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPracticeDay: lastPracticeDay != null ? lastPracticeDay() : this.lastPracticeDay,
      completedLessons: completedLessons ?? this.completedLessons,
      passedQuizzes: passedQuizzes ?? this.passedQuizzes,
      progress: progress ?? this.progress,
      answers: answers ?? this.answers,
      xpEvents: xpEvents ?? this.xpEvents,
      achievements: achievements ?? this.achievements,
      activity: activity ?? this.activity,
      correctRun: correctRun ?? this.correctRun,
      bestCorrectRun: bestCorrectRun ?? this.bestCorrectRun,
    );
  }
}

// ---------------------------------------------------------------------------
// Settings, leaderboard, code runs
// ---------------------------------------------------------------------------

enum ThemePreference { light, dark, system }

class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.system,
    this.reduceMotion = false,
    this.shareStats = true,
    this.dailyReminder = true,
    this.reminderMinutes = 19 * 60,
    this.launchOnStartup = false,
  });

  final ThemePreference theme;
  final bool reduceMotion;

  /// Off = hidden from the public leaderboard (enforced by RLS in Supabase).
  final bool shareStats;
  final bool dailyReminder;

  /// Minutes after midnight, e.g. 1140 = 7:00 PM.
  final int reminderMinutes;
  final bool launchOnStartup;

  AppSettings copyWith({
    ThemePreference? theme,
    bool? reduceMotion,
    bool? shareStats,
    bool? dailyReminder,
    int? reminderMinutes,
    bool? launchOnStartup,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      shareStats: shareStats ?? this.shareStats,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      launchOnStartup: launchOnStartup ?? this.launchOnStartup,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.avatarIndex,
    required this.xp,
    this.isMe = false,
  });

  final int rank;
  final String userId;
  final String username;
  final int avatarIndex;
  final int xp;
  final bool isMe;
}

class LeaderboardPage {
  const LeaderboardPage({required this.entries, required this.myRank, required this.totalPlayers});

  /// Sorted by rank.
  final List<LeaderboardEntry> entries;

  /// Null when the player has hidden their stats.
  final int? myRank;
  final int totalPlayers;
}

class TestResult {
  const TestResult({required this.testCase, required this.passed, required this.actual});
  final TestCase testCase;
  final bool passed;
  final String actual;
}

class RunResult {
  const RunResult({required this.results, required this.elapsedMs, this.error});
  final List<TestResult> results;
  final int elapsedMs;

  /// Compile or runtime error, shown instead of test results.
  final String? error;

  int get passed => results.where((r) => r.passed).length;
  bool get allPassed => error == null && results.isNotEmpty && passed == results.length;
}
