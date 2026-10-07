import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/domain/achievements.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/lesson_session.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/state/providers.dart';

/// The single place that changes player data.
///
/// Screens call methods here (`answer`, `revealHint`, `finishSession`...);
/// this class applies the rules from [GameRules], stores the new state, and
/// saves it through the repository. Because the state is immutable, every
/// change produces a new [PlayerState] and Riverpod redraws what depends on it.
class PlayerController extends Notifier<PlayerState?> {
  int? _lastKnownRank;

  @override
  PlayerState? build() {
    final initial = ref.read(initialPlayerProvider);
    return initial == null ? null : _regen(initial);
  }

  AppServices get _services => ref.read(servicesProvider);
  DateTime get _now => ref.read(clockProvider)();

  PlayerState get _player {
    final p = state;
    if (p == null) throw StateError('No player is signed in');
    return p;
  }

  void _set(PlayerState next) {
    state = next;
    unawaited(_services.players.save(next));
  }

  PlayerState _regen(PlayerState p) {
    final r = GameRules.regenerate(hearts: p.hearts, nextHeartAt: p.nextHeartAt, now: _now);
    if (r.hearts == p.hearts && r.nextHeartAt == p.nextHeartAt) return p;
    return p.copyWith(hearts: r.hearts, nextHeartAt: () => r.nextHeartAt);
  }

  // ---- Accounts --------------------------------------------------------------

  /// Throws `AuthException` with a message to show the user.
  Future<void> signIn(String identifier, String password) async {
    final session = await _services.auth.signIn(identifier: identifier, password: password);
    final loaded = await _services.players.load(session.userId);
    state = _regen(
      loaded ??
          PlayerState.fresh(
            Profile(
              userId: session.userId,
              username: identifier.contains('@') ? identifier.split('@').first : identifier,
              email: session.email,
              avatarIndex: 0,
              experienceLevel: ExperienceLevel.beginner,
              goals: const {},
              dailyGoal: DailyGoal.regular,
              memberSince: _now,
            ),
          ),
    );
    ref.read(signedInProvider.notifier).set(true);
  }

  Future<void> signUp(SignupDraft draft) async {
    final session = await _services.auth.signUp(email: draft.email, password: draft.password, username: draft.username);
    _set(
      PlayerState.fresh(
        Profile(
          userId: session.userId,
          username: draft.username.trim(),
          email: session.email,
          avatarIndex: draft.avatarIndex,
          experienceLevel: draft.experienceLevel,
          goals: draft.goals,
          dailyGoal: draft.dailyGoal,
          memberSince: _now,
        ),
      ),
    );
    ref.read(signedInProvider.notifier).set(true);
  }

  /// Leaves [state] in place (see [playerProvider]); the router reacts to
  /// [signedInProvider] and the next sign-in replaces the data.
  Future<void> signOut() async {
    await _services.auth.signOut();
    ref.read(signedInProvider.notifier).set(false);
  }

  void updateProfile({String? username, int? avatarIndex, DailyGoal? dailyGoal}) {
    final p = _player;
    _set(
      p.copyWith(
        profile: p.profile.copyWith(username: username, avatarIndex: avatarIndex, dailyGoal: dailyGoal),
      ),
    );
  }

  // ---- Hearts ----------------------------------------------------------------

  /// Adds hearts that have regenerated. Screens with a countdown call this.
  void tick() {
    final p = state;
    if (p == null) return;
    final next = _regen(p);
    if (!identical(next, p)) _set(next);
  }

  /// Spends 120 XP to restore all hearts. Returns false if XP is short.
  bool refillHearts() {
    final p = _regen(_player);
    if (p.xp < GameRules.heartRefillCost) return false;
    final now = _now;
    _set(
      p.copyWith(
        xp: p.xp - GameRules.heartRefillCost,
        hearts: GameRules.maxHearts,
        nextHeartAt: () => null,
        xpEvents: [
          ...p.xpEvents,
          XpEvent(amount: -GameRules.heartRefillCost, reason: XpReason.heartRefill, at: now),
        ],
      ),
    );
    return true;
  }

