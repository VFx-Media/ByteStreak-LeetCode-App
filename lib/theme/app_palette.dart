import 'package:flutter/material.dart';
import 'package:bytestreak/theme/app_colors.dart';

/// ByteStreak's colour *roles*. Material's [ColorScheme] covers generic roles
/// (primary, surface, error); this covers ours (streak, hearts, XP, quiz).
///
/// There is one instance for light mode and one for dark mode. A widget reads
/// `context.palette.streak` and automatically gets the right one.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.sunken,
    required this.line,
    required this.lineSoft,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.success,
    required this.successSoft,
    required this.streak,
    required this.streakSoft,
    required this.heart,
    required this.heartSoft,
    required this.xp,
    required this.xpSoft,
    required this.quiz,
    required this.quizSoft,
  });

  /// Cards, dialogs, the top bar.
  final Color background;

  /// The page behind the cards.
  final Color surface;

  /// Inset areas: placeholders, progress-bar tracks, unselected chips.
  final Color sunken;
  final Color line;
  final Color lineSoft;

  /// Text: main, secondary, tertiary.
  final Color ink;
  final Color muted;
  final Color faint;

  /// Progress, correct answers, completed nodes, the main action.
  final Color success;
  final Color successSoft;

  /// Streak counter and streak strip.
  final Color streak;
  final Color streakSoft;

  /// Hearts and wrong answers.
  final Color heart;
  final Color heartSoft;

  /// XP pill, XP costs, information.
  final Color xp;
  final Color xpSoft;

  /// Chapter quizzes and badges.
  final Color quiz;
  final Color quizSoft;

  static const light = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    sunken: AppColors.sunken,
    line: AppColors.line,
    lineSoft: AppColors.lineSoft,
    ink: AppColors.ink,
    muted: AppColors.muted,
    faint: AppColors.faint,
    success: AppColors.green,
    successSoft: AppColors.greenSoft,
    streak: AppColors.amber,
    streakSoft: AppColors.amberSoft,
    heart: AppColors.red,
    heartSoft: AppColors.redSoft,
    xp: AppColors.blue,
    xpSoft: AppColors.blueSoft,
    quiz: AppColors.purple,
    quizSoft: AppColors.purpleSoft,
  );

  static const dark = AppPalette(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    sunken: AppColors.darkSunken,
    line: AppColors.darkLine,
    lineSoft: AppColors.darkLineSoft,
    ink: AppColors.darkInk,
    muted: AppColors.darkMuted,
    faint: AppColors.darkFaint,
    success: AppColors.darkGreen,
    successSoft: AppColors.darkGreenSoft,
    streak: AppColors.darkAmber,
    streakSoft: AppColors.darkAmberSoft,
    heart: AppColors.darkRed,
    heartSoft: AppColors.darkRedSoft,
    xp: AppColors.darkBlue,
    xpSoft: AppColors.darkBlueSoft,
    quiz: AppColors.darkPurple,
    quizSoft: AppColors.darkPurpleSoft,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? sunken,
    Color? line,
    Color? lineSoft,
    Color? ink,
    Color? muted,
    Color? faint,
    Color? success,
    Color? successSoft,
    Color? streak,
    Color? streakSoft,
    Color? heart,
    Color? heartSoft,
    Color? xp,
    Color? xpSoft,
    Color? quiz,
    Color? quizSoft,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      sunken: sunken ?? this.sunken,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      streak: streak ?? this.streak,
      streakSoft: streakSoft ?? this.streakSoft,
      heart: heart ?? this.heart,
      heartSoft: heartSoft ?? this.heartSoft,
      xp: xp ?? this.xp,
      xpSoft: xpSoft ?? this.xpSoft,
      quiz: quiz ?? this.quiz,
      quizSoft: quizSoft ?? this.quizSoft,
    );
  }

  /// Blends two palettes; Flutter calls this when animating a theme change.
  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      sunken: mix(sunken, other.sunken),
      line: mix(line, other.line),
      lineSoft: mix(lineSoft, other.lineSoft),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      faint: mix(faint, other.faint),
      success: mix(success, other.success),
      successSoft: mix(successSoft, other.successSoft),
      streak: mix(streak, other.streak),
      streakSoft: mix(streakSoft, other.streakSoft),
      heart: mix(heart, other.heart),
      heartSoft: mix(heartSoft, other.heartSoft),
      xp: mix(xp, other.xp),
      xpSoft: mix(xpSoft, other.xpSoft),
      quiz: mix(quiz, other.quiz),
      quizSoft: mix(quizSoft, other.quizSoft),
    );
  }
}

/// Shortcuts so any widget can write `context.palette.streak` or
/// `context.text.titleMedium`.
extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
