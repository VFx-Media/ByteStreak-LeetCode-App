import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/domain/stats.dart';
import 'package:bytestreak/screens/leaderboard/leaderboard_screen.dart';
import 'package:bytestreak/screens/profile/edit_profile_dialog.dart';
import 'package:bytestreak/screens/share/share_preview_dialog.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// 1.12 Profile: who you are, your numbers, and what you did recently.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final player = ref.watch(currentPlayerProvider);
    final now = ref.watch(clockProvider)();
    final stats = PlayerStats.from(player, ref.watch(coursePathProvider), now);
    final rank = ref.watch(leaderboardProvider).value?.myRank;
    final league = ref.watch(leagueProvider);
    final level = GameRules.levelForXp(player.xp);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                AvatarView(index: player.profile.avatarIndex, size: 104),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.profile.username, style: context.text.headlineMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Tag('Level $level', tone: Tone.xp),
                          if (league != League.unranked)
                            Tooltip(
                              message: 'From your global rank',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: leagueColor(league, p).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  league.label,
                                  style: context.text.labelMedium?.copyWith(color: leagueColor(league, p)),
                                ),
                              ),
                            ),
                          Tag('Member since ${formatMonthYear(player.profile.memberSince)}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProgressBar(value: GameRules.levelProgress(player.xp), color: p.xp, height: 6),
                            const SizedBox(height: 4),
                            Text(
                              '${GameRules.xpForLevel(level + 1) - player.xp} XP to level ${level + 1}',
                              style: context.text.bodySmall?.copyWith(color: p.faint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(onPressed: () => showEditProfile(context), child: const Text('Edit profile')),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => showSharePreview(context),
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Share progress'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${stats.streak}',
                  label: 'Day streak',
                  color: p.streak,
                  centered: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatTile(
                  icon: Icons.diamond_rounded,
                  value: formatNumber(player.xp),
                  label: 'Total XP',
                  color: p.xp,
                  centered: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatTile(
                  icon: Icons.public_rounded,
                  value: rank == null ? '—' : '#${formatNumber(rank)}',
                  label: rank == null ? 'Global rank (hidden)' : 'Global rank',
                  color: p.success,
                  centered: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatTile(
                  icon: Icons.task_alt_rounded,
                  value: formatNumber(stats.solved),
                  label: 'Solved',
                  color: p.quiz,
                  centered: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            title: 'Recent activity',
            child: player.activity.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Finish your first lesson and it shows up here.',
                      style: context.text.bodyMedium?.copyWith(color: p.muted),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: [
                      for (final a in player.activity.take(8)) ...[
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle, border: Border.all(color: p.lineSoft)),
                              child: Icon(_activityIcon(a.kind), size: 18, color: _activityColor(a.kind, p)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                  Text(
                                    '${a.detail} · ${timeAgo(a.at, now)}',
                                    style: context.text.bodySmall?.copyWith(color: p.faint),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static IconData _activityIcon(ActivityKind k) => switch (k) {
        ActivityKind.solved => Icons.check_circle_rounded,
        ActivityKind.badge => Icons.military_tech_rounded,
        ActivityKind.lesson => Icons.menu_book_rounded,
        ActivityKind.quiz => Icons.workspace_premium_rounded,
      };

  static Color _activityColor(ActivityKind k, AppPalette p) => switch (k) {
        ActivityKind.solved => p.success,
        ActivityKind.badge => p.streak,
        ActivityKind.lesson => p.xp,
        ActivityKind.quiz => p.quiz,
      };
}
