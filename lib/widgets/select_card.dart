import 'package:flutter/material.dart';
import 'package:bytestreak/theme/app_palette.dart';

/// A selectable box: grey normally, green outline when chosen.
/// Used for experience level, daily goal, and settings choices.
class SelectCard extends StatelessWidget {
  const SelectCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.successSoft : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? p.success : p.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A pill that toggles on and off: goal chips, filters.
class ToggleChip extends StatelessWidget {
  const ToggleChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: selected ? p.successSoft : p.sunken,
      shape: StadiumBorder(side: BorderSide(color: selected ? p.success : Colors.transparent)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label, style: context.text.labelMedium?.copyWith(color: selected ? p.success : p.muted)),
        ),
      ),
    );
  }
}

/// Header used on both sign-up steps: title, progress bar, "Step N of 2".
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.title, required this.step, required this.of});
  final String title;
  final int step;
  final int of;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Text(title, style: context.text.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        SizedBox(
          width: 320,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: step / of, minHeight: 6, backgroundColor: p.sunken, color: p.success),
          ),
        ),
        const SizedBox(height: 8),
        Text('Step $step of $of', style: context.text.labelMedium?.copyWith(color: p.faint)),
      ],
    );
  }
}
