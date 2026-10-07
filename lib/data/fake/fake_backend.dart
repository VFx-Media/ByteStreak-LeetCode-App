// In-memory stand-ins for the real backend. Everything here is lost when the
// app closes. Person B replaces these classes (plan §7, Person B).

import 'dart:math' as math;

import 'package:bytestreak/data/repositories.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';

const demoUsername = 'dev123';
const demoEmail = 'dev123@example.com';
const demoPassword = 'password';
const demoUserId = 'user-demo';

class _Account {
  _Account({required this.userId, required this.email, required this.username, required this.password});
  final String userId;
  final String email;
  final String username;
  final String password;
}

/// Shared in-memory "database" behind all the fakes.
class FakeBackend {
  FakeBackend({DateTime Function()? clock, CoursePath? path, this.latency = Duration.zero})
    : _now = clock ?? DateTime.now {
    _accounts.add(_Account(userId: demoUserId, email: demoEmail, username: demoUsername, password: demoPassword));
    if (path != null) _players[demoUserId] = buildDemoPlayer(path, _now());
  }

  final DateTime Function() _now;

  /// Simulated network delay, so loading states are visible while testing.
  final Duration latency;
  final _accounts = <_Account>[];
  final _players = <String, PlayerState>{};
  AuthSession? session;
  AppSettings settings = const AppSettings();

  Future<void> _wait() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

  late final auth = _FakeAuth(this);
  late final players = _FakePlayers(this);
  late final settingsRepo = _FakeSettings(this);
  late final leaderboard = _FakeLeaderboard(this);
  late final codeRunner = FakeCodeRunner(
    latency: latency == Duration.zero ? Duration.zero : const Duration(milliseconds: 700),
  );
}

class _FakeAuth implements AuthRepository {
  _FakeAuth(this._db);
  final FakeBackend _db;

  @override
  String? get demoHint => 'Demo account: $demoUsername / $demoPassword';

  @override
  Future<AuthSession?> restoreSession() async => _db.session;

  @override
  Future<AuthSession> signIn({required String identifier, required String password}) async {
    await _db._wait();
    final id = identifier.trim().toLowerCase();
    final match = _db._accounts.where((a) => a.email.toLowerCase() == id || a.username.toLowerCase() == id);
    if (match.isEmpty) throw const AuthException('No account matches that email or username.');
    if (match.first.password != password) throw const AuthException('That password isn\'t right.');
    return _db.session = AuthSession(userId: match.first.userId, email: match.first.email);
  }

  @override
  Future<AuthSession> signUp({required String email, required String password, required String username}) async {
    await _db._wait();
    if (_db._accounts.any((a) => a.email.toLowerCase() == email.trim().toLowerCase())) {
      throw const AuthException('An account with that email already exists.');
    }
    if (!await isUsernameAvailable(username)) throw const AuthException('That username is taken.');
    final account = _Account(
      userId: 'user-${_db._accounts.length + 1}',
      email: email.trim(),
      username: username.trim(),
      password: password,
    );
    _db._accounts.add(account);
    return _db.session = AuthSession(userId: account.userId, email: account.email);
  }

  @override
  Future<void> signOut() async => _db.session = null;

  @override
  Future<void> sendPasswordReset(String identifier) => _db._wait();

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final u = username.trim().toLowerCase();
    return !_db._accounts.any((a) => a.username.toLowerCase() == u) &&
        !_leaderboardNames.any((n) => n.toLowerCase() == u);
  }
}

class _FakePlayers implements PlayerRepository {
  _FakePlayers(this._db);
  final FakeBackend _db;

  @override
  Future<PlayerState?> load(String userId) async => _db._players[userId];

  @override
  Future<void> save(PlayerState state) async => _db._players[state.profile.userId] = state;
}

class _FakeSettings implements SettingsRepository {
  _FakeSettings(this._db);
  final FakeBackend _db;

  @override
  Future<AppSettings> load() async => _db.settings;

  @override
  Future<void> save(AppSettings settings) async => _db.settings = settings;
}

