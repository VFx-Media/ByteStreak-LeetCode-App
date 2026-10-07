import 'package:flutter/material.dart';
import 'package:bytestreak/theme/app_palette.dart';

/// The colour family of a tag, pill or badge.
enum Tone { success, streak, heart, xp, quiz, neutral }

extension ToneColors on Tone {
  Color strong(AppPalette p) => switch (this) {
    Tone.success => p.success,
    Tone.streak => p.streak,
    Tone.heart => p.heart,
    Tone.xp => p.xp,
    Tone.quiz => p.quiz,
    Tone.neutral => p.muted,
  };

  Color soft(AppPalette p) => switch (this) {
    Tone.success => p.successSoft,
    Tone.streak => p.streakSoft,
    Tone.heart => p.heartSoft,
    Tone.xp => p.xpSoft,
    Tone.quiz => p.quizSoft,
    Tone.neutral => p.sunken,
  };
}

/// A small rounded label: "Medium", "Arrays", "+25 XP".
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.tone = Tone.neutral, this.icon});

  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: tone.soft(p), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: tone.strong(p)), const SizedBox(width: 4)],
          Text(label, style: context.text.labelMedium?.copyWith(color: tone.strong(p))),
        ],
      ),
    );
  }
}

/// A card: white box, thin border, rounded corners, optional header row.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.action,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final String? title;
  final Widget? action;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? p.line, width: borderWidth),
      ),
      child: title == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title!, style: context.text.titleSmall)),
                    ?action,
                  ],
                ),
                const SizedBox(height: 14),
                child,
              ],
            ),
    );
  }
}

/// A rounded progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color, this.height = 8, this.track});

  /// 0.0 to 1.0.
  final double value;
  final Color? color;
  final Color? track;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track ?? p.sunken),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: ColoredBox(color: color ?? p.success),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 12 preset avatars: a colour and an icon each.
class AvatarView extends StatelessWidget {
  const AvatarView({super.key, required this.index, this.size = 40, this.selected = false});

  final int index;
  final double size;
  final bool selected;

  static const count = 12;
  static const _icons = [
    Icons.rocket_launch_rounded,
    Icons.terminal_rounded,
    Icons.bolt_rounded,
    Icons.pets_rounded,
    Icons.psychology_rounded,
    Icons.local_cafe_rounded,
    Icons.sports_esports_rounded,
    Icons.music_note_rounded,
    Icons.eco_rounded,
    Icons.auto_awesome_rounded,
    Icons.code_rounded,
    Icons.nightlight_round,
  ];
  static const _tones = [
    Tone.success,
    Tone.xp,
    Tone.streak,
    Tone.quiz,
    Tone.heart,
    Tone.streak,
    Tone.xp,
    Tone.quiz,
    Tone.success,
    Tone.heart,
    Tone.xp,
    Tone.quiz,
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final i = index % count;
    final tone = _tones[i];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.soft(p),
        border: Border.all(color: selected ? p.success : p.lineSoft, width: selected ? 3 : 1),
      ),
      child: Icon(_icons[i], size: size * 0.46, color: tone.strong(p)),
    );
  }
}

/// The ByteStreak mark: a green rounded square with a lightning bolt.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.success, Color.lerp(p.success, p.xp, 0.45)!],
        ),
      ),
      child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.62),
    );
  }
}

/// Grows slightly and shows a hand cursor on hover: desktop feedback for
/// anything clickable that isn't already a button.
class HoverScale extends StatefulWidget {
  const HoverScale({super.key, required this.child, this.enabled = true, this.scale = 1.05});

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: widget.enabled && _hover ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A big number with a caption: used on Stats, Profile and Lesson complete.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.caption,
    this.icon,
    this.color,
    this.centered = false,
  });

  final String value;
  final String label;
  final String? caption;
  final IconData? icon;
  final Color? color;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final align = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 20, color: color ?? p.muted), const SizedBox(height: 6)],
          if (!centered) Text(label, style: context.text.labelMedium?.copyWith(color: p.muted)),
          if (!centered) const SizedBox(height: 4),
          Text(
            value,
            style: context.text.headlineSmall?.copyWith(color: color ?? p.ink, height: 1.1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (centered) ...[
            const SizedBox(height: 2),
            Text(label, style: context.text.bodySmall?.copyWith(color: p.muted)),
          ],
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: context.text.bodySmall?.copyWith(color: p.faint)),
          ],
        ],
      ),
    );
  }
}

/// A full-screen page helper: centred, width-limited, scrollable content.
class CenteredPage extends StatelessWidget {
  const CenteredPage({super.key, required this.child, this.maxWidth = 620, this.padding});

  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String formatNumber(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatPercent(double? v) => v == null ? '—' : '${(v * 100).round()}%';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String formatMonthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String timeAgo(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 30) return '${diff.inDays} days ago';
  return formatDate(then);
}

String formatCountdown(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int x) => x.toString().padLeft(2, '0');
  return h > 0 ? '${h}h ${two(m)}m' : '${two(m)}:${two(s)}';
}
