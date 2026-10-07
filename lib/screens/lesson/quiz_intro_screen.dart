import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/screens/lesson/out_of_hearts_dialog.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// 1.4 Chapter quiz intro: what's at stake before the quiz starts.
class QuizIntroScreen extends ConsumerWidget {
  const QuizIntroScreen({super.key, required this.lessonId});
  final String lessonId;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    if (ref.read(currentPlayerProvider).hearts == 0) {
      final choice = await showDialog<OutOfHeartsChoice>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const OutOfHeartsDialog(),
      );
      if (!context.mounted) return;
      if (choice == OutOfHeartsChoice.practice) return context.go('/practice');
      if (choice != OutOfHeartsChoice.refilled && choice != OutOfHeartsChoice.regenerated) return;
    }
    context.pushReplacement('/play/$lessonId?mode=quiz');
  }

  void _back(BuildContext context) => context.canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final path = ref.watch(coursePathProvider);
    final lesson = path.lesson(lessonId);
    final chapter = path.chapterOfLesson(lessonId);
    if (lesson == null || chapter == null) {
      return Scaffold(
        body: Center(child: FilledButton(onPressed: () => context.go('/home'), child: const Text('Back to home'))),
      );
    }
    final i = path.chapters.indexOf(chapter);
    final next = i + 1 < path.chapters.length ? path.chapters[i + 1] : null;
    final hearts = ref.watch(currentPlayerProvider.select((pl) => pl.hearts));
    final count = lesson.questions.length;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () => _start(context, ref),
        const SingleActivator(LogicalKeyboardKey.escape): () => _back(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AppCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: p.quizSoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.quiz, width: 2),
                        ),
                        child: Icon(Icons.star_rounded, color: p.quiz, size: 42),
                      ),
                      const SizedBox(height: 18),
                      Text('${chapter.title} — Chapter quiz', style: context.text.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        next == null
                            ? 'Pass this to finish LeetCode Mastery.'
                            : 'Pass this and ${next.title} unlocks: you can jump straight there without finishing every lesson.',
                        style: context.text.bodyMedium?.copyWith(color: p.muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(child: _Fact(value: '$count', label: 'questions')),
                          const SizedBox(width: 12),
                          Expanded(child: _Fact(value: '~${(count * 0.8).ceil()} min', label: 'estimated')),
                          const SizedBox(width: 12),
                          Expanded(child: _Fact(value: '${(GameRules.quizPassMark * 100).round()}%', label: 'to pass')),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: p.heartSoft, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Icon(Icons.favorite_rounded, color: p.heart, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                hearts == 0
                                    ? 'You\'re out of hearts. Earn one or refill to start.'
                                    : 'Wrong answers cost a heart. You have $hearts left.',
                                style: context.text.bodyMedium?.copyWith(color: p.heart, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: p.quiz),
                          onPressed: () => _start(context, ref),
                          child: const Text('Start quiz'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(onPressed: () => _back(context), child: const Text('Not right now')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: context.text.titleLarge),
          Text(label, style: context.text.bodySmall?.copyWith(color: p.muted)),
        ],
      ),
    );
  }
}
