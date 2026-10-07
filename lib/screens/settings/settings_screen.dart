import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/screens/profile/edit_profile_dialog.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// 1.11 Settings. Every change is saved immediately.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Your progress is saved to your account. Log back in any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.palette.heart),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(playerProvider.notifier).signOut();
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref, int minutes) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) ref.read(settingsProvider.notifier).setReminderTime(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(settingsProvider);
    final settings = ref.read(settingsProvider.notifier);
    final player = ref.watch(currentPlayerProvider);
    final reminder = TimeOfDay(hour: s.reminderMinutes ~/ 60, minute: s.reminderMinutes % 60);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Group(title: 'Appearance', rows: [
                _Row(
                  title: 'Theme',
                  subtitle: 'Auto follows your Windows setting',
                  trailing: SegmentedButton<ThemePreference>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ThemePreference.light, label: Text('Light')),
                      ButtonSegment(value: ThemePreference.dark, label: Text('Dark')),
                      ButtonSegment(value: ThemePreference.system, label: Text('Auto')),
                    ],
                    selected: {s.theme},
                    onSelectionChanged: (v) => settings.setTheme(v.first),
                  ),
                ),
                _Row(
                  title: 'Reduce motion',
                  subtitle: 'Turn off path and badge animations',
                  trailing: Switch(value: s.reduceMotion, onChanged: settings.setReduceMotion),
                ),
              ]),
              _Group(title: 'Learning', rows: [
                _Row(
                  title: 'Daily goal',
                  subtitle: '${player.profile.dailyGoal.questions} question${player.profile.dailyGoal.questions == 1 ? '' : 's'} a day · ${player.profile.dailyGoal.time}',
                  trailing: DropdownButton<DailyGoal>(
                    value: player.profile.dailyGoal,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(10),
                    items: [
                      for (final g in DailyGoal.values) DropdownMenuItem(value: g, child: Text(g.label)),
                    ],
                    onChanged: (g) {
                      if (g != null) ref.read(playerProvider.notifier).updateProfile(dailyGoal: g);
                    },
                  ),
                ),
              ]),
              _Group(title: 'Privacy', rows: [
                _Row(
                  title: 'Share stats to public leaderboard',
                  subtitle: s.shareStats ? 'Your XP and rank are visible globally' : 'You\'re hidden: no rank or league',
                  trailing: Switch(value: s.shareStats, onChanged: settings.setShareStats),
                ),
              ]),
              _Group(title: 'Notifications', rows: [
                _Row(
                  title: 'Daily reminder',
                  subtitle: s.dailyReminder ? 'Nudge me at ${reminder.format(context)}' : 'Off',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: s.dailyReminder ? () => _pickTime(context, ref, s.reminderMinutes) : null,
                        icon: const Icon(Icons.schedule_rounded, size: 16),
                        label: Text(reminder.format(context)),
                      ),
                      const SizedBox(width: 12),
                      Switch(value: s.dailyReminder, onChanged: settings.setDailyReminder),
                    ],
                  ),
                ),
                _Row(
                  title: 'Launch on system startup',
                  subtitle: 'Open ByteStreak when you sign in to Windows',
                  trailing: Switch(value: s.launchOnStartup, onChanged: settings.setLaunchOnStartup),
                ),
              ]),
              _Group(title: 'Account', rows: [
                _Row(
                  title: 'Username',
                  subtitle: player.profile.username,
                  trailing: TextButton(onPressed: () => showEditProfile(context), child: const Text('Edit')),
                ),
                _Row(
                  title: 'Log out',
                  titleColor: p.heart,
                  subtitle: 'Sign out on this device',
                  trailing: OutlinedButton(onPressed: () => _logOut(context, ref), child: const Text('Log out')),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.text.titleSmall?.copyWith(color: p.muted)),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(color: p.lineSoft),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, required this.trailing, this.titleColor});
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 66),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: context.text.titleSmall?.copyWith(color: titleColor ?? p.ink, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.text.bodySmall?.copyWith(color: p.faint)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            trailing,
          ],
        ),
      ),
    );
  }
}
