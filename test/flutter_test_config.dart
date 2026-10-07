// `flutter test` runs this before every test file in this folder.
//
// By default, widget tests draw text with a placeholder font where every
// letter is a wide square, so layouts look (and overflow) nothing like the
// real app. Loading the app's real fonts makes the layout tests and the
// screenshots match what users see.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFonts();
  await testMain();
}

Future<ByteData> _read(String path) async => ByteData.sublistView(await File(path).readAsBytes());

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(_read('assets/fonts/Inter-$weight.ttf'));
  }
  await inter.load();

  // Material icons ship with the Flutter SDK.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(_read(icons.path))).load();
    }
  }

  // The code editor uses Consolas, which ships with Windows.
  const consolas = r'C:\Windows\Fonts\consola.ttf';
  if (File(consolas).existsSync()) {
    await (FontLoader('Consolas')..addFont(_read(consolas))).load();
  }
}
