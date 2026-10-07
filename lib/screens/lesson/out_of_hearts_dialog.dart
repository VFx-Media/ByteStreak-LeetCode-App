import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

enum OutOfHeartsChoice { practice, refilled, regenerated, home }

/// 1.15 Out of hearts. Counts down to the next heart, and offers two ways
/// forward: practise to earn one (free) or refill for 120 XP.
class OutOfHeartsDialog extends ConsumerStatefulWidget {
  const OutOfHeartsDialog({super.key});

  @override
  ConsumerState<OutOfHeartsDialog> createState() => _OutOfHeartsDialogState();
}

class _OutOfHeartsDialogState extends ConsumerState<OutOfHeartsDialog> {
  Timer? _timer;
  String? _message;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(playerProvider.notifier).tick();
      if (!mounted) return;
      if (ref.read(currentPlayerProvider).hearts > 0) {
        Navigator.pop(context, OutOfHeartsChoice.regenerated);
      } else {
        setState(() {}); // redraw the countdown
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refill() {
    if (ref.read(playerProvider.notifier).refillHearts()) {
      Navigator.pop(context, OutOfHeartsChoice.refilled);
    } else {
      setState(() => _message = 'You need ${GameRules.heartRefillCost} XP to refill.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final player = ref.watch(currentPlayerProvider);
    final now = ref.read(clockProvider)();
    final next = player.nextHeartAt ?? now.add(GameRules.heartRegen);
    final untilNext = next.difference(now);
    final heartsMissing = GameRules.maxHearts - player.hearts;
    final untilFull = untilNext + GameRules.heartRegen * (heartsMissing - 1);
    final elapsed = 1 - untilNext.inSeconds / GameRules.heartRegen.inSeconds;
    final canRefill = player.xp >= GameRules.heartRefillCost;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < GameRules.maxHearts; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.heart_broken_rounded, color: p.heart.withValues(alpha: 0.35), size: 30),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text('You\'re out of hearts', style: context.text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                'Hearts refill on their own, or earn one back by practising something you already know.',
                style: context.text.bodyMedium?.copyWith(color: p.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: p.heartSoft, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(
                      'Next heart in ${formatCountdown(untilNext)}',
                      style: context.text.titleLarge?.copyWith(color: p.heart),
                    ),
                    const SizedBox(height: 10),
                    ProgressBar(value: elapsed, color: p.heart, track: p.background),
                    const SizedBox(height: 6),
                    Text(
                      'Full refill in ${formatCountdown(untilFull)}',
                      style: context.text.bodySmall?.copyWith(color: p.heart),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Option(
                icon: Icons.psychology_rounded,
                title: 'Practice to earn a heart',
                subtitle: 'Answer ${GameRules.practiceSize} review questions',
                tag: const Tag('Free', tone: Tone.success),
                onTap: () => Navigator.pop(context, OutOfHeartsChoice.practice),
              ),
              const SizedBox(height: 10),
              _Option(
                icon: Icons.favorite_rounded,
                title: 'Refill now',
                subtitle: canRefill
                    ? 'Restores all ${GameRules.maxHearts} hearts. Spending XP can cost leaderboard places.'
                    : 'You have ${formatNumber(player.xp)} XP',
                tag: Tag('−${GameRules.heartRefillCost} XP', tone: Tone.xp),
                onTap: canRefill ? _refill : null,
              ),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(_message!, style: context.text.bodySmall?.copyWith(color: p.heart), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => Navigator.pop(context, OutOfHeartsChoice.home),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: p.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: p.background, shape: BoxShape.circle, border: Border.all(color: p.lineSoft)),
                  child: Icon(icon, size: 20, color: p.muted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleSmall),
                      Text(subtitle, style: context.text.bodySmall?.copyWith(color: p.faint)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                tag,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
