import 'package:bytestreak/domain/lesson_session.dart';

/// The one-liner on the share card, picked to fit the moment.
///
/// **Person C:** these are placeholders. Write 10-15 fun lines (plan §7,
/// week 3) and replace this list; keep each under ~45 characters so it fits
/// the card on one or two lines.
String shareLine({required int streak, LessonResult? result}) {
  if (result != null && result.passedQuiz) return 'Chapter conquered. The next one\'s already open.';
  if (streak >= 30) return '$streak days straight. This is who I am now.';
  if (streak >= 7) return '$streak days. Not missing tomorrow either.';
  if (result != null && result.accuracy == 1) return 'Flawless lesson. Didn\'t even need a hint.';
  if (result != null && result.mode == SessionMode.lesson) return 'One more lesson down. The streak lives.';
  if (streak >= 2) return '$streak days in. The habit is forming.';
  return 'Building the habit, one question at a time.';
}
