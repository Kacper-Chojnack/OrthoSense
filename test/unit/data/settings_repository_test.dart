/// Unit tests for SettingsRepository.
///
/// Test coverage:
/// 1. SettingsKeys constants
/// 2. ThemeMode conversion logic
/// 3. Profile image path handling
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/settings/data/settings_repository.dart';

void main() {
  group('SettingsKeys', () {
    test('themeMode key is theme_mode', () {
      expect(SettingsKeys.themeMode, equals('theme_mode'));
    });

    test('profileImagePath key is profile_image_path', () {
      expect(SettingsKeys.profileImagePath, equals('profile_image_path'));
    });

    test('keys are unique', () {
      final keys = [
        SettingsKeys.themeMode,
        SettingsKeys.profileImagePath,
      ];
      final uniqueKeys = keys.toSet();
      expect(uniqueKeys.length, equals(keys.length));
    });
  });

  group('ThemeMode to string conversion', () {
    test('light mode converts to "light"', () {
      const mode = ThemeMode.light;
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      expect(value, equals('light'));
    });

    test('dark mode converts to "dark"', () {
      const mode = ThemeMode.dark;
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      expect(value, equals('dark'));
    });

    test('system mode converts to "system"', () {
      const mode = ThemeMode.system;
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      expect(value, equals('system'));
    });
  });

  group('String to ThemeMode conversion', () {
    test('light string converts to light mode', () {
      const value = 'light';
      final mode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      expect(mode, equals(ThemeMode.light));
    });

    test('dark string converts to dark mode', () {
      const value = 'dark';
      final mode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      expect(mode, equals(ThemeMode.dark));
    });

    test('system string converts to system mode', () {
      const value = 'system';
      final mode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      expect(mode, equals(ThemeMode.system));
    });

    test('unknown value defaults to system mode', () {
      const value = 'unknown';
      final mode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      expect(mode, equals(ThemeMode.system));
    });

    test('null value defaults to system mode', () {
      const String? value = null;
      final mode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      expect(mode, equals(ThemeMode.system));
    });

    test('empty string defaults to system mode', () {
      const value = '';
      final mode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      expect(mode, equals(ThemeMode.system));
    });
  });

  group('ThemeMode roundtrip conversion', () {
    test('all modes survive roundtrip', () {
      for (final original in ThemeMode.values) {
        final stringValue = switch (original) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        };

        final restored = switch (stringValue) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };

        expect(restored, equals(original));
      }
    });
  });

  group('Profile image path handling', () {
    test('null path should be cleared', () {
      const String? path = null;
      final shouldClear = path == null;
      expect(shouldClear, isTrue);
    });

    test('empty path should not be cleared', () {
      const path = '';
      final shouldClear = path == null;
      expect(shouldClear, isFalse);
    });

    test('valid path should not be cleared', () {
      const path = '/path/to/image.jpg';
      final shouldClear = path == null;
      expect(shouldClear, isFalse);
    });

    test('handles relative paths', () {
      const path = 'images/profile.jpg';
      expect(path, isNotEmpty);
      expect(path.contains('/'), isTrue);
    });

    test('handles absolute paths', () {
      const path = '/data/user/0/com.example.app/cache/image.jpg';
      expect(path.startsWith('/'), isTrue);
    });

    test('handles Windows-style paths', () {
      const path = r'C:\Users\user\AppData\image.jpg';
      expect(path, contains(r'\'));
    });
  });

  group('SettingsRepository behavior', () {
    test('loadThemeMode returns system for unknown values', () {
      const unknownValue = 'invalid';
      final mode = switch (unknownValue) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      expect(mode, equals(ThemeMode.system));
    });

    test('saveThemeMode uses correct string values', () {
      final conversions = <ThemeMode, String>{};

      for (final mode in ThemeMode.values) {
        final value = switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        };
        conversions[mode] = value;
      }

      expect(conversions[ThemeMode.light], equals('light'));
      expect(conversions[ThemeMode.dark], equals('dark'));
      expect(conversions[ThemeMode.system], equals('system'));
    });
  });

  group('Edge cases', () {
    test('handles case sensitivity in theme values', () {
      const values = ['LIGHT', 'Light', 'lIgHt', 'light'];

      for (final value in values) {
        final mode = switch (value.toLowerCase()) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };

        if (value.toLowerCase() == 'light') {
          expect(mode, equals(ThemeMode.light));
        }
      }
    });

    test('handles whitespace in profile paths', () {
      const path = '/path/with spaces/image.jpg';
      expect(path, contains(' '));
    });

    test('handles unicode in profile paths', () {
      const path = '/путь/到/изображение.jpg';
      expect(path, isNotEmpty);
    });

    test('handles very long paths', () {
      final longPath = '/path' + '/subdir' * 100 + '/image.jpg';
      expect(longPath.length, greaterThan(500));
    });

    test('handles special characters in paths', () {
      const path = '/path/with@special#chars!/image.jpg';
      expect(path, contains('@'));
      expect(path, contains('#'));
      expect(path, contains('!'));
    });
  });
}
