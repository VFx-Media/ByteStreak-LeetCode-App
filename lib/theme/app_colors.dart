import 'package:flutter/material.dart';

/// Every colour in ByteStreak, taken from the design.
/// Screens never type a hex code; they use AppColors.green etc.
class AppColors {
  AppColors._(); // private constructor: nobody can create an AppColors object

  // Neutrals: backgrounds, borders, text
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF6F7F9);
  static const sunken = Color(0xFFEDEFF3);
  static const line = Color(0xFFD7DBE2);
  static const ink = Color(0xFF15181D);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFF9AA1AC);

  // Accents: each has a strong version and a soft background version
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
}