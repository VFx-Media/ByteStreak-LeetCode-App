import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/domain/achievements.dart';
import 'package:bytestreak/screens/achievements/achievements_screen.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// 1.16 Badge detail: what it's for, when you earned it, and progress to the
/// next tier in its series.
class BadgeDetailDialog extends ConsumerWidget {
  const BadgeDetailDialog({super.key, required this.def});
  final AchievementDef def;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final player = ref.watch(currentPlayerProvider);
    final defs = ref.watch(achievementDefsProvider);
    final ctx = achievementContext(ref);
    final earnedAt = player.achievements[def.id];
    final tone = badgeTone(def.category);
    final next = earnedAt == null ? null : nextInSeries(defs, def, player);
    final tracking = earnedAt == null ? def : next;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Achievement', style: context.text.labelLarge?.copyWith(color: p.muted, fontSize: 13)),
                  const Spacer(),
                  IconButton(tooltip: 'Close (Esc)', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    BadgeMedal(icon: badgeIcon(def.icon), tone: tone, earned: earnedAt != null, size: 120),
                    const SizedBox(height: 16),
                    Text(def.name, style: context.text.headlineSmall),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        Tag(def.category.label, tone: tone),
                        if (earnedAt != null) Tag('Earned ${formatDate(earnedAt)}', tone: Tone.success, icon: Icons.check_rounded),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      def.description,
                      style: context.text.bodyMedium?.copyWith(color: p.muted),
                      textAlign: TextAlign.center,
                    ),
                    if (tracking != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.line),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                BadgeMedal(icon: badgeIcon(tracking.icon), tone: tone, earned: false, size: 32),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tracking == def ? 'Progress' : 'Next: ${tracking.name}',
                                    style: context.text.titleSmall,
                                  ),
                                ),
                                Text(
                                  '${tracking.progress(ctx)} / ${tracking.target}${tracking.unit.isEmpty ? '' : ' ${tracking.unit}'}',
                                  style: context.text.labelMedium?.copyWith(color: p.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ProgressBar(value: tracking.progress(ctx) / tracking.target, color: tone.strong(p)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
