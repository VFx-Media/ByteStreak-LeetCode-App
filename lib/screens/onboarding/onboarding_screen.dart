import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// 1.1 Onboarding: the first screen on a new install.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _features = [
    (Icons.local_fire_department_rounded, Tone.streak, 'Daily streaks', 'Miss a day, lose the streak'),
    (Icons.work_rounded, Tone.xp, 'Real questions', 'The patterns interviews actually use'),
    (Icons.code_rounded, Tone.success, 'Built-in editor', 'Write and run code in the app'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final calm = ref.watch(settingsProvider.select((s) => s.reduceMotion));
    Widget logo = const LogoMark(size: 96);
    if (!calm) logo = logo.animate().scale(begin: const Offset(0.7, 0.7), duration: 450.ms, curve: Curves.easeOutBack);

    return CenteredPage(
      maxWidth: 660,
      child: Column(
        children: [
          logo,
          const SizedBox(height: 24),
          Text('ByteStreak', style: context.text.displaySmall),
          const SizedBox(height: 10),
          Text(
            'Build a daily DSA habit. One question, one streak, one goal.',
            style: context.text.bodyLarge?.copyWith(color: p.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (icon, tone, title, blurb) in _features) ...[
                  if (title != _features.first.$3) const SizedBox(width: 16),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: tone.soft(p), shape: BoxShape.circle),
                            child: Icon(icon, color: tone.strong(p), size: 22),
                          ),
                          const SizedBox(height: 12),
                          Text(title, style: context.text.titleSmall, textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(
                            blurb,
                            style: context.text.bodySmall?.copyWith(color: p.muted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 320,
            child: FilledButton(onPressed: () => context.go('/signup'), child: const Text('Get Started')),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('I already have an account', style: TextStyle(color: p.xp)),
          ),
        ],
      ),
    );
  }
}
