import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/domain/lesson_session.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_colors.dart';
import 'package:bytestreak/theme/app_palette.dart';

/// 1.7 Hints overlay. Progressive hints (10 XP each in lessons and quizzes),
/// plus the worked solution for coding questions, which is free but makes
/// the question worth 0 XP.
class HintsDialog extends ConsumerStatefulWidget {
  const HintsDialog({super.key, required this.question, required this.mode, this.focusSolution = false});

  final Question question;
  final SessionMode mode;

  /// Opened from "View solution": scroll to and offer the solution.
  final bool focusSolution;

  @override
  ConsumerState<HintsDialog> createState() => _HintsDialogState();
}

class _HintsDialogState extends ConsumerState<HintsDialog> {
  final _solutionKey = GlobalKey();
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.focusSolution) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _solutionKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
      });
    }
  }

  void _reveal() {
    final ok = ref.read(playerProvider.notifier).revealHint(widget.question, widget.mode);
    setState(() => _message = ok ? null : 'You need ${ref.read(playerProvider.notifier).hintCost(widget.mode)} XP for a hint.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = widget.question;
    final player = ref.watch(currentPlayerProvider);
    final progress = player.progressOf(q.id);
    final revealed = progress.hintsRevealed.clamp(0, q.hints.length);
    final cost = ref.read(playerProvider.notifier).hintCost(widget.mode);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 14, 10),
              child: Row(
                children: [
                  Expanded(child: Text('Need a nudge?', style: context.text.titleLarge)),
                  IconButton(
                    tooltip: 'Close (Esc)',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(color: p.lineSoft),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Hints', style: context.text.titleSmall),
                    const SizedBox(height: 12),
                    for (var i = 0; i < revealed; i++) ...[
                      _HintCard(index: i, text: q.hints[i]),
                      const SizedBox(height: 10),
                    ],
                    if (revealed < q.hints.length)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 18, color: p.faint),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Hint ${revealed + 1} of ${q.hints.length}',
                                style: context.text.titleSmall?.copyWith(color: p.muted),
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: _reveal,
                              child: Text(cost > 0 ? 'Reveal · $cost XP' : 'Reveal'),
                            ),
                          ],
                        ),
                      )
                    else
                      Text('That\'s every hint for this question.', style: context.text.bodySmall?.copyWith(color: p.faint)),
                    if (_message != null) ...[
                      const SizedBox(height: 8),
                      Text(_message!, style: context.text.bodySmall?.copyWith(color: p.heart)),
                    ],
                    if (q is CodingQuestion) ...[
                      const SizedBox(height: 24),
                      Text('Solution', key: _solutionKey, style: context.text.titleSmall),
                      const SizedBox(height: 12),
                      if (progress.solutionViewed)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.codeBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SelectableText(
                            q.solution,
                            style: const TextStyle(
                              fontFamily: 'Consolas',
                              fontFamilyFallback: ['Cascadia Mono', 'Courier New', 'monospace'],
                              fontSize: 13,
                              height: 1.55,
                              color: AppColors.codeText,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: p.streakSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: widget.focusSolution ? Border.all(color: p.streak, width: 2) : null,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: p.streak),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.mode.awardsXp
                                      ? 'Viewing the solution is free, but this question will then earn 0 XP.'
                                      : 'Viewing the solution is free.',
                                  style: context.text.bodyMedium?.copyWith(color: p.ink),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () => ref.read(playerProvider.notifier).viewSolution(q),
                                child: const Text('Show solution'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.xpSoft, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hint ${index + 1}', style: context.text.labelLarge?.copyWith(color: p.xp, fontSize: 13)),
          const SizedBox(height: 4),
          Text(text, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
