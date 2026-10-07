import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/screens/lesson/lesson_screen.dart';
import 'package:bytestreak/screens/lesson/mcq_view.dart';
import 'package:bytestreak/theme/app_colors.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

const _mono = 'Consolas';
const _monoFallback = ['Cascadia Mono', 'Courier New', 'monospace'];

const languageNames = {'python': 'Python 3', 'java': 'Java', 'cpp': 'C++'};
final _highlightModes = {'python': langPython, 'java': langJava, 'cpp': langCpp};

/// 1.6 Question — Code editor. Problem on the left; editor, Run/Submit and
/// test results on the right.
class CodeView extends StatelessWidget {
  const CodeView({
    super.key,
    required this.question,
    required this.controller,
    required this.language,
    required this.onLanguage,
    required this.run,
    required this.running,
    required this.locked,
    required this.onRun,
    required this.onSubmit,
    required this.onHint,
    required this.onSolution,
    required this.hintCost,
    required this.hintsLeft,
  });

  final CodingQuestion question;
  final CodeLineEditingController controller;
  final String language;
  final ValueChanged<String> onLanguage;
  final RunResult? run;
  final bool running;

  /// True after Submit: the editor becomes read-only.
  final bool locked;
  final VoidCallback onRun;
  final VoidCallback onSubmit;
  final VoidCallback onHint;
  final VoidCallback onSolution;
  final int hintCost;
  final int hintsLeft;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _ProblemPanel(
              question: question,
              onHint: onHint,
              onSolution: onSolution,
              hintCost: hintCost,
              hintsLeft: hintsLeft,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 7,
            child: _EditorPanel(
              question: question,
              controller: controller,
              language: language,
              onLanguage: onLanguage,
              run: run,
              running: running,
              locked: locked,
              onRun: onRun,
              onSubmit: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemPanel extends StatelessWidget {
  const _ProblemPanel({
    required this.question,
    required this.onHint,
    required this.onSolution,
    required this.hintCost,
    required this.hintsLeft,
  });

  final CodingQuestion question;
  final VoidCallback onHint;
  final VoidCallback onSolution;
  final int hintCost;
  final int hintsLeft;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.prompt, style: context.text.titleLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Tag(question.difficulty.label, tone: difficultyTone(question.difficulty)),
                      Tag(question.topic, tone: Tone.xp),
                      Tag('+${question.xpReward} XP', tone: Tone.quiz),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(question.description, style: context.text.bodyMedium?.copyWith(color: p.muted, height: 1.6)),
                  const SizedBox(height: 16),
                  Divider(color: p.lineSoft),
                  for (final (i, ex) in question.examples.indexed) ...[
                    const SizedBox(height: 14),
                    Text('Example ${i + 1}', style: context.text.titleSmall),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MonoLine(label: 'Input:', value: ex.input),
                          const SizedBox(height: 4),
                          _MonoLine(label: 'Output:', value: ex.output),
                          if (ex.explanation != null) ...[
                            const SizedBox(height: 6),
                            Text(ex.explanation!, style: context.text.bodySmall?.copyWith(color: p.muted)),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (question.constraints.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('Constraints', style: context.text.titleSmall),
                    const SizedBox(height: 6),
                    for (final c in question.constraints)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '•  $c',
                          style: context.text.bodySmall?.copyWith(
                            color: p.muted,
                            fontFamily: _mono,
                            fontFamilyFallback: _monoFallback,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.lineSoft)),
            ),
            child: Row(
              children: [
                HintButton(cost: hintCost, hintsLeft: hintsLeft, onPressed: onHint),
                const Spacer(),
                Tooltip(
                  message: 'Free, but this question then earns 0 XP',
                  child: TextButton(onPressed: onSolution, child: const Text('View solution')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonoLine extends StatelessWidget {
  const _MonoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.text.bodyMedium?.copyWith(fontFamily: _mono, fontFamilyFallback: _monoFallback, color: p.ink);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: style?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value, style: style),
        ],
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.question,
    required this.controller,
    required this.language,
    required this.onLanguage,
    required this.run,
    required this.running,
    required this.locked,
    required this.onRun,
    required this.onSubmit,
  });

  final CodingQuestion question;
  final CodeLineEditingController controller;
  final String language;
  final ValueChanged<String> onLanguage;
  final RunResult? run;
  final bool running;
  final bool locked;
  final VoidCallback onRun;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final busy = running || locked;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Language',
                  enabled: !locked && question.starterCode.length > 1,
                  onSelected: onLanguage,
                  itemBuilder: (_) => [
                    for (final lang in question.starterCode.keys)
                      PopupMenuItem(value: lang, child: Text(languageNames[lang] ?? lang)),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(languageNames[language] ?? language, style: context.text.labelMedium),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more_rounded, size: 16, color: p.muted),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Run the example tests (Ctrl+Enter)',
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onRun,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Run'),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Grade against every test, including hidden ones (Ctrl+Shift+Enter)',
                  child: FilledButton(onPressed: busy ? null : onSubmit, child: const Text('Submit')),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.lineSoft),
          // Editor
          Expanded(
            child: ColoredBox(
              color: AppColors.codeBackground,
              child: CodeEditor(
                controller: controller,
                readOnly: locked,
                wordWrap: false,
                padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                style: CodeEditorStyle(
                  fontSize: 13.5,
                  fontFamily: _mono,
                  fontFamilyFallback: _monoFallback,
                  fontHeight: 1.55,
                  backgroundColor: AppColors.codeBackground,
                  textColor: AppColors.codeText,
                  cursorColor: Colors.white,
                  selectionColor: const Color(0x553B7DD8),
                  cursorLineColor: const Color(0x0DFFFFFF),
                  codeTheme: CodeHighlightTheme(
                    // Only the selected language, so the highlighter never guesses.
                    languages: {language: CodeHighlightThemeMode(mode: _highlightModes[language] ?? langPython)},
                    theme: atomOneDarkTheme,
                  ),
                ),
                indicatorBuilder: (context, editing, chunk, notifier) => Row(
                  children: [
                    DefaultCodeLineNumber(
                      controller: editing,
                      notifier: notifier,
                      textStyle: const TextStyle(color: AppColors.codeGutter, fontSize: 12.5, fontFamily: _mono),
                      focusedTextStyle: const TextStyle(color: AppColors.codeText, fontSize: 12.5, fontFamily: _mono),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
          // Console
          SizedBox(
            height: 210,
            child: _Console(run: run, running: running),
          ),
        ],
      ),
    );
  }
}

class _Console extends StatelessWidget {
  const _Console({required this.run, required this.running});
  final RunResult? run;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = run;
    final summary = running
        ? 'Running…'
        : r == null
        ? ''
        : r.error != null
        ? 'Error'
        : '${r.passed} of ${r.results.length} passed · ${r.elapsedMs} ms';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.lineSoft)),
          ),
          child: Row(
            children: [
              Text('Test results', style: context.text.titleSmall),
              const Spacer(),
              Text(summary, style: context.text.bodySmall?.copyWith(color: p.muted)),
            ],
          ),
        ),
        Expanded(
          child: running
              ? const Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))
              : r == null
              ? Center(
                  child: Text(
                    'Run your code to check it against the examples.',
                    style: context.text.bodySmall?.copyWith(color: p.faint),
                  ),
                )
              : r.error != null
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: p.heartSoft, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      r.error!,
                      style: context.text.bodyMedium?.copyWith(
                        color: p.heart,
                        fontFamily: _mono,
                        fontFamilyFallback: _monoFallback,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: r.results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ResultRow(index: i, result: r.results[i]),
                ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.index, required this.result});
  final int index;
  final TestResult result;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = result.passed ? p.success : p.heart;
    final name = result.testCase.hidden ? 'Hidden case ${index + 1}' : 'Case ${index + 1}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: result.passed ? p.successSoft : p.heartSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(result.passed ? Icons.check_rounded : Icons.close_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Text(name, style: context.text.labelLarge?.copyWith(color: color, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.passed
                  ? 'passed'
                  : result.testCase.hidden
                  ? 'failed'
                  : 'expected ${result.testCase.expected}, got ${result.actual}',
              style: context.text.bodySmall?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
