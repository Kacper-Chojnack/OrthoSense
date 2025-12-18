import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/settings/data/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// Manages theme mode state with persistence.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  Future<ThemeMode> build() async {
    final repository = ref.watch(settingsRepositoryProvider);
    return repository.loadThemeMode();
  }

  /// Update theme mode and persist.
  Future<void> setThemeMode(ThemeMode mode) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.saveThemeMode(mode);
    state = AsyncData(mode);
  }
}

/// Synchronous theme mode for MaterialApp.
/// Returns system as default while loading.
@riverpod
ThemeMode currentThemeMode(Ref ref) {
  final asyncValue = ref.watch(themeModeProvider);
  return asyncValue.maybeWhen(
    data: (mode) => mode,
    orElse: () => ThemeMode.system,
  );
}
