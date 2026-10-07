import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// The frame around every main screen: nav rail on the left, top bar above,
/// and the current screen ([child]) filling the rest.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavRail(location: location),
          Expanded(
            child: Column(
              children: [
                TopBar(location: location),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

const _mainItems = [
  _NavItem('/home', 'Home', Icons.home_rounded),
  _NavItem('/achievements', 'Badges', Icons.military_tech_rounded),
  _NavItem('/leaderboard', 'Ranks', Icons.leaderboard_rounded),
  _NavItem('/stats', 'Stats', Icons.insights_rounded),
];
const _settingsItem = _NavItem('/settings', 'Settings', Icons.settings_rounded);

class NavRail extends StatelessWidget {
  const NavRail({super.key, required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.lineSoft)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Tooltip(
            message: 'ByteStreak',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.go('/home'),
              child: const LogoMark(size: 40),
            ),
          ),
          const SizedBox(height: 22),
          for (final item in _mainItems) ...[
            _RailButton(item: item, selected: location.startsWith(item.path)),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          _RailButton(item: _settingsItem, selected: location.startsWith(_settingsItem.path)),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.item, required this.selected});
  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.success : p.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Material(
        color: selected ? p.successSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(item.path),
          child: SizedBox(
            width: 64,
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: context.text.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Title on the left; streak, hearts, XP, theme toggle and avatar on the right.
class TopBar extends ConsumerWidget {
  const TopBar({super.key, required this.location});
  final String location;

  String _title(WidgetRef ref) {
    if (location.startsWith('/achievements')) return 'Achievements';
    if (location.startsWith('/leaderboard')) return 'Leaderboard';
    if (location.startsWith('/stats')) return 'Your stats';
    if (location.startsWith('/settings')) return 'Settings';
    if (location.startsWith('/profile')) return 'Profile';
    final current = ref.watch(pathProgressProvider).current;
    final chapter = current == null ? null : ref.watch(coursePathProvider).chapterOfLesson(current.id);
    return chapter?.title ?? ref.watch(coursePathProvider).title;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final player = ref.watch(currentPlayerProvider);
    final brightness = Theme.of(context).brightness;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: p.background,
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(_title(ref), style: context.text.titleLarge, overflow: TextOverflow.ellipsis),
          ),
          const StreakPill(),
          const SizedBox(width: 10),
          const HeartsPill(),
          const SizedBox(width: 10),
          const XpPill(),
          const SizedBox(width: 12),
          Tooltip(
            message: brightness == Brightness.dark ? 'Switch to light mode' : 'Switch to dark mode',
            child: IconButton.outlined(
              style: IconButton.styleFrom(side: BorderSide(color: p.line)),
              onPressed: () => ref.read(settingsProvider.notifier).toggleBrightness(brightness),
              icon: Icon(brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Profile',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go('/profile'),
              child: AvatarView(index: player.profile.avatarIndex, size: 36, selected: location.startsWith('/profile')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.tone, required this.tooltip});
  final IconData icon;
  final String label;
  final Tone tone;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: tone.soft(p), borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tone.strong(p)),
            const SizedBox(width: 6),
            Text(label, style: context.text.labelLarge?.copyWith(color: tone.strong(p), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class StreakPill extends ConsumerWidget {
  const StreakPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final now = ref.watch(clockProvider)();
    final streak = GameRules.effectiveStreak(streak: player.streak, lastPracticeDay: player.lastPracticeDay, now: now);
    final doneToday =
        player.lastPracticeDay != null && GameRules.dayOf(player.lastPracticeDay!) == GameRules.dayOf(now);
    return _Pill(
      icon: Icons.local_fire_department_rounded,
      label: '$streak',
      tone: Tone.streak,
      tooltip: doneToday
          ? '$streak-day streak. Done for today!'
          : '$streak-day streak. Finish a lesson today to keep it.',
    );
  }
}

/// Also keeps hearts regenerating while the app is open.
class HeartsPill extends ConsumerStatefulWidget {
  const HeartsPill({super.key});

  @override
  ConsumerState<HeartsPill> createState() => _HeartsPillState();
}

class _HeartsPillState extends ConsumerState<HeartsPill> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => ref.read(playerProvider.notifier).tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);
    final now = ref.watch(clockProvider)();
    final next = player.nextHeartAt;
    return _Pill(
      icon: Icons.favorite_rounded,
      label: '${player.hearts}/${GameRules.maxHearts}',
      tone: Tone.heart,
      tooltip: next == null ? 'Hearts full' : 'Next heart in ${formatCountdown(next.difference(now))}',
    );
  }
}

class XpPill extends ConsumerWidget {
  const XpPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(currentPlayerProvider.select((p) => p.xp));
    final level = GameRules.levelForXp(xp);
    final toNext = GameRules.xpForLevel(level + 1) - xp;
    return _Pill(
      icon: Icons.diamond_rounded,
      label: '${formatNumber(xp)} XP',
      tone: Tone.xp,
      tooltip: 'Level $level · $toNext XP to level ${level + 1}',
    );
  }
}
