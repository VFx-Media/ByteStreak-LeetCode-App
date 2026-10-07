import 'package:flutter/material.dart';
import 'package:bytestreak/theme/app_colors.dart';
import 'package:bytestreak/theme/app_palette.dart';

/// Builds Flutter's [ThemeData] from the ByteStreak palette.
///
/// `light()` and `dark()` share one builder, so the two modes can never drift
/// apart: the only difference between them is which [AppPalette] goes in.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  // Sizes and weights from the design. Colours are applied in _build.
  static const _textTheme = TextTheme(
    displaySmall: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, height: 1.15),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
    headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
    titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.35),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45),
    bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, height: 1.4),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
  );

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: brightness,
    ).copyWith(
      primary: p.success,
      onPrimary: Colors.white,
      primaryContainer: p.successSoft,
      onPrimaryContainer: p.success,
      secondary: p.xp,
      onSecondary: Colors.white,
      tertiary: p.quiz,
      surface: p.background,
      onSurface: p.ink,
      onSurfaceVariant: p.muted,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.sunken,
      surfaceContainerHighest: p.sunken,
      error: p.heart,
      onError: Colors.white,
      outline: p.line,
      outlineVariant: p.lineSoft,
    );

    final text = _textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: p.ink,
      displayColor: p.ink,
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      brightness: brightness,
      fontFamily: 'Inter',
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: p.surface,
      canvasColor: p.surface,
      dividerColor: p.line,
      extensions: [p],
      dividerTheme: DividerThemeData(color: p.lineSoft, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          disabledBackgroundColor: p.sunken,
          disabledForegroundColor: p.faint,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: buttonPadding,
          shape: buttonShape,
          foregroundColor: p.ink,
          backgroundColor: p.background,
          side: BorderSide(color: p.line, width: 1.5),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: buttonShape,
          foregroundColor: p.muted,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.muted),
      ),
      cardTheme: CardThemeData(
        color: p.background,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: text.bodyLarge?.copyWith(color: p.faint),
        border: border(p.line),
        enabledBorder: border(p.line),
        focusedBorder: border(p.success, 2),
        errorBorder: border(p.heart),
        focusedErrorBorder: border(p.heart, 2),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 350),
        textStyle: text.bodySmall?.copyWith(color: p.background),
        decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(6)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.background),
        width: 440,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(p.line),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(8),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : p.line,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.success),
    );
  }
}