const _leaderboardNames = [
  'aarav_k',
  'meera.s',
  'devq',
  'sam_lin',
  'nikhil',
  'priya_r',
  'tanmay',
  'lee.w',
  'zoe',
  'raj99',
  'kofi',
  'ana_m',
  'hiro',
  'fatima.z',
  'oliver',
  'sofia_dev',
  'kwame',
  'yuki',
  'mateo',
  'ines',
  'arjun.p',
  'chloe',
  'dmitri',
  'leila',
  'noah_c',
  'amara',
  'jonas',
  'mei',
  'tomas',
  'aisha',
  'felix',
  'ruby',
  'omar',
  'sana',
  'lucas',
  'hana',
  'ivan',
  'nia',
  'pedro',
  'maya',
  'ethan',
  'zara',
  'kai',
  'lina',
  'sami',
  'elena',
  'theo',
  'rhea',
  'jin',
  'amir',
  'nora',
  'ben',
  'isla',
  'yusuf',
  'lea',
  'adam',
  'mira',
  'luca',
  'tara',
  'emre',
];

/// Deterministic fake XP: the top five match the design, then it tails off.
int _fakeXp(int i) {
  const top = [4120, 3980, 3740, 3510, 3300, 2410, 2180, 1960, 1700, 1240, 980];
  if (i < top.length) return top[i];
  return math.max(40, 950 - (i - top.length) * 17 - (i * 37) % 23);
}

class _FakeLeaderboard implements LeaderboardRepository {
  _FakeLeaderboard(this._db);
  final FakeBackend _db;

  @override
  Future<LeaderboardPage> fetch({
    required String userId,
    required String username,
    required int avatarIndex,
    required int xp,
    required bool shareStats,
  }) async {
    await _db._wait();
    final rows =
        <({String id, String name, int avatar, int xp, bool me})>[
          for (var i = 0; i < _leaderboardNames.length; i++)
            (id: 'lb-$i', name: _leaderboardNames[i], avatar: i % 12, xp: _fakeXp(i), me: false),
          if (shareStats) (id: userId, name: username, avatar: avatarIndex, xp: xp, me: true),
        ]..sort((a, b) {
          final byXp = b.xp.compareTo(a.xp);
          if (byXp != 0) return byXp;
          return a.me ? -1 : (b.me ? 1 : 0); // ties go to you
        });

    final entries = [
      for (var i = 0; i < rows.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          userId: rows[i].id,
          username: rows[i].name,
          avatarIndex: rows[i].avatar,
          xp: rows[i].xp,
          isMe: rows[i].me,
        ),
    ];
    final mine = entries.where((e) => e.isMe);
    return LeaderboardPage(
      entries: entries,
      myRank: mine.isEmpty ? null : mine.first.rank,
      totalPlayers: entries.length,
    );
  }
}

/// Pretends to grade code. It can't run Python, so: code that still contains
/// the starter's TODO, or has no `return`, fails every test; anything else
/// passes. Good enough to exercise the UI; Judge0 replaces it.
class FakeCodeRunner implements CodeRunner {
  FakeCodeRunner({this.latency = Duration.zero});
  final Duration latency;

  @override
  Future<RunResult> run({
    required CodingQuestion question,
    required String language,
    required String code,
    required bool includeHidden,
  }) async {
    if (latency > Duration.zero) await Future.delayed(latency);
    final cases = question.testCases.where((t) => includeHidden || !t.hidden).toList();
    final starter = (question.starterCode[language] ?? '').trim();
    final trimmed = code.trim();

    if (trimmed.isEmpty) {
      return const RunResult(results: [], elapsedMs: 0, error: 'Nothing to run: the editor is empty.');
    }
    if (RegExp(r'^\s*(def|class)\s+\w+\s*$', multiLine: true).hasMatch(code)) {
      return const RunResult(results: [], elapsedMs: 3, error: 'SyntaxError: expected \':\'');
    }

    final looksSolved = trimmed != starter && !trimmed.contains('TODO') && trimmed.contains('return');
    final results = [
      for (var i = 0; i < cases.length; i++)
        TestResult(
          testCase: cases[i],
          passed: looksSolved,
          actual: looksSolved ? cases[i].expected : (i == 0 ? 'None' : '0'),
        ),
    ];
    return RunResult(results: results, elapsedMs: 30 + code.length % 40);
  }
}

// ---------------------------------------------------------------------------
// The demo player: a few weeks of history so every screen has data.
// ---------------------------------------------------------------------------

