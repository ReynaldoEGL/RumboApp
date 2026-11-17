import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettings {
  final bool onboardingCompleted;
  final ThemeMode themeMode;

  const AppSettings({
    required this.onboardingCompleted,
    required this.themeMode,
  });

  AppSettings copyWith({bool? onboardingCompleted, ThemeMode? themeMode}) {
    return AppSettings(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppSettingsController extends AsyncNotifier<AppSettings> {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _themeModeKey = 'theme_mode';

  // Se inicializa únicamente cuando se necesita utilizar.
  SharedPreferencesAsync? _preferencesInstance;

  SharedPreferencesAsync get _preferences {
    return _preferencesInstance ??= SharedPreferencesAsync();
  }

  @override
  Future<AppSettings> build() async {
    final bool onboardingCompleted =
        await _preferences.getBool(_onboardingKey) ?? false;

    final String? storedTheme = await _preferences.getString(_themeModeKey);

    return AppSettings(
      onboardingCompleted: onboardingCompleted,
      themeMode: _parseThemeMode(storedTheme),
    );
  }

  ThemeMode _parseThemeMode(String? value) {
    for (final mode in ThemeMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }

    return ThemeMode.system;
  }

  Future<void> completeOnboarding() async {
    final currentSettings = state.asData?.value;

    if (currentSettings == null) {
      throw StateError('Las preferencias todavía no están disponibles.');
    }

    if (currentSettings.onboardingCompleted) {
      return;
    }

    await _preferences.setBool(_onboardingKey, true);

    final latestSettings = state.asData?.value ?? currentSettings;

    state = AsyncData(latestSettings.copyWith(onboardingCompleted: true));
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final currentSettings = state.asData?.value;

    if (currentSettings == null) {
      throw StateError('Las preferencias todavía no están disponibles.');
    }

    await _preferences.setString(_themeModeKey, themeMode.name);

    final latestSettings = state.asData?.value ?? currentSettings;

    state = AsyncData(latestSettings.copyWith(themeMode: themeMode));
  }
}
