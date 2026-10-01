import 'package:flutter/material.dart';
import 'package:bytestreak/screens/theme_preview.dart';
import 'package:bytestreak/theme/app_theme.dart';

class ByteStreakApp extends StatelessWidget {
  const ByteStreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ByteStreak',
      debugShowCheckedModeBanner: false,  // hides the red DEBUG ribbon
      theme: AppTheme.light(),
      home: const ThemePreview(),         // temporary; becomes the router in Step 4
    );
  }
}