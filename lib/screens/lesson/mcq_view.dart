import 'package:flutter/material.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

Tone difficultyTone(Difficulty d) => switch (d) {
  Difficulty.easy => Tone.success,
  Difficulty.medium => Tone.streak,
  Difficulty.hard => Tone.heart,
};

/// 1.5 Question — Multiple choice. Click an option or press 1-4 / A-D.
class McqView extends StatelessWidget {
  const McqView({
    super.key,
    required this.question,
    required this.index,
    required this.total,
    required this.selected,
    required this.revealed,
    required this.onSelect,
  });

  final McqQuestion question;
  final int index;
  final int total;
  final int? selected;

  /// True once "Check answer" was pressed: shows right and wrong.
  final bool revealed;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: AppCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Tag('Question ${index + 1} of $total'),
                    Tag(question.difficulty.label, tone: difficultyTone(question.difficulty)),
                    Tag(question.topic, tone: Tone.xp),
                  ],
                ),
                const SizedBox(height: 18),
                Text(question.prompt, style: context.text.titleLarge?.copyWith(fontSize: 19, height: 1.45)),
                const SizedBox(height: 22),
                for (var i = 0; i < question.options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _OptionTile(
                    letter: String.fromCharCode(65 + i),
                    text: question.options[i],
                    state: _stateFor(i),
                    onTap: revealed ? null : () => onSelect(i),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _OptionState _stateFor(int i) {
    if (!revealed) return i == selected ? _OptionState.selected : _OptionState.idle;
    if (i == question.correctIndex) return _OptionState.correct;
    if (i == selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, selected, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.letter, required this.text, required this.state, required this.onTap});

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fill, Color border, Color keyFill, Color keyText, double width) = switch (state) {
      _OptionState.idle => (p.background, p.line, p.surface, p.muted, 1.0),
      _OptionState.selected => (p.successSoft, p.success, p.success, Colors.white, 2.0),
      _OptionState.correct => (p.successSoft, p.success, p.success, Colors.white, 2.0),
      _OptionState.wrong => (p.heartSoft, p.heart, p.heart, Colors.white, 2.0),
      _OptionState.dimmed => (p.background, p.lineSoft, p.surface, p.faint, 1.0),
    };
    final emphasise = state == _OptionState.selected || state == _OptionState.correct || state == _OptionState.wrong;

    return Semantics(
      button: true,
      selected: state == _OptionState.selected,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: width),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: keyFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: emphasise ? keyFill : p.line),
                    ),
                    child: Text(
                      letter,
                      style: context.text.labelMedium?.copyWith(color: keyText, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: emphasise ? FontWeight.w600 : FontWeight.w400,
                        color: state == _OptionState.dimmed ? p.muted : p.ink,
                      ),
                    ),
                  ),
                  if (state == _OptionState.correct) Icon(Icons.check_circle_rounded, color: p.success),
                  if (state == _OptionState.wrong) Icon(Icons.cancel_rounded, color: p.heart),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
