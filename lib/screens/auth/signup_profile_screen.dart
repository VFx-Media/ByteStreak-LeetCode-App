import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/data/repositories.dart';
import 'package:bytestreak/screens/auth/validators.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';
import 'package:bytestreak/widgets/select_card.dart';

/// 1.2 Create profile, step 1: avatar, username, and the email and password
/// the account needs.
///
/// The design only shows avatar + username; email and password were added
/// because Supabase Auth needs them to create an account.
/// "Skip for now" skips the personalisation step and uses its defaults.
class SignupProfileScreen extends ConsumerStatefulWidget {
  const SignupProfileScreen({super.key});

  @override
  ConsumerState<SignupProfileScreen> createState() => _SignupProfileScreenState();
}

enum _Availability { unknown, checking, available, taken }

class _SignupProfileScreenState extends ConsumerState<SignupProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late int _avatar;
  var _showPassword = false;
  var _availability = _Availability.unknown;
  var _busy = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(signupDraftProvider);
    _username = TextEditingController(text: draft.username);
    _email = TextEditingController(text: draft.email);
    _password = TextEditingController(text: draft.password);
    _avatar = draft.avatarIndex;
    if (draft.username.isNotEmpty) _checkUsername(draft.username);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Waits until typing pauses, then asks the backend if the name is free.
  void _checkUsername(String value) {
    _debounce?.cancel();
    if (validateUsername(value) != null) {
      setState(() => _availability = _Availability.unknown);
      return;
    }
    setState(() => _availability = _Availability.checking);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final free = await ref.read(servicesProvider).auth.isUsernameAvailable(value);
      if (!mounted || _username.text != value) return;
      setState(() => _availability = free ? _Availability.available : _Availability.taken);
    });
  }

  bool _saveDraft() {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return false;
    ref
        .read(signupDraftProvider.notifier)
        .update(
          (d) => d.copyWith(
            username: _username.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            avatarIndex: _avatar,
          ),
        );
    return true;
  }

  void _continue() {
    if (_saveDraft()) context.go('/signup/details');
  }

  Future<void> _skip() async {
    if (!_saveDraft()) return;
    setState(() => _busy = true);
    try {
      await ref.read(playerProvider.notifier).signUp(ref.read(signupDraftProvider));
      ref.read(signupDraftProvider.notifier).reset();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CenteredPage(
      maxWidth: 600,
      child: Column(
        children: [
          const StepHeader(title: 'Create your profile', step: 1, of: 2),
          const SizedBox(height: 28),
          AppCard(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _form,
              // Re-check each field as the user types once they've touched it,
              // so a fixed error disappears and new ones (like "taken") appear.
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Label('Pick an avatar', hint: '12 to choose from'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < AvatarView.count; i++)
                        Tooltip(
                          message: 'Avatar ${i + 1}',
                          child: HoverScale(
                            child: GestureDetector(
                              onTap: () => setState(() => _avatar = i),
                              child: AvatarView(index: i, size: 64, selected: i == _avatar),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _Label('Username', hint: 'This is what the leaderboard shows'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _username,
                    autofocus: true,
                    validator: (v) =>
                        validateUsername(v) ?? (_availability == _Availability.taken ? 'That username is taken' : null),
                    onChanged: _checkUsername,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(hintText: 'dev123', suffixIcon: _AvailabilityBadge(_availability)),
                  ),
                  const SizedBox(height: 18),
                  _Label('Email'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    validator: validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'you@example.com'),
                  ),
                  const SizedBox(height: 18),
                  _Label('Password', hint: 'At least 8 characters'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    validator: validatePassword,
                    obscureText: !_showPassword,
                    onFieldSubmitted: (_) => _continue(),
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'Hide password' : 'Show password',
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                        icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: context.text.bodyMedium?.copyWith(color: p.heart)),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Tooltip(
                        message: 'Create the account now with default settings',
                        child: TextButton(onPressed: _busy ? null : _skip, child: const Text('Skip for now')),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 220,
                        child: FilledButton(
                          onPressed: _busy ? null : _continue,
                          child: _busy
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account?', style: context.text.bodyMedium?.copyWith(color: p.muted)),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Log in', style: TextStyle(color: p.xp)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.hint});
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: context.text.titleSmall),
        const Spacer(),
        if (hint != null) Text(hint!, style: context.text.bodySmall?.copyWith(color: context.palette.faint)),
      ],
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge(this.state);
  final _Availability state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final child = switch (state) {
      _Availability.unknown => null,
      _Availability.checking => const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
      _Availability.available => Text('✓ available', style: context.text.labelMedium?.copyWith(color: p.success)),
      _Availability.taken => Text('taken', style: context.text.labelMedium?.copyWith(color: p.heart)),
    };
    if (child == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(mainAxisSize: MainAxisSize.min, children: [child]),
    );
  }
}
