import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/data/repositories.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// 1.13 Log in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  var _showPassword = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (_identifier.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email or username and your password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(playerProvider.notifier).signIn(_identifier.text, _password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final id = _identifier.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Type your email or username first, then press Forgot?');
      return;
    }
    await ref.read(servicesProvider).auth.sendPasswordReset(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('If an account matches "$id", a reset link is on its way.')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hint = ref.watch(servicesProvider).auth.demoHint;
    return CenteredPage(
      maxWidth: 480,
      child: AppCard(
        padding: const EdgeInsets.all(32),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: LogoMark(size: 72)),
              const SizedBox(height: 20),
              Text('Welcome back', style: context.text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                'Your streak is waiting.',
                style: context.text.bodyLarge?.copyWith(color: p.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Text('Email or username', style: context.text.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _identifier,
                autofocus: true,
                autofillHints: const [AutofillHints.username, AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'you@example.com'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Password', style: context.text.titleSmall),
                  const Spacer(),
                  InkWell(
                    onTap: _forgot,
                    child: Text('Forgot?', style: context.text.labelMedium?.copyWith(color: p.xp)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _password,
                obscureText: !_showPassword,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _logIn(),
                decoration: InputDecoration(
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    child: Text(_showPassword ? 'Hide' : 'Show'),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: context.text.bodyMedium?.copyWith(color: p.heart)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _logIn,
                child: _busy
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Log in'),
              ),
              if (hint != null) ...[
                const SizedBox(height: 12),
                Text(
                  hint,
                  style: context.text.bodySmall?.copyWith(color: p.faint),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New here?', style: context.text.bodyMedium?.copyWith(color: p.muted)),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: Text('Create an account', style: TextStyle(color: p.xp)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
