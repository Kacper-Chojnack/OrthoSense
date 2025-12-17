import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_repository.g.dart';

/// Keys for SharedPreferences storage.
abstract class SettingsKeys {
  static const String themeMode = 'theme_mode';
}

/// Repository for persisting app settings.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Load saved theme mode. Defaults to system.
  ThemeMode loadThemeMode() {
    final value = _prefs.getString(SettingsKeys.themeMode);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Save theme mode preference.
  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(SettingsKeys.themeMode, value);
  }
}

/// Provides SharedPreferences instance.
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) async {
  return SharedPreferences.getInstance();
}

/// Provides SettingsRepository instance.
@Riverpod(keepAlive: true)
Future<SettingsRepository> settingsRepository(SettingsRepositoryRef ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepository(prefs);
}
