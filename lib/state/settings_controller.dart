import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytestreak/domain/models.dart';
import 'package:bytestreak/state/providers.dart';

/// Device settings. Every change is saved straight away.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  void _set(AppSettings next) {
    state = next;
    unawaited(ref.read(servicesProvider).settings.save(next));
  }

  void setTheme(ThemePreference theme) => _set(state.copyWith(theme: theme));
  void setReduceMotion(bool on) => _set(state.copyWith(reduceMotion: on));
  void setShareStats(bool on) => _set(state.copyWith(shareStats: on));
  void setDailyReminder(bool on) => _set(state.copyWith(dailyReminder: on));
  void setReminderTime(TimeOfDay time) => _set(state.copyWith(reminderMinutes: time.hour * 60 + time.minute));

  /// Stored here; **Person B** wires it to the `launch_at_startup` package.
  void setLaunchOnStartup(bool on) => _set(state.copyWith(launchOnStartup: on));

  /// The top-bar sun/moon button: flips between light and dark.
  void toggleBrightness(Brightness current) =>
      setTheme(current == Brightness.dark ? ThemePreference.light : ThemePreference.dark);
}

extension ThemePreferenceMode on ThemePreference {
  ThemeMode get mode => switch (this) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      };
}
