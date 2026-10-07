import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/lesson_session.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/screens/share/share_preview_dialog.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// 1.14 Lesson complete: XP, accuracy, streak, every answer, daily goal,
/// then Review mistakes, Share progress, or Continue.
class LessonCompleteScreen extends ConsumerWidget {
  const LessonCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final result = ref.watch(lastResultProvider);
    final calm = ref.watch(settingsProvider.select((s) => s.reduceMotion));
    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold();
    }

    final path = ref.watch(coursePathProvider);
    final lesson = result.lesson;
    final chapter = lesson == null ? null : path.chapterOfLesson(lesson.id);
    final failedQuiz = result.mode == SessionMode.quiz && !result.passedQuiz;
    final passMark = (GameRules.quizPassMark * 100).round();

    final (IconData icon, Color accent, Color wash, String title, String subtitle) = switch (result.mode) {
      SessionMode.quiz when result.passedQuiz => (
        Icons.workspace_premium_rounded,
        p.quiz,
        p.quizSoft,
        'Quiz passed!',
        _nextChapterLine(path.chapters, chapter),
      ),
      SessionMode.quiz => (
        Icons.refresh_rounded,
        p.heart,
        p.heartSoft,
        'Not quite: ${formatPercent(result.accuracy)}',
        'You need $passMark% to pass. Review your mistakes and try again.',
      ),
      SessionMode.review => (
        Icons.task_alt_rounded,
        p.xp,
        p.xpSoft,
        'Review complete',
        'No hearts lost, no XP: just practice.',
      ),
      SessionMode.practice => (
        Icons.favorite_rounded,
        p.heart,
        p.heartSoft,
        '+1 heart earned!',
        'Back to the path whenever you\'re ready.',
      ),
      SessionMode.replay => (
        Icons.replay_rounded,
        p.xp,
        p.xpSoft,
        'Practice complete',
        '${chapter?.title ?? ''} · ${lesson?.title ?? ''}',
      ),
      SessionMode.lesson => (
        Icons.emoji_events_rounded,
        p.streak,
        p.successSoft,
        'Lesson complete!',
        '${chapter?.title ?? ''} · ${lesson?.title ?? ''}',
      ),
    };

    Widget badge = Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: p.background,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 24)],
      ),
      child: Icon(icon, size: 56, color: accent),
    );
    if (!calm && !failedQuiz) {
      badge = badge
          .animate()
          .scale(begin: const Offset(0.4, 0.4), duration: 500.ms, curve: Curves.easeOutBack)
          .fadeIn();
    }

    final canReview =
        result.missed.isNotEmpty &&
        (result.mode == SessionMode.lesson || result.mode == SessionMode.quiz || result.mode == SessionMode.replay);

    void done() => context.go('/home');

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter): done},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: p.background,
          body: Stack(
            children: [
              Positioned(top: 0, left: 0, right: 0, height: 300, child: ColoredBox(color: wash)),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        badge,
                        const SizedBox(height: 20),
                        Text(title, style: context.text.headlineLarge, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: context.text.bodyLarge?.copyWith(color: p.muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _CountUpTile(
                                value: result.xpEarned,
                                label: 'XP earned',
                                color: p.quiz,
                                animate: !calm,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                value: formatPercent(result.accuracy),
                                label: 'Accuracy',
                                color: failedQuiz ? p.heart : p.success,
                                centered: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                value: '${result.streak}',
                                label: 'Day streak',
                                color: p.streak,
                                centered: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppCard(
                          title: 'Your answers',
                          action: Text(
                            '${result.correct} correct · ${result.outcomes.length - result.correct} wrong',
                            style: context.text.bodySmall?.copyWith(color: p.muted),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (i, o) in result.outcomes.indexed)
                                Tooltip(
                                  message: o.question.prompt,
                                  child: Container(
                                    width: 78,
                                    height: 54,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: o.correct ? p.successSoft : p.heartSoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          o.correct ? 'PASS' : 'MISS',
                                          style: context.text.labelMedium?.copyWith(
                                            color: o.correct ? p.success : p.heart,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Q${i + 1}',
                                          style: context.text.labelSmall?.copyWith(
                                            color: o.correct ? p.success : p.heart,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          child: Row(
                            children: [
                              Text('Daily goal', style: context.text.titleSmall),
                              const SizedBox(width: 20),
                              Expanded(child: ProgressBar(value: result.dailyGoalDone / result.dailyGoalTarget)),
                              const SizedBox(width: 14),
                              Text(
                                '${math.min(result.dailyGoalDone, result.dailyGoalTarget)} / ${result.dailyGoalTarget} done',
                                style: context.text.labelMedium?.copyWith(
                                  color: result.dailyGoalDone >= result.dailyGoalTarget ? p.success : p.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (result.newAchievements.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          AppCard(
                            color: p.streakSoft,
                            borderColor: p.streakSoft,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.military_tech_rounded, color: p.streak),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'New badge${result.newAchievements.length > 1 ? 's' : ''}: ${result.newAchievements.join(', ')}',
                                    style: context.text.titleSmall?.copyWith(color: p.ink),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/achievements'),
                                  child: const Text('See badges'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (canReview) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.go('/play/${lesson?.id ?? 'review'}?mode=review'),
                                  icon: const Icon(Icons.replay_rounded, size: 18),
                                  label: Text(
                                    'Review ${result.missed.length} mistake${result.missed.length == 1 ? '' : 's'}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => showSharePreview(context),
                                icon: const Icon(Icons.ios_share_rounded, size: 18),
                                label: const Text('Share progress'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Tooltip(
                                message: 'Enter',
                                child: FilledButton(onPressed: done, child: const Text('Continue')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _nextChapterLine(List<Chapter> chapters, Chapter? chapter) {
    final i = chapter == null ? -1 : chapters.indexOf(chapter);
    if (i < 0) return '';
    if (i + 1 >= chapters.length) return 'You finished LeetCode Mastery!';
    return '${chapters[i + 1].title} is unlocked.';
  }
}

class _CountUpTile extends StatelessWidget {
  const _CountUpTile({required this.value, required this.label, required this.color, required this.animate});
  final int value;
  final String label;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate) return StatTile(value: '+$value', label: label, color: color, centered: true);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => StatTile(value: '+$v', label: label, color: color, centered: true),
    );
  }
}