  /// Up to 3 questions you've answered correctly before: "practise something
  /// you already know" on the Out of hearts screen.
  List<Question> practiceQuestions() {
    final p = _player;
    final path = ref.read(coursePathProvider);
    final known = [
      for (final e in p.progress.entries)
        if (e.value.correct > 0 && path.question(e.key) != null) path.question(e.key)!,
    ];
    final pool = known.isNotEmpty ? known : path.chapters.first.lessons.first.questions;
    final shuffled = List.of(pool)..shuffle(math.Random(_now.millisecondsSinceEpoch ~/ 60000));
    return shuffled.take(GameRules.practiceSize).toList();
  }

  // ---- Answering -------------------------------------------------------------

  /// Records an answer to the session's current question and applies hearts
  /// and XP for the session's mode.
  AnswerOutcome answer(LessonSession session, {required bool correct}) {
    final q = session.current;
    final p = _regen(_player);
    final now = _now;
    final progress = p.progressOf(q.id);

    final xp = GameRules.xpForAnswer(
      question: q,
      correct: correct,
      solutionViewed: progress.solutionViewed,
      awardsXp: session.mode.awardsXp,
    );
    final loseHeart = !correct && session.mode.costsHearts;
    final hearts = loseHeart
        ? GameRules.loseHeart(hearts: p.hearts, nextHeartAt: p.nextHeartAt, now: now)
        : (hearts: p.hearts, nextHeartAt: p.nextHeartAt);
    final run = correct ? p.correctRun + 1 : 0;

    final outcome = AnswerOutcome(question: q, correct: correct, xpAwarded: xp, heartLost: loseHeart);
    session.record(outcome);

    _set(
      p.copyWith(
        xp: p.xp + xp,
        hearts: hearts.hearts,
        nextHeartAt: () => hearts.nextHeartAt,
        progress: {
          ...p.progress,
          q.id: progress.copyWith(
            attempts: progress.attempts + 1,
            correct: progress.correct + (correct ? 1 : 0),
            lastCorrect: correct,
            lastAttempted: now,
          ),
        },
        answers: [
          ...p.answers,
          AnswerRecord(questionId: q.id, correct: correct, at: now),
        ],
        xpEvents: xp > 0 ? [...p.xpEvents, XpEvent(amount: xp, reason: XpReason.answer, at: now)] : null,
        correctRun: run,
        bestCorrectRun: math.max(p.bestCorrectRun, run),
        activity: correct && q is CodingQuestion && session.mode.awardsXp
            ? _pushActivity(
                p.activity,
                ActivityItem(kind: ActivityKind.solved, title: 'Solved ${q.prompt}', detail: '+$xp XP', at: now),
              )
            : null,
      ),
    );
    return outcome;
  }

  /// Hints cost XP only in modes that earn XP (lessons and quizzes).
  int hintCost(SessionMode mode) => mode.awardsXp ? GameRules.hintCost : 0;

  /// Reveals the next hint. Returns false if there are none left or the
  /// player can't afford it.
  bool revealHint(Question q, SessionMode mode) {
    final p = _player;
    final progress = p.progressOf(q.id);
    if (progress.hintsRevealed >= q.hints.length) return false;
    final cost = hintCost(mode);
    if (p.xp < cost) return false;
    _set(
      p.copyWith(
        xp: p.xp - cost,
        progress: {
          ...p.progress,
          q.id: progress.copyWith(hintsRevealed: progress.hintsRevealed + 1),
        },
        xpEvents: cost > 0 ? [...p.xpEvents, XpEvent(amount: -cost, reason: XpReason.hint, at: _now)] : null,
      ),
    );
    return true;
  }

  /// Plan §2: viewing the solution is free but the question then earns 0 XP.
  void viewSolution(Question q) {
    final p = _player;
    final progress = p.progressOf(q.id);
    if (progress.solutionViewed) return;
    _set(p.copyWith(progress: {...p.progress, q.id: progress.copyWith(solutionViewed: true)}));
  }

  // ---- Finishing -------------------------------------------------------------

