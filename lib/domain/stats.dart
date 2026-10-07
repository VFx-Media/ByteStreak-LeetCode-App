import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';

class TopicMastery {
  const TopicMastery({required this.chapter, required this.correct, required this.attempts});
  final Chapter chapter;
  final int correct;
  final int attempts;

  /// Null when the topic hasn't been attempted yet.
  double? get accuracy => attempts == 0 ? null : correct / attempts;
}

/// Everything the Stats screen shows, derived from the answer log.
class PlayerStats {
  PlayerStats._({
    required this.level,
    required this.skill,
    required this.streak,
    required this.longestStreak,
    required this.solved,
    required this.solvedThisWeek,
    required this.accuracy,
    required this.accuracyChange,
    required this.topics,
    required this.heatmap,
    required this.weeklyAccuracy,
    required this.answeredToday,
  });

  final int level;
  final String skill;
  final int streak;
  final int longestStreak;
  final int solved;
  final int solvedThisWeek;

  /// Null before the first answer.
  final double? accuracy;

  /// Last 30 days vs the 30 before; null when either window is empty.
  final double? accuracyChange;
  final List<TopicMastery> topics;

  /// Answers per day for the last [heatmapWeeks] weeks, oldest first, in
  /// Monday-Sunday columns. Days in the future are -1.
  final List<List<int>> heatmap;

  /// Rolling weekly accuracy for the last [trendWeeks] weeks; null = no answers.
  final List<double?> weeklyAccuracy;
  final int answeredToday;

  static const heatmapWeeks = 20;
  static const trendWeeks = 11;

  TopicMastery? get strongest {
    final tried = topics.where((t) => t.accuracy != null).toList();
    if (tried.isEmpty) return null;
    tried.sort((a, b) => b.accuracy!.compareTo(a.accuracy!));
    return tried.first;
  }

  TopicMastery? get weakest {
    final tried = topics.where((t) => t.accuracy != null).toList();
    if (tried.length < 2) return null;
    tried.sort((a, b) => a.accuracy!.compareTo(b.accuracy!));
    return tried.first;
  }

  factory PlayerStats.from(PlayerState player, CoursePath path, DateTime now) {
    final today = GameRules.dayOf(now);
    final answers = player.answers;

    // Solved = distinct questions answered correctly at least once.
    final firstSolved = <String, DateTime>{};
    for (final a in answers) {
      if (a.correct) firstSolved.putIfAbsent(a.questionId, () => a.at);
    }
    final weekAgo = now.subtract(const Duration(days: 7));
    final solvedThisWeek = firstSolved.values.where((t) => t.isAfter(weekAgo)).length;

    double? accuracyBetween(DateTime from, DateTime to) {
      final window = answers.where((a) => !a.at.isBefore(from) && a.at.isBefore(to));
      if (window.isEmpty) return null;
      return window.where((a) => a.correct).length / window.length;
    }

    final overall = answers.isEmpty ? null : answers.where((a) => a.correct).length / answers.length;
    final recent = accuracyBetween(now.subtract(const Duration(days: 30)), now.add(const Duration(seconds: 1)));
    final before = accuracyBetween(now.subtract(const Duration(days: 60)), now.subtract(const Duration(days: 30)));

    // Topic mastery: accuracy over every answer in that chapter's questions.
    final byChapter = <String, ({int correct, int attempts})>{};
    for (final a in answers) {
      final chapter = path.chapterOfQuestion(a.questionId);
      if (chapter == null) continue;
      final cur = byChapter[chapter.id] ?? (correct: 0, attempts: 0);
      byChapter[chapter.id] = (correct: cur.correct + (a.correct ? 1 : 0), attempts: cur.attempts + 1);
    }
    final topics = [
      for (final c in path.chapters)
        TopicMastery(
          chapter: c,
          correct: byChapter[c.id]?.correct ?? 0,
          attempts: byChapter[c.id]?.attempts ?? 0,
        ),
    ];

    // Heatmap: columns are weeks (Mon-Sun), the last column is this week.
    final perDay = <DateTime, int>{};
    for (final a in answers) {
      final d = GameRules.dayOf(a.at);
      perDay[d] = (perDay[d] ?? 0) + 1;
    }
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final firstMonday = thisMonday.subtract(const Duration(days: 7 * (heatmapWeeks - 1)));
    final heatmap = [
      for (var w = 0; w < heatmapWeeks; w++)
        [
          for (var d = 0; d < 7; d++)
            () {
              final day = DateTime(firstMonday.year, firstMonday.month, firstMonday.day + w * 7 + d);
              return day.isAfter(today) ? -1 : (perDay[day] ?? 0);
            }(),
        ],
    ];

    final weekly = [
      for (var w = trendWeeks - 1; w >= 0; w--)
        accuracyBetween(
          today.subtract(Duration(days: 7 * w + 6)),
          today.add(const Duration(days: 1)).subtract(Duration(days: 7 * w)),
        ),
    ];

    final level = GameRules.levelForXp(player.xp);
    return PlayerStats._(
      level: level,
      skill: GameRules.skillLabel(level),
      streak: GameRules.effectiveStreak(
        streak: player.streak,
        lastPracticeDay: player.lastPracticeDay,
        now: now,
      ),
      longestStreak: player.longestStreak,
      solved: firstSolved.length,
      solvedThisWeek: solvedThisWeek,
      accuracy: overall,
      accuracyChange: recent != null && before != null ? recent - before : null,
      topics: topics,
      heatmap: heatmap,
      weeklyAccuracy: weekly,
      answeredToday: perDay[today] ?? 0,
    );
  }
}
