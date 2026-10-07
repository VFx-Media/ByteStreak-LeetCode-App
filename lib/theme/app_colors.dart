import 'package:flutter/material.dart';

/// The raw ByteStreak palette, taken from the design.
///
/// Widgets should not read these directly. They ask the theme for a *role*
/// instead (`context.palette.streak`, `Theme.of(context).colorScheme.primary`)
/// so the same widget works in both light and dark mode. See `AppPalette`.
class AppColors {
  AppColors._(); // private constructor: nobody can create an AppColors object

  // ---- Light ---------------------------------------------------------------
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF6F7F9);
  static const sunken = Color(0xFFEDEFF3);
  static const line = Color(0xFFD7DBE2);
  static const lineSoft = Color(0xFFE7EAEF);
  static const ink = Color(0xFF15181D);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFF9AA1AC);

  static const green = Color(0xFF2CB669);
  static const greenSoft = Color(0xFFE3F6EC);
  static const amber = Color(0xFFE0A21A);
  static const amberSoft = Color(0xFFFCF2DC);
  static const red = Color(0xFFDC4B4B);
  static const redSoft = Color(0xFFFBE7E7);
  static const blue = Color(0xFF3B7DD8);
  static const blueSoft = Color(0xFFE5EEFB);
  static const purple = Color(0xFF7C5CD6);
  static const purpleSoft = Color(0xFFEDE8FB);

  // ---- Dark ----------------------------------------------------------------
  static const darkBackground = Color(0xFF1E2228);
  static const darkSurface = Color(0xFF15181C);
  static const darkSunken = Color(0xFF2A2F37);
  static const darkLine = Color(0xFF363C46);
  static const darkLineSoft = Color(0xFF2A2F37);
  static const darkInk = Color(0xFFE8EAED);
  static const darkMuted = Color(0xFFA3AAB4);
  static const darkFaint = Color(0xFF6F7782);

  static const darkGreen = Color(0xFF3CC77C);
  static const darkGreenSoft = Color(0xFF1B3628);
  static const darkAmber = Color(0xFFF0B640);
  static const darkAmberSoft = Color(0xFF3A2E15);
  static const darkRed = Color(0xFFEE6A6A);
  static const darkRedSoft = Color(0xFF3D2123);
  static const darkBlue = Color(0xFF5E9AEC);
  static const darkBlueSoft = Color(0xFF1C2A3F);
  static const darkPurple = Color(0xFF9A80EA);
  static const darkPurpleSoft = Color(0xFF2B2443);

  // ---- Code editor (dark in both modes, like the design) -------------------
  static const codeBackground = Color(0xFF191C21);
  static const codeGutter = Color(0xFF4B525C);
  static const codeText = Color(0xFFD6DEEB);
}
