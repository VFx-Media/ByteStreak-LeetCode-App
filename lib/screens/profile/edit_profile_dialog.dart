import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/screens/auth/validators.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

Future<void> showEditProfile(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const EditProfileDialog());

/// Change avatar and username. Opened from Profile and Settings.
class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _username;
  late int _avatar;
  late final String _original;
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentPlayerProvider).profile;
    _original = profile.username;
    _username = TextEditingController(text: profile.username);
    _avatar = profile.avatarIndex;
  }

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final name = _username.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    if (name.toLowerCase() != _original.toLowerCase() &&
        !await ref.read(servicesProvider).auth.isUsernameAvailable(name)) {
      setState(() {
        _busy = false;
        _error = 'That username is taken.';
      });
      return;
    }
    ref.read(playerProvider.notifier).updateProfile(username: name, avatarIndex: _avatar);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Avatar', style: context.text.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < AvatarView.count; i++)
                    HoverScale(
                      child: GestureDetector(
                        onTap: () => setState(() => _avatar = i),
                        child: AvatarView(index: i, size: 52, selected: i == _avatar),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Username', style: context.text.titleSmall),
              const SizedBox(height: 8),
              TextFormField(controller: _username, validator: validateUsername, onFieldSubmitted: (_) => _save()),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: context.text.bodySmall?.copyWith(color: p.heart)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
