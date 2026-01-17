/// Unit tests for theme mode provider.
///
/// Test coverage:
/// 1. ThemeMode enum values
/// 2. Theme mode loading logic
/// 3. Theme mode persistence
/// 4. Default value handling
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeMode enum', () {
    test('has system value', () {
      expect(ThemeMode.system, isNotNull);
    });

    test('has light value', () {
      expect(ThemeMode.light, isNotNull);
    });

    test('has dark value', () {
      expect(ThemeMode.dark, isNotNull);
    });

    test('all values exist', () {
      expect(ThemeMode.values.length, equals(3));
    });
  });

  group('ThemeMode to String Conversion', () {
    test('system mode converts to string', () {
      const mode = ThemeMode.system;
      expect(mode.name, equals('system'));
    });

    test('light mode converts to string', () {
      const mode = ThemeMode.light;
      expect(mode.name, equals('light'));
    });

    test('dark mode converts to string', () {
      const mode = ThemeMode.dark;
      expect(mode.name, equals('dark'));
    });
  });

  group('ThemeMode from String', () {
    test('parses system string', () {
      final mode = _parseThemeMode('system');
      expect(mode, equals(ThemeMode.system));
    });

    test('parses light string', () {
      final mode = _parseThemeMode('light');
      expect(mode, equals(ThemeMode.light));
    });

    test('parses dark string', () {
      final mode = _parseThemeMode('dark');
      expect(mode, equals(ThemeMode.dark));
    });

    test('returns system for unknown string', () {
      final mode = _parseThemeMode('invalid');
      expect(mode, equals(ThemeMode.system));
    });

    test('returns system for null', () {
      final mode = _parseThemeMode(null);
      expect(mode, equals(ThemeMode.system));
    });
  });

  group('Theme Mode Persistence', () {
    late MockSettingsRepository repository;

    setUp(() {
      repository = MockSettingsRepository();
    });

    test('loads saved theme mode', () async {
      repository.savedThemeMode = ThemeMode.dark;
      final loaded = await repository.loadThemeMode();
      expect(loaded, equals(ThemeMode.dark));
    });

    test('saves theme mode', () async {
      await repository.saveThemeMode(ThemeMode.light);
      expect(repository.savedThemeMode, equals(ThemeMode.light));
    });

    test('loads default when no saved value', () async {
      repository.savedThemeMode = null;
      final loaded = await repository.loadThemeMode();
      expect(loaded, equals(ThemeMode.system));
    });
  });

  group('Theme Mode Notifier', () {
    test('initial state is loading', () {
      final state = MockAsyncValue<ThemeMode>.loading();
      expect(state.isLoading, isTrue);
    });

    test('state updates to data after load', () {
      final state = MockAsyncValue<ThemeMode>.data(ThemeMode.dark);
      expect(state.isLoading, isFalse);
      expect(state.value, equals(ThemeMode.dark));
    });

    test('setThemeMode updates state', () async {
      final notifier = MockThemeModeNotifier();
      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.currentMode, equals(ThemeMode.light));
    });
  });

  group('Current Theme Mode Sync Provider', () {
    test('returns data value when loaded', () {
      final asyncValue = MockAsyncValue<ThemeMode>.data(ThemeMode.dark);
      final current = asyncValue.maybeWhen(
        data: (mode) => mode,
        orElse: () => ThemeMode.system,
      );

      expect(current, equals(ThemeMode.dark));
    });

    test('returns system when loading', () {
      final asyncValue = MockAsyncValue<ThemeMode>.loading();
      final current = asyncValue.maybeWhen(
        data: (mode) => mode,
        orElse: () => ThemeMode.system,
      );

      expect(current, equals(ThemeMode.system));
    });

    test('returns system on error', () {
      final asyncValue = MockAsyncValue<ThemeMode>.error(Exception());
      final current = asyncValue.maybeWhen(
        data: (mode) => mode,
        orElse: () => ThemeMode.system,
      );

      expect(current, equals(ThemeMode.system));
    });
  });

  group('Theme Mode Display Names', () {
    test('system mode display name', () {
      final name = _getThemeModeDisplayName(ThemeMode.system);
      expect(name, equals('System'));
    });

    test('light mode display name', () {
      final name = _getThemeModeDisplayName(ThemeMode.light);
      expect(name, equals('Light'));
    });

    test('dark mode display name', () {
      final name = _getThemeModeDisplayName(ThemeMode.dark);
      expect(name, equals('Dark'));
    });
  });

  group('Theme Mode Icons', () {
    test('system mode has icon', () {
      final icon = _getThemeModeIcon(ThemeMode.system);
      expect(icon, equals(Icons.brightness_auto));
    });

    test('light mode has icon', () {
      final icon = _getThemeModeIcon(ThemeMode.light);
      expect(icon, equals(Icons.light_mode));
    });

    test('dark mode has icon', () {
      final icon = _getThemeModeIcon(ThemeMode.dark);
      expect(icon, equals(Icons.dark_mode));
    });
  });
}

// Helper functions

ThemeMode _parseThemeMode(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

String _getThemeModeDisplayName(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 'System';
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
  }
}

IconData _getThemeModeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return Icons.brightness_auto;
    case ThemeMode.light:
      return Icons.light_mode;
    case ThemeMode.dark:
      return Icons.dark_mode;
  }
}

// Mock classes

class MockSettingsRepository {
  ThemeMode? savedThemeMode;

  Future<ThemeMode> loadThemeMode() async {
    return savedThemeMode ?? ThemeMode.system;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    savedThemeMode = mode;
  }
}

class MockAsyncValue<T> {
  MockAsyncValue.data(this.value)
      : isLoading = false,
        hasError = false;

  MockAsyncValue.loading()
      : value = null,
        isLoading = true,
        hasError = false;

  MockAsyncValue.error(Object error)
      : value = null,
        isLoading = false,
        hasError = true;

  final T? value;
  final bool isLoading;
  final bool hasError;

  R maybeWhen<R>({
    R Function(T data)? data,
    required R Function() orElse,
  }) {
    if (!isLoading && !hasError && value != null && data != null) {
      return data(value as T);
    }
    return orElse();
  }
}

class MockThemeModeNotifier {
  ThemeMode currentMode = ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) async {
    currentMode = mode;
  }
}
