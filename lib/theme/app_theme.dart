import 'package:flutter/material.dart';
import 'package:bytestreak/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.green,
      onPrimary: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.ink,
      error: AppColors.red,
      outline: AppColors.line,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      dividerColor: AppColors.line,
    );
  }
}