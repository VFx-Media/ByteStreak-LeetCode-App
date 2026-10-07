import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// 1.9 Leaderboard: one global list ranked by XP. Your league comes from
/// your rank (Gold = top 10, Silver = 11-50, Bronze = 51+). No friends, no
/// search, no weekly seasons (plan §2).
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final _meKey = GlobalKey();

  void _jumpToMe() {
    final ctx = _meKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.4, duration: const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final page = ref.watch(leaderboardProvider);
    final shareStats = ref.watch(settingsProvider.select((s) => s.shareStats));

    // Tell the player controller our rank, so the Gold League badge unlocks.
    ref.listen(leaderboardProvider, (_, next) {
      final rank = next.value?.myRank;
      if (rank != null) ref.read(playerProvider.notifier).recordRank(rank);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: p.streakSoft, shape: BoxShape.circle),
                      child: Icon(Icons.emoji_events_rounded, color: p.streak, size: 36),
                    ),
                    const SizedBox(height: 10),
                    Text('Leaderboard', style: context.text.headlineSmall),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: p.line, width: 2),
                      ),
                      child: Text('Global', style: context.text.labelLarge),
                    ),
                    const SizedBox(height: 12),
                    page.when(
                      data: (data) => _Summary(page: data, onJump: _jumpToMe),
                      loading: () => const SizedBox(height: 20),
                      error: (_, _) => const SizedBox(height: 20),
                    ),
                  ],
                ),
              ),
              if (!shareStats) ...[
                const SizedBox(height: 12),
                AppCard(
                  color: p.xpSoft,
                  borderColor: p.xpSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_off_rounded, color: p.xp, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You\'re hidden from the leaderboard, so you have no rank or league.',
                          style: context.text.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.read(settingsProvider.notifier).setShareStats(true),
                        child: Text('Show me', style: TextStyle(color: p.xp)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              page.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => AppCard(
                  child: Column(
                    children: [
                      Text('Couldn\'t load the leaderboard.', style: context.text.titleMedium),
                      const SizedBox(height: 6),
                      Text('$e', style: context.text.bodySmall?.copyWith(color: p.muted)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(leaderboardProvider),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
                data: (data) => AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      for (final e in data.entries) ...[
                        if (e.rank == 1) const _TierHeader(league: League.gold, range: 'Top 10'),
                        if (e.rank == GameRules.goldCutoff + 1)
                          const _TierHeader(league: League.silver, range: '11–50'),
                        if (e.rank == GameRules.silverCutoff + 1)
                          const _TierHeader(league: League.bronze, range: '51 and below'),
                        _Row(key: e.isMe ? _meKey : null, entry: e),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.page, required this.onJump});
  final LeaderboardPage page;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rank = page.myRank;
    if (rank == null) {
      return Text('${page.totalPlayers} players', style: context.text.bodyMedium?.copyWith(color: p.muted));
    }
    final league = GameRules.leagueForRank(rank);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'You\'re #$rank of ${page.totalPlayers} · ${league.label}',
          style: context.text.bodyMedium?.copyWith(color: p.muted),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onJump,
          child: Text('Jump to you', style: TextStyle(color: p.xp)),
        ),
      ],
    );
  }
}

Color leagueColor(League league, AppPalette p) => switch (league) {
  League.gold => p.streak,
  League.silver => p.muted,
  League.bronze => const Color(0xFFB07A4A),
  League.unranked => p.faint,
};

class _TierHeader extends StatelessWidget {
  const _TierHeader({required this.league, required this.range});
  final League league;
  final String range;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = leagueColor(league, p);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(league.label, style: context.text.labelLarge?.copyWith(color: color, fontSize: 13)),
          const SizedBox(width: 8),
          Text(range, style: context.text.bodySmall?.copyWith(color: p.faint)),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: p.lineSoft)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({super.key, required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final league = GameRules.leagueForRank(entry.rank);
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: entry.isMe ? p.successSoft : null,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${entry.rank}',
              style: context.text.titleSmall?.copyWith(color: league == League.gold ? p.success : p.faint),
            ),
          ),
          AvatarView(index: entry.avatarIndex, size: 34),
          const SizedBox(width: 14),
          Text(
            entry.username,
            style: context.text.bodyLarge?.copyWith(fontWeight: entry.isMe ? FontWeight.w700 : FontWeight.w400),
          ),
          if (entry.isMe) ...[const SizedBox(width: 10), const Tag('You', tone: Tone.success)],
          const Spacer(),
          Text('${formatNumber(entry.xp)} XP', style: context.text.titleSmall?.copyWith(color: p.muted)),
        ],
      ),
    );
  }
}
