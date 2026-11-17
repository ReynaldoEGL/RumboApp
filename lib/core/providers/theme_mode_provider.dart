import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings_provider.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settings = ref.watch(appSettingsProvider);

    return settings.asData?.value.themeMode ?? ThemeMode.system;
  }

  Future<void> toggle() async {
    final settings = ref.read(appSettingsProvider).asData?.value;

    if (settings == null) {
      return;
    }

    final ThemeMode nextTheme = settings.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    await ref.read(appSettingsProvider.notifier).setThemeMode(nextTheme);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await ref.read(appSettingsProvider.notifier).setThemeMode(themeMode);
  }
}
