import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/domain/path_progress.dart';
import 'package:bytestreak/router/app_router.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// 1.3 Home / LeetCode Mastery. The path *is* the home screen: the node you
/// left off on is visible straight away and resuming is one click.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.focusChapterId});

  /// Scroll to this chapter on open (the Stats screen's "Practice" button).
  final String? focusChapterId;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _chapterKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToFocus() {
    final path = ref.read(coursePathProvider);
    final current = ref.read(pathProgressProvider).current;
    final id = widget.focusChapterId ?? (current == null ? null : path.chapterOfLesson(current.id)?.id);
    final ctx = id == null ? null : _chapterKeys[id]?.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(ctx, alignment: 0.05, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final path = ref.watch(coursePathProvider);
    final progress = ref.watch(pathProgressProvider);
    final calm = ref.watch(settingsProvider.select((s) => s.reduceMotion));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Scrollbar(
                      controller: _scroll,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            for (final (i, chapter) in path.chapters.indexed)
                              _ChapterSection(
                                key: _chapterKeys.putIfAbsent(chapter.id, GlobalKey.new),
                                chapter: chapter,
                                previous: i == 0 ? null : path.chapters[i - 1],
                                progress: progress,
                                mirror: i.isOdd,
                                calm: calm,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // A footer, not floating over the path: floating, it covered
                  // nodes and chapter titles as they scrolled underneath.
                  const _MapKey(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const SizedBox(width: 340, child: _Sidebar()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The path
// ---------------------------------------------------------------------------

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({
    super.key,
    required this.chapter,
    required this.previous,
    required this.progress,
    required this.mirror,
    required this.calm,
  });

  final Chapter chapter;
  final Chapter? previous;
  final PathProgress progress;
  final bool mirror;
  final bool calm;

  static const _rowHeight = 122.0;

  @override
  Widget build(BuildContext context) {
    final nodes = chapter.nodes;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          _ChapterBanner(chapter: chapter, previous: previous, progress: progress),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final reach = math.min(130.0, width / 2 - 80);
              // Zig-zag: lessons alternate left and right; the quiz sits in the
              // middle. Alternate chapters start on opposite sides.
              Offset centre(int i) {
                final swing = i == nodes.length - 1 ? 0.0 : (i.isEven ? -0.7 : 0.7);
                return Offset(width / 2 + (mirror ? -1 : 1) * swing * reach, 56 + i * _rowHeight);
              }

              final centres = [for (var i = 0; i < nodes.length; i++) centre(i)];
              return SizedBox(
                height: 56 + (nodes.length - 1) * _rowHeight + 76,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ConnectorPainter(
                          points: centres,
                          done: [for (final n in nodes) progress.stateOf(n.id) == NodeState.done],
                          palette: context.palette,
                        ),
                      ),
                    ),
                    for (var i = 0; i < nodes.length; i++)
                      Positioned(
                        left: centres[i].dx - 70,
                        top: centres[i].dy - 44,
                        width: 140,
                        child: _PathNode(
                          lesson: nodes[i],
                          index: i,
                          chapter: chapter,
                          state: progress.stateOf(nodes[i].id),
                          calm: calm,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChapterBanner extends StatelessWidget {
  const _ChapterBanner({required this.chapter, required this.previous, required this.progress});
  final Chapter chapter;
  final Chapter? previous;
  final PathProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final unlocked = progress.isChapterUnlocked(chapter);
    final complete = progress.isChapterComplete(chapter);
    final done = progress.lessonsDone(chapter);
    final (tone, status, icon) = complete
        ? (Tone.success, 'Complete', Icons.check_circle_rounded)
        : unlocked
        ? (Tone.xp, '$done of ${chapter.lessons.length} lessons', Icons.play_circle_fill_rounded)
        : (Tone.neutral, 'Pass the ${previous?.title} quiz to unlock', Icons.lock_rounded);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: unlocked ? p.surface : p.sunken.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.lineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHAPTER ${chapter.number}',
                  style: context.text.labelSmall?.copyWith(color: p.faint, letterSpacing: 1.2),
                ),
                const SizedBox(height: 2),
                Text(chapter.title, style: context.text.titleLarge?.copyWith(color: unlocked ? p.ink : p.muted)),
                const SizedBox(height: 2),
                Text(chapter.summary, style: context.text.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Tag(status, tone: tone, icon: icon),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.lesson,
    required this.index,
    required this.chapter,
    required this.state,
    required this.calm,
  });

  final Lesson lesson;
  final int index;
  final Chapter chapter;
  final NodeState state;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final quiz = lesson.isQuiz;
    final current = state == NodeState.current;
    final size = current ? 84.0 : (quiz ? 76.0 : 68.0);
    final accent = quiz ? p.quiz : p.success;
    final accentSoft = quiz ? p.quizSoft : p.successSoft;

    final (Color fill, Color border, double borderWidth) = switch (state) {
      NodeState.done => (accentSoft, accentSoft, 1.0),
      NodeState.current => (accent, accent, 2.0),
      NodeState.available => (p.background, accent, 2.0),
      NodeState.locked => (p.sunken, p.lineSoft, 1.0),
    };

    final Widget face = switch (state) {
      NodeState.done => Icon(Icons.check_rounded, color: accent, size: 30),
      NodeState.current => Text(
        quiz ? 'QUIZ' : 'START',
        style: context.text.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
      NodeState.available => Icon(quiz ? Icons.star_rounded : Icons.play_arrow_rounded, color: accent, size: 30),
      NodeState.locked => Icon(Icons.lock_rounded, color: p.faint, size: 24),
    };

    final tooltip = switch (state) {
      NodeState.done => '${lesson.title} · done. Click to replay (practice, no XP).',
      NodeState.current => '${lesson.title} · ${lesson.questions.length} questions. Click to start.',
      NodeState.available =>
        quiz
            ? 'Pass with 80% to unlock the next chapter, even if you skip lessons.'
            : '${lesson.title} · ${lesson.questions.length} questions.',
      NodeState.locked =>
        index == 0 ? 'Locked: finish the previous chapter first.' : 'Locked: finish the lesson before this one.',
    };

    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: borderWidth),
        boxShadow: current ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: 2)] : null,
      ),
      child: face,
    );
    if (current && !calm) {
      circle = circle
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1, end: 1.06, duration: 900.ms, curve: Curves.easeInOut);
    }

    final enabled = state != NodeState.locked;
    return Semantics(
      button: enabled,
      label: '${lesson.title}, ${state.name}',
      child: Column(
        children: [
          SizedBox(
            height: 88,
            child: Center(
              child: Tooltip(
                message: tooltip,
                child: HoverScale(
                  enabled: enabled,
                  child: GestureDetector(
                    onTap: enabled
                        ? () => context.push(
                            routeForNode(lessonId: lesson.id, isQuiz: quiz, done: state == NodeState.done),
                          )
                        : null,
                    child: circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quiz ? 'Chapter quiz' : lesson.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium?.copyWith(
              color: state == NodeState.locked ? p.faint : p.muted,
              fontWeight: current ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed lines between node centres; solid green once both ends are done.
class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({required this.points, required this.done, required this.palette});
  final List<Offset> points;
  final List<bool> done;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final complete = done[i] && done[i + 1];
      final paint = Paint()
        ..color = complete ? palette.success.withValues(alpha: 0.45) : palette.line
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
      if (complete) {
        canvas.drawPath(path, paint);
      } else {
        for (final metric in path.computeMetrics()) {
          for (var d = 0.0; d < metric.length; d += 14) {
            canvas.drawPath(metric.extractPath(d, math.min(d + 7, metric.length)), paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.points != points || old.palette != palette || old.done.toString() != done.toString();
}

class _MapKey extends StatelessWidget {
  const _MapKey();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget item(Color fill, Color border, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: context.text.bodySmall?.copyWith(color: p.muted)),
      ],
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.lineSoft)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          item(p.successSoft, p.successSoft, 'Done'),
          item(p.success, p.success, 'Current'),
          item(p.sunken, p.lineSoft, 'Locked'),
          item(p.quizSoft, p.quiz, 'Quiz'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_ContinueCard(), SizedBox(height: 16), _StreakCard()],
      ),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final progress = ref.watch(pathProgressProvider);
    final path = ref.watch(coursePathProvider);
    final current = progress.current;

    if (current == null) {
      return AppCard(
        borderColor: p.success,
        borderWidth: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.emoji_events_rounded, color: p.streak, size: 32),
            const SizedBox(height: 8),
            Text('You finished ${path.title}!', style: context.text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Replay any lesson to practise. New chapters appear here as they are added.',
              style: context.text.bodyMedium?.copyWith(color: p.muted),
            ),
          ],
        ),
      );
    }

    final chapter = path.chapterOfLesson(current.id)!;
    final nodesDone = chapter.nodes.where((n) => progress.stateOf(n.id) == NodeState.done).length;
    final position = current.isQuiz
        ? 'Chapter quiz'
        : 'Lesson ${chapter.lessons.indexOf(current) + 1} of ${chapter.lessons.length}';

    return AppCard(
      borderColor: p.success,
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Continue where you left off', style: context.text.labelMedium?.copyWith(color: p.success)),
          const SizedBox(height: 8),
          Text(current.isQuiz ? '${chapter.title} quiz' : current.title, style: context.text.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Tag(position, tone: current.isQuiz ? Tone.quiz : Tone.success),
              Tag('${current.questions.length} questions'),
              Tag(chapter.title, tone: Tone.xp),
            ],
          ),
          const SizedBox(height: 14),
          ProgressBar(value: nodesDone / chapter.nodes.length),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push(routeForNode(lessonId: current.id, isQuiz: current.isQuiz, done: false)),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final player = ref.watch(currentPlayerProvider);
    final now = ref.watch(clockProvider)();
    final today = GameRules.dayOf(now);
    final streak = GameRules.effectiveStreak(streak: player.streak, lastPracticeDay: player.lastPracticeDay, now: now);

    // Days covered by the current streak.
    final practiced = <DateTime>{};
    if (streak > 0 && player.lastPracticeDay != null) {
      final last = GameRules.dayOf(player.lastPracticeDay!);
      for (var i = 0; i < streak; i++) {
        practiced.add(DateTime(last.year, last.month, last.day - i));
      }
    }
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final answeredToday = player.answers.where((a) => GameRules.dayOf(a.at) == today).length;
    final goal = player.profile.dailyGoal.questions;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: p.streak, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$streak day streak',
                  style: context.text.titleMedium?.copyWith(color: p.streak),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Best: ${math.max(player.longestStreak, streak)}',
                style: context.text.bodySmall?.copyWith(color: p.faint),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                () {
                  final day = DateTime(monday.year, monday.month, monday.day + i);
                  final done = practiced.contains(day);
                  final isToday = day == today;
                  return Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? p.streakSoft : p.surface,
                          border: Border.all(color: isToday ? p.streak : p.lineSoft, width: isToday ? 2 : 1),
                        ),
                        child: done ? Icon(Icons.local_fire_department_rounded, size: 18, color: p.streak) : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _days[i],
                        style: context.text.labelSmall?.copyWith(
                          color: isToday ? p.streak : p.faint,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }(),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: p.lineSoft),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Daily goal', style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(
                '${math.min(answeredToday, goal)} / $goal questions',
                style: context.text.labelMedium?.copyWith(color: answeredToday >= goal ? p.success : p.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(value: answeredToday / goal),
        ],
      ),
    );
  }
}
