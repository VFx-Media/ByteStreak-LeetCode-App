import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/share_lines.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

Future<void> showSharePreview(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const SharePreviewDialog());

/// 1.17 Share card preview: the 9:16 story card, with Save image, Copy and
/// Share. Stories are a phone feature, so the desktop app *makes* the image
/// and the user posts it from their phone.
class SharePreviewDialog extends ConsumerStatefulWidget {
  const SharePreviewDialog({super.key});

  @override
  ConsumerState<SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends ConsumerState<SharePreviewDialog> {
  final _cardKey = GlobalKey();
  String? _status;
  var _busy = false;

  /// Renders the card at 3x: 360 x 640 logical pixels -> 1080 x 1920 PNG.
  Future<Uint8List> _capture() async {
    final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _do(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final msg = await action();
      if (mounted) setState(() => _status = msg);
    } catch (e) {
      if (mounted) setState(() => _status = 'That didn\'t work: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _save() async {
    final location = await getSaveLocation(
      suggestedName: 'bytestreak-progress.png',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'PNG image', extensions: ['png']),
      ],
    );
    if (location == null) return null;
    await File(location.path).writeAsBytes(await _capture());
    return 'Saved. Send it to your phone and post it to your story.';
  }

  Future<String?> _copy() async {
    await Pasteboard.writeImage(await _capture());
    return 'Copied to the clipboard.';
  }

  Future<String?> _share() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}bytestreak-progress.png');
    await file.writeAsBytes(await _capture());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: 'My ByteStreak progress',
      ),
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview: the real 360 x 640 card, scaled down to fit.
              SizedBox(
                width: 288,
                height: 512,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FittedBox(
                    child: RepaintBoundary(key: _cardKey, child: const ShareCard()),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Share your progress', style: context.text.titleLarge)),
                        IconButton(
                          tooltip: 'Close (Esc)',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A 1080 × 1920 image, sized for Instagram, TikTok and Snapchat stories.',
                      style: context.text.bodyMedium?.copyWith(color: p.muted),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: p.xpSoft, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.phone_iphone_rounded, size: 18, color: p.xp),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stories are a phone feature, so save or copy the image here and post it from your phone.',
                              style: context.text.bodySmall?.copyWith(color: p.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _do(_save),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Save image'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _do(_copy),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _do(_share),
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Share…'),
                    ),
                    const SizedBox(height: 14),
                    if (_status != null) Text(_status!, style: context.text.bodySmall?.copyWith(color: p.success)),
                    Text(
                      'Only shows what\'s already public on the leaderboard and your profile.',
                      style: context.text.bodySmall?.copyWith(color: p.faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The story card itself, laid out at 360 x 640 logical pixels.
///
/// Story apps put their own buttons over the top and bottom ~250 px of a
/// 1080 x 1920 image (~84 px here), so text stays inside the middle band.
class ShareCard extends ConsumerWidget {
  const ShareCard({super.key});

  static const width = 360.0;
  static const height = 640.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final now = ref.watch(clockProvider)();
    final result = ref.watch(lastResultProvider);
    final league = ref.watch(leagueProvider);
    final progress = ref.watch(pathProgressProvider);
    final path = ref.watch(coursePathProvider);
    final current = progress.current;
    final chapter = current == null ? null : path.chapterOfLesson(current.id);
    final streak = GameRules.effectiveStreak(streak: player.streak, lastPracticeDay: player.lastPracticeDay, now: now);
    const white = Colors.white;
    final dim = Colors.white.withValues(alpha: 0.78);

    Widget stat(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(color: white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: dim, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );

    return MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.noScaling),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF2CB669), Color.lerp(const Color(0xFF2CB669), const Color(0xFF3B7DD8), 0.7)!],
          ),
        ),
        child: Stack(
          children: [
            Positioned(right: -60, top: 40, child: _Blob(size: 220, alpha: 0.10)),
            Positioned(left: -80, bottom: 60, child: _Blob(size: 260, alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 92, 28, 92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const LogoMark(size: 30),
                      const SizedBox(width: 8),
                      const Text(
                        'ByteStreak',
                        style: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                        ),
                        child: AvatarView(index: player.profile.avatarIndex, size: 38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '@${player.profile.username}',
                      style: TextStyle(color: dim, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFD166), size: 44),
                  Text(
                    '$streak',
                    style: const TextStyle(color: white, fontSize: 92, fontWeight: FontWeight.w700, height: 1),
                  ),
                  const Text(
                    'day streak',
                    style: TextStyle(color: white, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"${shareLine(streak: streak, result: result)}"',
                    style: TextStyle(color: dim, fontSize: 15, fontWeight: FontWeight.w500, height: 1.35),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      stat(formatNumber(player.xp), 'XP'),
                      const SizedBox(width: 8),
                      stat('${GameRules.levelForXp(player.xp)}', 'LEVEL'),
                      const SizedBox(width: 8),
                      stat(league == League.unranked ? '—' : league.label.split(' ').first, 'LEAGUE'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    chapter == null ? 'Finished ${path.title}' : 'Now learning: ${chapter.title}',
                    style: TextStyle(color: dim, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.alpha});
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}
