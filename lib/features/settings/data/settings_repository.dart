import 'package:flutter/material.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_repository.g.dart';

/// Keys for Settings storage.
abstract class SettingsKeys {
  static const String themeMode = 'theme_mode';
}

/// Repository for persisting app settings using Drift.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// Load saved theme mode. Defaults to system.
  Future<ThemeMode> loadThemeMode() async {
    final query = _db.select(_db.settings)
      ..where((tbl) => tbl.key.equals(SettingsKeys.themeMode));
    final record = await query.getSingleOrNull();
    
    final value = record?.value;
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
    
    await _db.into(_db.settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        key: SettingsKeys.themeMode,
        value: value,
      ),
    );
  }
}

/// Provides SettingsRepository instance.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepository(db);
}