  LessonResult finishSession(LessonSession session) {
    final now = _now;
    final path = ref.read(coursePathProvider);
    var p = _regen(_player);
    final lesson = session.lesson;
    final chapter = lesson == null ? null : path.chapterOfLesson(lesson.id);

    var bonus = 0;
    var passedQuiz = false;
    var completed = p.completedLessons;
    var passed = p.passedQuizzes;
    var activity = p.activity;
    var streak = p.streak;
    var longest = p.longestStreak;
    var lastDay = p.lastPracticeDay;
    var hearts = p.hearts;
    var nextHeartAt = p.nextHeartAt;

    if (lesson != null && (session.mode == SessionMode.lesson || session.mode == SessionMode.quiz)) {
      final s = GameRules.recordPractice(streak: streak, lastPracticeDay: lastDay, now: now);
      streak = s.streak;
      lastDay = s.lastPracticeDay;
      longest = math.max(longest, streak);

      if (session.mode == SessionMode.lesson) {
        completed = {...completed, lesson.id};
        bonus = GameRules.lessonBonus;
        activity = _pushActivity(
          activity,
          ActivityItem(
            kind: ActivityKind.lesson,
            title: 'Completed ${chapter?.title ?? ''} · ${lesson.title}',
            detail: '+${session.xpEarned + bonus} XP',
            at: now,
          ),
        );
      } else if (session.passedQuiz) {
        passedQuiz = true;
        passed = {...passed, lesson.id};
        bonus = GameRules.quizPassBonus;
        activity = _pushActivity(
          activity,
          ActivityItem(
            kind: ActivityKind.quiz,
            title: 'Passed ${chapter?.title ?? ''} chapter quiz',
            detail: '${session.correctCount}/${session.questions.length} correct',
            at: now,
          ),
        );
      }
    }

    if (session.mode == SessionMode.practice) {
      hearts = math.min(GameRules.maxHearts, hearts + 1);
      nextHeartAt = hearts >= GameRules.maxHearts ? null : nextHeartAt;
    }

    p = p.copyWith(
      xp: p.xp + bonus,
      completedLessons: completed,
      passedQuizzes: passed,
      activity: activity,
      streak: streak,
      longestStreak: longest,
      lastPracticeDay: () => lastDay,
      hearts: hearts,
      nextHeartAt: () => nextHeartAt,
      xpEvents: bonus > 0
          ? [
              ...p.xpEvents,
              XpEvent(
                amount: bonus,
                reason: session.mode == SessionMode.quiz ? XpReason.quizBonus : XpReason.lessonBonus,
                at: now,
              ),
            ]
          : null,
    );

    final earned = _awardAchievements(p, now);
    p = earned.player;
    _set(p);

    final today = GameRules.dayOf(now);
    return LessonResult(
      mode: session.mode,
      lesson: lesson,
      outcomes: List.unmodifiable(session.outcomes),
      xpEarned: session.xpEarned + bonus,
      streak: GameRules.effectiveStreak(streak: p.streak, lastPracticeDay: p.lastPracticeDay, now: now),
      passedQuiz: passedQuiz,
      newAchievements: earned.names,
      dailyGoalDone: p.answers.where((a) => GameRules.dayOf(a.at) == today).length,
      dailyGoalTarget: p.profile.dailyGoal.questions,
    );
  }

  /// Called when the leaderboard loads, so the Gold League badge can unlock.
  void recordRank(int? rank) {
    _lastKnownRank = rank;
    final p = state;
    if (p == null) return;
    final earned = _awardAchievements(p, _now);
    if (earned.names.isNotEmpty) _set(earned.player);
  }

  ({PlayerState player, List<String> names}) _awardAchievements(PlayerState p, DateTime now) {
    final defs = ref.read(achievementDefsProvider);
    final ids = newlyEarned(
      defs,
      AchievementContext(player: p, path: ref.read(coursePathProvider), now: now, rank: _lastKnownRank),
    );
    if (ids.isEmpty) return (player: p, names: const []);
    final byId = {for (final d in defs) d.id: d};
    var activity = p.activity;
    for (final id in ids) {
      activity = _pushActivity(
        activity,
        ActivityItem(
          kind: ActivityKind.badge,
          title: 'Earned ${byId[id]!.name}',
          detail: byId[id]!.category.label,
          at: now,
        ),
      );
    }
    return (
      player: p.copyWith(achievements: {...p.achievements, for (final id in ids) id: now}, activity: activity),
      names: [for (final id in ids) byId[id]!.name],
    );
  }

  static List<ActivityItem> _pushActivity(List<ActivityItem> list, ActivityItem item) =>
      [item, ...list].take(50).toList();
}