PlayerState buildDemoPlayer(CoursePath path, DateTime now) {
  final today = GameRules.dayOf(now);
  final random = math.Random(42);

  // Chapters 1-3 finished (quizzes passed), Trees lesson 1 done.
  final done = <String>{};
  final passed = <String>{};
  for (final c in path.chapters.take(3)) {
    done.addAll(c.lessons.map((l) => l.id));
    passed.add(c.quiz.id);
  }
  if (path.chapters.length > 3) done.add(path.chapters[3].lessons.first.id);

  // Answer history over 20 weeks, with per-topic accuracy roughly matching
  // the design: Arrays strong, Trees weakest.
  const accuracy = {'arrays': 0.92, 'hashing': 0.71, 'two-pointers': 0.78, 'trees': 0.54};
  final pool = <(Question, double)>[
    for (final c in path.chapters.take(4))
      for (final l in c.lessons)
        for (final q in l.questions) (q, accuracy[c.id] ?? 0.6),
  ];
  final answers = <AnswerRecord>[];
  for (var d = 139; d >= 1; d--) {
    final day = today.subtract(Duration(days: d));
    final inStreak = d <= 12;
    if (!inStreak && random.nextDouble() < 0.45) continue;
    final count = 1 + random.nextInt(inStreak ? 5 : 4);
    for (var k = 0; k < count; k++) {
      final (q, acc) = pool[random.nextInt(pool.length)];
      // Accuracy improves a little over time, so the trend line rises.
      final drift = (139 - d) / 139 * 0.12 - 0.06;
      answers.add(
        AnswerRecord(
          questionId: q.id,
          correct: random.nextDouble() < (acc + drift).clamp(0.05, 0.98),
          at: day.add(Duration(hours: 18 + k % 4, minutes: random.nextInt(59))),
        ),
      );
    }
  }

  final progress = <String, QuestionProgress>{};
  for (final a in answers) {
    final p = progress[a.questionId] ?? const QuestionProgress();
    progress[a.questionId] = p.copyWith(
      attempts: p.attempts + 1,
      correct: p.correct + (a.correct ? 1 : 0),
      lastCorrect: a.correct,
      lastAttempted: a.at,
    );
  }

  final yesterday = today.subtract(const Duration(days: 1));
  return PlayerState(
    profile: Profile(
      userId: demoUserId,
      username: demoUsername,
      email: demoEmail,
      avatarIndex: 1,
      experienceLevel: ExperienceLevel.intermediate,
      goals: const {'Interview prep', 'Daily habit'},
      dailyGoal: DailyGoal.serious,
      memberSince: DateTime(2026, 3, 9),
    ),
    xp: 2480,
    hearts: 4,
    nextHeartAt: now.add(const Duration(minutes: 23, seconds: 41)),
    streak: 12,
    longestStreak: 21,
    lastPracticeDay: yesterday,
    completedLessons: done,
    passedQuizzes: passed,
    progress: progress,
    answers: answers,
    xpEvents: [
      for (final a in answers)
        if (a.correct) XpEvent(amount: 15, reason: XpReason.answer, at: a.at),
    ],
    achievements: {
      'first_spark': today.subtract(const Duration(days: 120)),
      'week_warrior': today.subtract(const Duration(days: 60)),
      'fortnight': today.subtract(const Duration(days: 52)),
      'array_ace': today.subtract(const Duration(days: 40)),
      'hash_hero': today.subtract(const Duration(days: 21)),
      'pointer_pro': today.subtract(const Duration(days: 6)),
    },
    activity: [
      ActivityItem(
        kind: ActivityKind.lesson,
        title: 'Completed Trees · Traversal',
        detail: '+40 XP',
        at: yesterday.add(const Duration(hours: 20, minutes: 12)),
      ),
      ActivityItem(
        kind: ActivityKind.solved,
        title: 'Solved Container With Most Water',
        detail: '+25 XP',
        at: yesterday.add(const Duration(hours: 19, minutes: 40)),
      ),
      ActivityItem(
        kind: ActivityKind.quiz,
        title: 'Passed Two Pointers chapter quiz',
        detail: '9/10 correct',
        at: today.subtract(const Duration(days: 6, hours: -19)),
      ),
      ActivityItem(
        kind: ActivityKind.badge,
        title: 'Earned Pointer Pro',
        detail: 'Topic mastery',
        at: today.subtract(const Duration(days: 6, hours: -19)),
      ),
    ],
    correctRun: 4,
    bestCorrectRun: 17,
  );
}
