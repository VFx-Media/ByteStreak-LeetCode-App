import 'package:bytestreak/domain/models.dart';

/// How a node on the path looks and behaves.
enum NodeState {
  /// Finished. Can be replayed for practice (no XP, no hearts).
  done,

  /// The one node the player should do next. Highlighted "START".
  current,

  /// Unlocked but not next, e.g. a chapter quiz you can take early.
  available,

  /// Not reachable yet.
  locked,
}

/// Works out the state of every node from what the player has finished.
///
/// Rules (plan §2):
/// * Chapter 1 is open. Chapter N+1 opens when chapter N's quiz is passed.
/// * Inside an open chapter, lesson k opens when lesson k-1 is done, or when
///   the chapter quiz has been passed (you skipped ahead).
/// * The quiz is available as soon as its chapter opens, so you can skip
///   lessons you already know.
class PathProgress {
  PathProgress(this.path, PlayerState player)
      : _completed = player.completedLessons,
        _passed = player.passedQuizzes {
    _compute();
  }

  final CoursePath path;
  final Set<String> _completed;
  final Set<String> _passed;
  final _states = <String, NodeState>{};
  Lesson? _current;

  NodeState stateOf(String lessonId) => _states[lessonId] ?? NodeState.locked;

  /// Where "Continue where you left off" goes. Null when the path is finished.
  Lesson? get current => _current;

  bool isChapterUnlocked(Chapter chapter) {
    final i = path.chapters.indexOf(chapter);
    return i == 0 || _passed.contains(path.chapters[i - 1].quiz.id);
  }

  bool isChapterComplete(Chapter chapter) => _passed.contains(chapter.quiz.id);

  /// Lessons done in this chapter, for "Lesson 2 of 2" style labels.
  int lessonsDone(Chapter chapter) =>
      chapter.lessons.where((l) => _completed.contains(l.id)).length;

  void _compute() {
    Chapter? furthestOpen;
    for (final chapter in path.chapters) {
      final open = isChapterUnlocked(chapter);
      if (open) furthestOpen = chapter;
      final quizPassed = _passed.contains(chapter.quiz.id);

      for (var k = 0; k < chapter.lessons.length; k++) {
        final lesson = chapter.lessons[k];
        if (_completed.contains(lesson.id)) {
          _states[lesson.id] = NodeState.done;
        } else if (open && (k == 0 || _completed.contains(chapter.lessons[k - 1].id) || quizPassed)) {
          _states[lesson.id] = NodeState.available;
        } else {
          _states[lesson.id] = NodeState.locked;
        }
      }
      _states[chapter.quiz.id] = quizPassed
          ? NodeState.done
          : open
              ? NodeState.available
              : NodeState.locked;
    }

    // "Current" is the first unfinished node in the furthest open chapter, so
    // skipping a chapter via its quiz doesn't drag you back to old lessons.
    if (furthestOpen != null) {
      for (final node in furthestOpen.nodes) {
        if (_states[node.id] == NodeState.available) {
          _states[node.id] = NodeState.current;
          _current = node;
          break;
        }
      }
    }
  }
}
