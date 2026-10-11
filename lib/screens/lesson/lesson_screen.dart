import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:re_editor/re_editor.dart';
import 'package:bytestreak/domain/lesson_session.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/screens/lesson/code_view.dart';
import 'package:bytestreak/screens/lesson/hints_dialog.dart';
import 'package:bytestreak/screens/lesson/mcq_view.dart';
import 'package:bytestreak/screens/lesson/out_of_hearts_dialog.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

/// The lesson runner. Plays a mixed sequence of questions, sending each to
/// 1.5 (multiple choice) or 1.6 (code editor), and handles hearts, hints,
/// feedback and finishing. Used for lessons, quizzes, review, practice and
/// replays; [mode] decides whether hearts and XP are in play.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId, required this.mode});

  final String? lessonId;
  final SessionMode mode;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  LessonSession? _session;

  // Multiple choice
  int? _selected;

  // Coding
  CodeLineEditingController? _code;
  String _language = 'python';
  RunResult? _run;
  var _running = false;

  /// Set once the current question is answered; shows the feedback bar.
  AnswerOutcome? _outcome;

  final _focus = FocusNode(debugLabel: 'lesson');

  @override
  void initState() {
    super.initState();
    _session = _buildSession();
    _prepareQuestion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = ref.read(currentPlayerProvider);
      if (_session != null && widget.mode.costsHearts && player.hearts == 0) {
        _handleOutOfHearts(atStart: true);
      }
    });
  }

  @override
  void dispose() {
    _code?.dispose();
    _focus.dispose();
    super.dispose();
  }

  LessonSession? _buildSession() {
    final path = ref.read(coursePathProvider);
    switch (widget.mode) {
      case SessionMode.lesson:
      case SessionMode.quiz:
      case SessionMode.replay:
        final lesson = widget.lessonId == null ? null : path.lesson(widget.lessonId!);
        if (lesson == null || lesson.questions.isEmpty) return null;
        return LessonSession(mode: widget.mode, questions: lesson.questions, lesson: lesson);
      case SessionMode.review:
        final last = ref.read(lastResultProvider);
        if (last == null || last.missed.isEmpty) return null;
        return LessonSession(mode: SessionMode.review, questions: last.missed, lesson: last.lesson);
      case SessionMode.practice:
        final questions = ref.read(playerProvider.notifier).practiceQuestions();
        if (questions.isEmpty) return null;
        return LessonSession(mode: SessionMode.practice, questions: questions);
    }
  }

  void _prepareQuestion() {
    _selected = null;
    _outcome = null;
    _run = null;
    _running = false;
    _code?.dispose();
    _code = null;
    final q = _session?.current;
    if (q is CodingQuestion) {
      _language = q.starterCode.keys.first;
      // Tab indents by 4 spaces, matching the starter code.
      _code = CodeLineEditingController.fromText(q.starterCode[_language], const CodeLineOptions(indentSize: 4));
    }
  }

  // ---- Answering -------------------------------------------------------------

  void _checkMcq() {
    final s = _session!;
    final q = s.current;
    if (q is! McqQuestion || _selected == null || _outcome != null) return;
    final outcome = ref.read(playerProvider.notifier).answer(s, correct: _selected == q.correctIndex);
    setState(() => _outcome = outcome);
  }

  Future<void> _runCode({required bool submit}) async {
    final s = _session!;
    final q = s.current;
    if (q is! CodingQuestion || _running || _outcome != null) return;
    setState(() => _running = true);
    final result = await ref
        .read(servicesProvider)
        .codeRunner
        .run(question: q, language: _language, code: _code!.text, includeHidden: submit);
    if (!mounted) return;
    setState(() {
      _running = false;
      _run = result;
      if (submit) {
        _outcome = ref.read(playerProvider.notifier).answer(s, correct: result.allPassed);
      }
    });
  }

  void _changeLanguage(String language) {
    final q = _session!.current;
    if (q is! CodingQuestion) return;
    setState(() {
      _language = language;
      _code!.text = q.starterCode[language] ?? '';
      _run = null;
    });
  }

  Future<void> _openHints({bool solution = false}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => HintsDialog(question: _session!.current, mode: widget.mode, focusSolution: solution),
    );
    _focus.requestFocus();
  }

  // ---- Moving on -------------------------------------------------------------

  Future<void> _continue() async {
    final s = _session!;
    if (_outcome == null) return;
    if (s.isLast) {
      _finish();
      return;
    }
    if (widget.mode.costsHearts && ref.read(currentPlayerProvider).hearts == 0) {
      final keepGoing = await _handleOutOfHearts(atStart: false);
      if (!keepGoing) return;
    }
    setState(() {
      s.advance();
      _prepareQuestion();
    });
    _focus.requestFocus();
  }

  void _finish() {
    final result = ref.read(playerProvider.notifier).finishSession(_session!);
    ref.read(lastResultProvider.notifier).set(result);
    context.go('/complete');
  }

  /// Shows 1.15 Out of hearts. Returns true if the player can keep going.
  Future<bool> _handleOutOfHearts({required bool atStart}) async {
    final choice = await showDialog<OutOfHeartsChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OutOfHeartsDialog(),
    );
    if (!mounted) return false;
    switch (choice) {
      case OutOfHeartsChoice.refilled:
      case OutOfHeartsChoice.regenerated:
        _focus.requestFocus();
        return true;
      case OutOfHeartsChoice.practice:
        context.go('/practice');
        return false;
      case OutOfHeartsChoice.home:
      case null:
        context.go('/home');
        return false;
    }
  }

  Future<void> _quit() async {
    final s = _session;
    if (s != null && s.outcomes.isNotEmpty && !s.isFinished) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(switch (widget.mode) {
            SessionMode.quiz => 'Quit this quiz?',
            SessionMode.practice => 'Stop practising?',
            SessionMode.review => 'Stop reviewing?',
            SessionMode.lesson || SessionMode.replay => 'Quit this lesson?',
          }),
          content: Text(switch (widget.mode) {
            SessionMode.lesson => 'XP you have already earned stays, but the lesson won\'t count as finished.',
            SessionMode.quiz => 'XP you have already earned stays, but the quiz won\'t count as passed.',
            SessionMode.practice => 'You only earn the heart by finishing all ${s.questions.length} questions.',
            SessionMode.review || SessionMode.replay => 'Nothing is lost: this mode doesn\'t use hearts or XP.',
          }),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.palette.heart),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quit'),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  // ---- Keyboard --------------------------------------------------------------

  Map<ShortcutActivator, VoidCallback> get _shortcuts {
    final q = _session?.current;
    return {
      const SingleActivator(LogicalKeyboardKey.escape): _quit,
      if (_outcome != null) ...{
        const SingleActivator(LogicalKeyboardKey.enter): _continue,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _continue,
      },
      if (q is McqQuestion && _outcome == null) ...{
        const SingleActivator(LogicalKeyboardKey.enter): _checkMcq,
        for (var i = 0; i < q.options.length && i < 4; i++) ...{
          SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)): () => setState(() => _selected = i),
          SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.keyA.keyId + i)): () => setState(() => _selected = i),
        },
      },
      if (q is CodingQuestion && _outcome == null) ...{
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _runCode(submit: false),
        const SingleActivator(LogicalKeyboardKey.enter, control: true, shift: true): () => _runCode(submit: true),
      },
    };
  }

  // ---- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = _session;
    if (s == null) return _EmptySession(mode: widget.mode);

    final q = s.current;
    final player = ref.watch(currentPlayerProvider);
    final hintsLeft = q.hints.length - player.progressOf(q.id).hintsRevealed;

    return CallbackShortcuts(
      bindings: _shortcuts,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: Scaffold(
          backgroundColor: context.palette.background,
          body: Column(
            children: [
              _Header(session: s, hearts: player.hearts, onClose: _quit),
              Expanded(
                child: switch (q) {
                  McqQuestion() => McqView(
                    question: q,
                    index: s.index,
                    total: s.questions.length,
                    selected: _selected,
                    revealed: _outcome != null,
                    onSelect: (i) => setState(() => _selected = i),
                  ),
                  CodingQuestion() => CodeView(
                    question: q,
                    controller: _code!,
                    language: _language,
                    onLanguage: _changeLanguage,
                    run: _run,
                    running: _running,
                    locked: _outcome != null,
                    onRun: () => _runCode(submit: false),
                    onSubmit: () => _runCode(submit: true),
                    onHint: () => _openHints(),
                    onSolution: () => _openHints(solution: true),
                    hintCost: ref.read(playerProvider.notifier).hintCost(widget.mode),
                    hintsLeft: hintsLeft,
                    awardsXp: widget.mode.awardsXp,
                    solutionViewed: player.progressOf(q.id).solutionViewed,
                  ),
                },
              ),
              if (_outcome != null)
                _FeedbackBar(outcome: _outcome!, run: _run, mode: widget.mode, onContinue: _continue, isLast: s.isLast)
              else if (q is McqQuestion)
                _McqFooter(
                  canCheck: _selected != null,
                  onCheck: _checkMcq,
                  onHint: () => _openHints(),
                  hintCost: ref.read(playerProvider.notifier).hintCost(widget.mode),
                  hintsLeft: hintsLeft,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session, required this.hearts, required this.onClose});
  final LessonSession session;
  final int hearts;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mode = session.mode;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Quit (Esc)',
            style: IconButton.styleFrom(backgroundColor: p.sunken),
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 20, color: p.muted),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < session.questions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: i < session.outcomes.length
                            ? (session.outcomes[i].correct ? p.success : p.heart)
                            : i == session.index
                            ? p.streak
                            : p.sunken,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          if (mode.costsHearts)
            Tooltip(
              message: 'Wrong answers cost a heart',
              child: Tag('$hearts', tone: Tone.heart, icon: Icons.favorite_rounded),
            )
          else
            Tooltip(
              message: 'No hearts lost and no XP earned in this mode',
              child: Tag(
                switch (mode) {
                  SessionMode.review => 'Review',
                  SessionMode.practice => 'Practice',
                  _ => 'Replay',
                },
                tone: Tone.xp,
                icon: Icons.replay_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _McqFooter extends StatelessWidget {
  const _McqFooter({
    required this.canCheck,
    required this.onCheck,
    required this.onHint,
    required this.hintCost,
    required this.hintsLeft,
  });

  final bool canCheck;
  final VoidCallback onCheck;
  final VoidCallback onHint;
  final int hintCost;
  final int hintsLeft;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 92,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Row(
            children: [
              HintButton(cost: hintCost, hintsLeft: hintsLeft, onPressed: onHint),
              const Spacer(),
              Tooltip(
                message: 'Enter',
                child: SizedBox(
                  width: 200,
                  child: FilledButton(onPressed: canCheck ? onCheck : null, child: const Text('Check answer')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Hint · ◆ 10". Opens the hints overlay even when none are left, so
/// already-revealed hints can be read again.
class HintButton extends StatelessWidget {
  const HintButton({super.key, required this.cost, required this.hintsLeft, required this.onPressed});
  final int cost;
  final int hintsLeft;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.lightbulb_outline_rounded, size: 18, color: p.streak),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Hint'),
          if (cost > 0 && hintsLeft > 0) ...[
            Text(' · ', style: TextStyle(color: p.faint)),
            Icon(Icons.diamond_rounded, size: 14, color: p.xp),
            Text(' $cost', style: TextStyle(color: p.xp)),
          ],
        ],
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({
    required this.outcome,
    required this.run,
    required this.mode,
    required this.onContinue,
    required this.isLast,
  });

  final AnswerOutcome outcome;
  final RunResult? run;
  final SessionMode mode;
  final VoidCallback onContinue;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = outcome.question;
    final good = outcome.correct;
    final color = good ? p.success : p.heart;

    final String title;
    if (good) {
      title = switch (q) {
        CodingQuestion() => 'All tests passed!',
        McqQuestion() => 'Correct!',
      };
    } else {
      title = switch (q) {
        CodingQuestion() =>
          run?.error != null
              ? 'Your code didn\'t run'
              : '${run?.passed ?? 0} of ${run?.results.length ?? 0} tests passed',
        McqQuestion() => 'Not quite',
      };
    }

    final details = <String>[
      if (!good && q is McqQuestion)
        'Answer: ${String.fromCharCode(65 + q.correctIndex)}. ${q.options[q.correctIndex]} — ${q.solution}',
      if (good && q is McqQuestion) q.solution,
      if (!good && q is CodingQuestion && mode.offersReview) 'It\'ll be waiting in Review mistakes at the end.',
    ];

    final reward = !mode.awardsXp
        ? null
        : outcome.correct
        ? (outcome.xpAwarded > 0 ? '+${outcome.xpAwarded} XP' : '+0 XP · solution viewed')
        : (outcome.heartLost ? '−1 heart' : null);

    return Container(
      decoration: BoxDecoration(
        color: good ? p.successSoft : p.heartSoft,
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.4))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(good ? Icons.check_rounded : Icons.close_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(title, style: context.text.titleLarge?.copyWith(color: color)),
                        if (reward != null) ...[
                          const SizedBox(width: 10),
                          Tag(reward, tone: good ? Tone.xp : Tone.heart),
                        ],
                      ],
                    ),
                    for (final d in details) ...[
                      const SizedBox(height: 4),
                      Text(
                        d,
                        style: context.text.bodyMedium?.copyWith(color: color),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Tooltip(
                message: 'Enter',
                child: SizedBox(
                  width: 180,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: onContinue,
                    autofocus: true,
                    child: Text(isLast ? 'Finish' : 'Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySession extends StatelessWidget {
  const _EmptySession({required this.mode});
  final SessionMode mode;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: p.faint),
            const SizedBox(height: 12),
            Text(
              mode == SessionMode.review ? 'No mistakes to review' : 'Nothing to play here',
              style: context.text.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              mode == SessionMode.review ? 'You got everything right. Nice.' : 'This lesson has no questions yet.',
              style: context.text.bodyMedium?.copyWith(color: p.muted),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
          ],
        ),
      ),
    );
  }
}
