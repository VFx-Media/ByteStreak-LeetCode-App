import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/domain/path_progress.dart';

enum AchievementCategory {
  streaks('Streaks'),
  mastery('Topic mastery'),
  milestones('Milestones');

  const AchievementCategory(this.label);
  final String label;
}

/// Everything an achievement needs to measure progress.
class AchievementContext {
  const AchievementContext({
    required this.player,
    required this.path,
    required this.now,
    this.rank,
  });

  final PlayerState player;
  final CoursePath path;
  final DateTime now;

  /// Global leaderboard rank, when known.
  final int? rank;
}

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.target,
    required this.unit,
    required this.measure,
    this.series,
  });

  final String id;
  final String name;
  final String description;
  final AchievementCategory category;

  /// A key the UI maps to an icon (keeps this file free of Flutter imports).
  final String icon;
  final int target;

  /// "days", "lessons", "questions" — used in "12 / 14 days".
  final String unit;

  /// Badges in the same series are tiers: First Spark -> Week Warrior -> ...
  final String? series;
  final int Function(AchievementContext ctx) measure;

  int progress(AchievementContext ctx) => measure(ctx).clamp(0, target);
}

int _bestStreak(AchievementContext c) {
  final current = GameRules.effectiveStreak(
    streak: c.player.streak,
    lastPracticeDay: c.player.lastPracticeDay,
    now: c.now,
  );
  return current > c.player.longestStreak ? current : c.player.longestStreak;
}

int _chapterNodesDone(AchievementContext c, String chapterId) {
  final chapter = c.path.chapter(chapterId);
  if (chapter == null) return 0;
  final p = PathProgress(c.path, c.player);
  return chapter.nodes.where((n) => p.stateOf(n.id) == NodeState.done).length;
}

int _chapterSize(CoursePath? path, String chapterId) => path?.chapter(chapterId)?.nodes.length ?? 3;

int _solved(AchievementContext c) => c.player.progress.values.where((p) => p.correct > 0).length;

/// The badge catalogue. Topic-mastery targets depend on how many lessons each
/// chapter has, so the list is built from the course path.
List<AchievementDef> buildAchievements(CoursePath? path) {
  AchievementDef mastery(String id, String chapterId, String name, String icon) {
    final title = path?.chapter(chapterId)?.title ?? chapterId;
    return AchievementDef(
      id: id,
      name: name,
      description: 'Finish every lesson and pass the quiz in $title.',
      category: AchievementCategory.mastery,
      icon: icon,
      target: _chapterSize(path, chapterId),
      unit: 'lessons',
      measure: (c) => _chapterNodesDone(c, chapterId),
    );
  }

  AchievementDef streak(String id, String name, int days, String blurb) {
    return AchievementDef(
      id: id,
      name: name,
      description: blurb,
      category: AchievementCategory.streaks,
      icon: 'flame',
      target: days,
      unit: 'days',
      series: 'streak',
      measure: _bestStreak,
    );
  }

  return [
    streak('first_spark', 'First Spark', 1, 'Complete your first lesson.'),
    streak('week_warrior', 'Week Warrior', 7,
        'Practise every day for 7 days in a row. Missing a day resets the count.'),
    streak('fortnight', 'Fortnight', 14,
        'Practise every day for 14 days in a row. Missing a day resets the count.'),
    streak('century_streak', 'Century', 100, 'A 100-day streak. Legendary.'),
    mastery('array_ace', 'arrays', 'Array Ace', 'grid'),
    mastery('hash_hero', 'hashing', 'Hash Hero', 'key'),
    mastery('pointer_pro', 'two-pointers', 'Pointer Pro', 'pointers'),
    mastery('tree_hugger', 'trees', 'Tree Hugger', 'tree'),
    mastery('graph_theorist', 'graphs', 'Graph Theorist', 'graph'),
    mastery('dp_dreamer', 'dp', 'DP Dreamer', 'brain'),
    AchievementDef(
      id: 'century_club',
      name: 'Century Club',
      description: 'Solve 100 different questions.',
      category: AchievementCategory.milestones,
      icon: 'bolt',
      target: 100,
      unit: 'questions',
      series: 'solved',
      measure: _solved,
    ),
    AchievementDef(
      id: 'sharpshooter',
      name: 'Sharpshooter',
      description: 'Answer 20 questions in a row correctly.',
      category: AchievementCategory.milestones,
      icon: 'target',
      target: 20,
      unit: 'in a row',
      measure: (c) => c.player.bestCorrectRun,
    ),
    AchievementDef(
      id: 'gold_league',
      name: 'Gold League',
      description: 'Reach the top 10 on the global leaderboard.',
      category: AchievementCategory.milestones,
      icon: 'trophy',
      target: 1,
      unit: '',
      measure: (c) => c.rank != null && c.rank! <= GameRules.goldCutoff ? 1 : 0,
    ),
    AchievementDef(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Solve a question between midnight and 4 AM.',
      category: AchievementCategory.milestones,
      icon: 'moon',
      target: 1,
      unit: '',
      measure: (c) => c.player.answers.any((a) => a.correct && a.at.hour < 4) ? 1 : 0,
    ),
  ];
}

/// Ids of achievements that are complete but not yet recorded as earned.
List<String> newlyEarned(List<AchievementDef> defs, AchievementContext ctx) => [
      for (final d in defs)
        if (!ctx.player.achievements.containsKey(d.id) && d.progress(ctx) >= d.target) d.id,
    ];

/// The next unearned badge in the same series, for "Next: Fortnight 12 / 14".
AchievementDef? nextInSeries(List<AchievementDef> defs, AchievementDef def, PlayerState player) {
  if (def.series == null) return null;
  final series = defs.where((d) => d.series == def.series).toList()
    ..sort((a, b) => a.target.compareTo(b.target));
  for (final d in series) {
    if (d.target > def.target && !player.achievements.containsKey(d.id)) return d;
  }
  return null;
}
