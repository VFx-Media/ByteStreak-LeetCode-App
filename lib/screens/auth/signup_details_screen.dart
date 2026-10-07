import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/data/repositories.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';
import 'package:bytestreak/widgets/select_card.dart';

/// 1.2b Create profile, step 2: experience level, goals, daily goal.
class SignupDetailsScreen extends ConsumerStatefulWidget {
  const SignupDetailsScreen({super.key});

  @override
  ConsumerState<SignupDetailsScreen> createState() => _SignupDetailsScreenState();
}

class _SignupDetailsScreenState extends ConsumerState<SignupDetailsScreen> {
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Arriving here without step 1 (e.g. a stale address) sends you back.
    if (ref.read(signupDraftProvider).email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/signup');
      });
    }
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(playerProvider.notifier).signUp(ref.read(signupDraftProvider));
      ref.read(signupDraftProvider.notifier).reset();
      // The router sees you're signed in and moves you to /home.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final draft = ref.watch(signupDraftProvider);
    final edit = ref.read(signupDraftProvider.notifier).update;

    return CenteredPage(
      maxWidth: 600,
      child: Column(
        children: [
          const StepHeader(title: 'Tell us how you learn', step: 2, of: 2),
          const SizedBox(height: 28),
          AppCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('How much DSA have you done?', style: context.text.titleSmall),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final level in ExperienceLevel.values) ...[
                      if (level != ExperienceLevel.values.first) const SizedBox(width: 10),
                      Expanded(
                        child: SelectCard(
                          selected: draft.experienceLevel == level,
                          onTap: () => edit((d) => d.copyWith(experienceLevel: level)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.label,
                                style: context.text.titleSmall?.copyWith(
                                  color: draft.experienceLevel == level ? p.success : p.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(level.blurb, style: context.text.bodySmall?.copyWith(color: p.muted)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('What are you here for?', style: context.text.titleSmall),
                    const Spacer(),
                    Text('Pick any', style: context.text.bodySmall?.copyWith(color: p.faint)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final goal in learnerGoals)
                      ToggleChip(
                        label: goal,
                        selected: draft.goals.contains(goal),
                        onTap: () => edit((d) => d.copyWith(
                              goals: d.goals.contains(goal) ? (d.goals.toSet()..remove(goal)) : {...d.goals, goal},
                            )),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Set a daily goal', style: context.text.titleSmall),
                    const Spacer(),
                    Text('Change it any time in Settings', style: context.text.bodySmall?.copyWith(color: p.faint)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final goal in DailyGoal.values) ...[
                      if (goal != DailyGoal.values.first) const SizedBox(width: 10),
                      Expanded(
                        child: SelectCard(
                          selected: draft.dailyGoal == goal,
                          onTap: () => edit((d) => d.copyWith(dailyGoal: goal)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Column(
                            children: [
                              Text(
                                goal.label,
                                style: context.text.titleSmall?.copyWith(
                                  color: draft.dailyGoal == goal ? p.success : p.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${goal.questions} question${goal.questions == 1 ? '' : 's'}',
                                style: context.text.bodySmall?.copyWith(color: p.muted),
                              ),
                              Text(goal.time, style: context.text.bodySmall?.copyWith(color: p.faint)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: context.text.bodyMedium?.copyWith(color: p.heart)),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    TextButton(onPressed: _busy ? null : () => context.go('/signup'), child: const Text('Back')),
                    const Spacer(),
                    SizedBox(
                      width: 250,
                      child: FilledButton(
                        onPressed: _busy ? null : _create,
                        child: _busy
                            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Create account'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
