// The code editor's keyboard shortcuts, on Windows.
//
// Its own file because re_editor decides once, the first time it's used,
// whether it's on a phone, and widget tests pretend to be Android by default.
// On "Android" it handles Enter itself, so these keys can only be tested if
// nothing in this file has shown the editor before this test sets Windows.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

import '../helpers.dart';

void main() {
  testWidgets(
    'Tab indents 4 spaces, Ctrl+Enter runs and Ctrl+Shift+Enter submits, even from inside the editor',
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
    (tester) async {
      await pumpApp(tester, location: '/play/trees-2?mode=lesson');
      await tester.tap(find.text('An empty (None) node'));
      await tester.pump();
      await tester.tap(find.text('Check answer'));
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settle(tester);

      // Click into the code so the editor, not the lesson, has the keyboard.
      await tester.tap(find.byType(CodeEditor));
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.ancestor(of: find.byElementPredicate((e) => e == focused), matching: find.byType(CodeEditor)),
        findsOne,
      );
      final controller = tester.widget<CodeEditor>(find.byType(CodeEditor)).controller!;

      final starter = controller.text;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(controller.text.length, starter.length + 4, reason: 'Tab adds 4 spaces');
      final code = controller.text;

      Future<void> ctrlEnter({bool shift = false}) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await settle(tester);
      }

      await ctrlEnter();
      expect(find.textContaining('expected 2, got None'), findsOneWidget, reason: 'Ctrl+Enter runs');
      expect(controller.text, code, reason: 'and doesn\'t type a new line');
      expect(find.text('Finish'), findsNothing, reason: 'Run doesn\'t answer the question');

      await ctrlEnter(shift: true);
      expect(find.text('0 of 2 tests passed'), findsOneWidget, reason: 'Ctrl+Shift+Enter submits');
    },
  );
}
