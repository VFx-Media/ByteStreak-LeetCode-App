import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/domain/achievements.dart';
import 'package:bytestreak/screens/achievements/badge_detail_dialog.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';
import 'package:bytestreak/widgets/select_card.dart';

IconData badgeIcon(String key) => switch (key) {
  'flame' => Icons.local_fire_department_rounded,
  'grid' => Icons.grid_view_rounded,
  'key' => Icons.vpn_key_rounded,
  'pointers' => Icons.compare_arrows_rounded,
  'tree' => Icons.account_tree_rounded,
  'graph' => Icons.hub_rounded,
  'brain' => Icons.psychology_rounded,
  'bolt' => Icons.bolt_rounded,
  'target' => Icons.gps_fixed_rounded,
  'trophy' => Icons.emoji_events_rounded,
  'moon' => Icons.nightlight_round,
  _ => Icons.military_tech_rounded,
};

Tone badgeTone(AchievementCategory c) => switch (c) {
  AchievementCategory.streaks => Tone.streak,
  AchievementCategory.mastery => Tone.success,
  AchievementCategory.milestones => Tone.quiz,
};

/// Builds the context achievements are measured against.
AchievementContext achievementContext(WidgetRef ref) => AchievementContext(
  player: ref.watch(currentPlayerProvider),
  path: ref.watch(coursePathProvider),
  now: ref.watch(clockProvider)(),
  rank: ref.watch(leaderboardProvider).value?.myRank,
);

enum _Filter { all, earned, locked }

/// 1.8 Achievements: badges in three sections; locked ones show progress.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  var _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final defs = ref.watch(achievementDefsProvider);
    final player = ref.watch(currentPlayerProvider);
    final ctx = achievementContext(ref);
    final earned = defs.where((d) => player.achievements.containsKey(d.id)).length;

    bool show(AchievementDef d) => switch (_filter) {
      _Filter.all => true,
      _Filter.earned => player.achievements.containsKey(d.id),
      _Filter.locked => !player.achievements.containsKey(d.id),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('$earned of ${defs.length} earned', style: context.text.titleMedium),
              const SizedBox(width: 16),
              SizedBox(width: 260, child: ProgressBar(value: earned / defs.length)),
              const Spacer(),
              for (final f in _Filter.values) ...[
                const SizedBox(width: 8),
                ToggleChip(
                  label: switch (f) {
                    _Filter.all => 'All',
                    _Filter.earned => 'Earned',
                    _Filter.locked => 'Locked',
                  },
                  selected: _filter == f,
                  onTap: () => setState(() => _filter = f),
                ),
              ],
            ],
          ),
          for (final category in AchievementCategory.values)
            if (defs.any((d) => d.category == category && show(d))) ...[
              const SizedBox(height: 24),
              Text(category.label, style: context.text.titleSmall?.copyWith(color: p.muted)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 14.0;
                  final columns = (constraints.maxWidth / 250).floor().clamp(2, 5);
                  final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final d in defs.where((d) => d.category == category && show(d)))
                        SizedBox(
                          width: width,
                          child: _BadgeCard(
                            def: d,
                            earned: player.achievements.containsKey(d.id),
                            progress: d.progress(ctx),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.def, required this.earned, required this.progress});
  final AchievementDef def;
  final bool earned;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tone = badgeTone(def.category);
    return HoverScale(
      scale: 1.02,
      child: Material(
        color: p.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => BadgeDetailDialog(def: def),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                BadgeMedal(icon: badgeIcon(def.icon), tone: tone, earned: earned, size: 64),
                const SizedBox(height: 10),
                Text(
                  def.name,
                  style: context.text.titleSmall?.copyWith(color: earned ? p.ink : p.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 32,
                  child: Text(
                    def.description,
                    style: context.text.bodySmall?.copyWith(color: p.faint),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                if (earned)
                  Tag('Earned', tone: tone, icon: Icons.check_rounded)
                else
                  Row(
                    children: [
                      Expanded(
                        child: ProgressBar(value: progress / def.target, height: 6, color: p.faint),
                      ),
                      const SizedBox(width: 8),
                      Text('$progress/${def.target}', style: context.text.labelSmall?.copyWith(color: p.faint)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The round badge art: full colour when earned, grey when locked.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.icon, required this.tone, required this.earned, this.size = 64});
  final IconData icon;
  final Tone tone;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned ? tone.soft(p) : p.sunken,
        border: Border.all(color: earned ? tone.strong(p).withValues(alpha: 0.4) : p.lineSoft, width: 2),
      ),
      child: Icon(icon, size: size * 0.48, color: earned ? tone.strong(p) : p.faint),
    );
  }
}
