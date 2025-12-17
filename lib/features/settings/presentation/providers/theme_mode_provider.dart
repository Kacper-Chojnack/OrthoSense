import 'package:flutter/material.dart';
import 'package:orthosense/features/settings/data/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// Manages theme mode state with persistence.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  Future<ThemeMode> build() async {
    final repository = await ref.watch(settingsRepositoryProvider.future);
    return repository.loadThemeMode();
  }

  /// Update theme mode and persist.
  Future<void> setThemeMode(ThemeMode mode) async {
    final repository = await ref.read(settingsRepositoryProvider.future);
    await repository.saveThemeMode(mode);
    state = AsyncData(mode);
  }
}

/// Synchronous theme mode for MaterialApp.
/// Returns system as default while loading.
@riverpod
ThemeMode currentThemeMode(CurrentThemeModeRef ref) {
  final asyncValue = ref.watch(themeModeNotifierProvider);
  return asyncValue.valueOrNull ?? ThemeMode.system;
}
