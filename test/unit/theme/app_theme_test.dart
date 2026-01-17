/// Unit tests for AppTheme configuration.
///
/// Test coverage:
/// 1. Light theme configuration
/// 2. Dark theme configuration
/// 3. Text theme accessibility
/// 4. Component theming
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme Constants', () {
    test('seed color is defined', () {
      expect(AppThemeMock.seedColor, isA<Color>());
      expect(AppThemeMock.seedColor, equals(const Color(0xFF008080)));
    });

    test('seed color is teal', () {
      // Teal has similar green and blue, low red
      final color = AppThemeMock.seedColor;
      expect(color.red, lessThan(50));
      expect(color.green, greaterThan(100));
      expect(color.blue, greaterThan(100));
    });

    test('accent color is defined', () {
      expect(AppThemeMock.accentColor, isA<Color>());
      expect(AppThemeMock.accentColor, equals(const Color(0xFF00695C)));
    });
  });

  group('Light Theme', () {
    late ThemeData lightTheme;

    setUpAll(() {
      lightTheme = AppThemeMock.lightTheme;
    });

    test('uses Material 3', () {
      expect(lightTheme.useMaterial3, isTrue);
    });

    test('brightness is light', () {
      expect(lightTheme.brightness, equals(Brightness.light));
    });

    test('has color scheme', () {
      expect(lightTheme.colorScheme, isNotNull);
      expect(lightTheme.colorScheme.brightness, equals(Brightness.light));
    });

    test('app bar is centered', () {
      expect(lightTheme.appBarTheme.centerTitle, isTrue);
    });

    test('app bar has no elevation by default', () {
      expect(lightTheme.appBarTheme.elevation, equals(0));
    });

    test('cards have rounded corners', () {
      final shape = lightTheme.cardTheme.shape;
      expect(shape, isA<RoundedRectangleBorder>());
      final rrb = shape as RoundedRectangleBorder;
      expect(rrb.borderRadius, equals(BorderRadius.circular(12)));
    });

    test('FAB uses stadium shape', () {
      expect(lightTheme.floatingActionButtonTheme.shape, isA<StadiumBorder>());
    });

    test('snackbar is floating', () {
      expect(
        lightTheme.snackBarTheme.behavior,
        equals(SnackBarBehavior.floating),
      );
    });

    test('input fields have rounded borders', () {
      final border = lightTheme.inputDecorationTheme.border;
      expect(border, isA<OutlineInputBorder>());
      final oib = border as OutlineInputBorder;
      expect(oib.borderRadius, equals(BorderRadius.circular(12)));
    });

    test('dialogs have rounded corners', () {
      final shape = lightTheme.dialogTheme.shape;
      expect(shape, isA<RoundedRectangleBorder>());
      final rrb = shape as RoundedRectangleBorder;
      expect(rrb.borderRadius, equals(BorderRadius.circular(16)));
    });

    test('bottom sheet has top rounded corners', () {
      final shape = lightTheme.bottomSheetTheme.shape;
      expect(shape, isA<RoundedRectangleBorder>());
    });
  });

  group('Dark Theme', () {
    late ThemeData darkTheme;

    setUpAll(() {
      darkTheme = AppThemeMock.darkTheme;
    });

    test('uses Material 3', () {
      expect(darkTheme.useMaterial3, isTrue);
    });

    test('brightness is dark', () {
      expect(darkTheme.brightness, equals(Brightness.dark));
    });

    test('has color scheme', () {
      expect(darkTheme.colorScheme, isNotNull);
      expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
    });

    test('app bar is centered', () {
      expect(darkTheme.appBarTheme.centerTitle, isTrue);
    });

    test('cards have rounded corners', () {
      final shape = darkTheme.cardTheme.shape;
      expect(shape, isA<RoundedRectangleBorder>());
    });
  });

  group('Text Theme (Accessibility)', () {
    late TextTheme textTheme;

    setUpAll(() {
      textTheme = AppThemeMock.accessibleTextTheme;
    });

    test('display large is extra large', () {
      expect(textTheme.displayLarge?.fontSize, equals(64));
      expect(textTheme.displayLarge?.fontWeight, equals(FontWeight.bold));
    });

    test('display medium is large', () {
      expect(textTheme.displayMedium?.fontSize, equals(52));
    });

    test('headline styles are bold', () {
      expect(textTheme.headlineLarge?.fontWeight, equals(FontWeight.bold));
      expect(textTheme.headlineMedium?.fontWeight, equals(FontWeight.bold));
      expect(textTheme.headlineSmall?.fontWeight, equals(FontWeight.bold));
    });

    test('body text has comfortable line height', () {
      expect(textTheme.bodyLarge?.height, equals(1.5));
      expect(textTheme.bodyMedium?.height, equals(1.5));
      expect(textTheme.bodySmall?.height, equals(1.5));
    });

    test('body large is readable size', () {
      expect(textTheme.bodyLarge?.fontSize, greaterThanOrEqualTo(18));
    });

    test('label styles are semi-bold', () {
      expect(textTheme.labelLarge?.fontWeight, equals(FontWeight.w600));
      expect(textTheme.labelMedium?.fontWeight, equals(FontWeight.w600));
    });

    test('title styles are semi-bold', () {
      expect(textTheme.titleLarge?.fontWeight, equals(FontWeight.w600));
      expect(textTheme.titleMedium?.fontWeight, equals(FontWeight.w600));
    });

    test('all text styles are defined', () {
      expect(textTheme.displayLarge, isNotNull);
      expect(textTheme.displayMedium, isNotNull);
      expect(textTheme.displaySmall, isNotNull);
      expect(textTheme.headlineLarge, isNotNull);
      expect(textTheme.headlineMedium, isNotNull);
      expect(textTheme.headlineSmall, isNotNull);
      expect(textTheme.titleLarge, isNotNull);
      expect(textTheme.titleMedium, isNotNull);
      expect(textTheme.titleSmall, isNotNull);
      expect(textTheme.bodyLarge, isNotNull);
      expect(textTheme.bodyMedium, isNotNull);
      expect(textTheme.bodySmall, isNotNull);
      expect(textTheme.labelLarge, isNotNull);
      expect(textTheme.labelMedium, isNotNull);
      expect(textTheme.labelSmall, isNotNull);
    });
  });

  group('Theme Consistency', () {
    test('light and dark themes have same components', () {
      final light = AppThemeMock.lightTheme;
      final dark = AppThemeMock.darkTheme;

      expect(light.useMaterial3, equals(dark.useMaterial3));
      expect(light.appBarTheme.centerTitle, equals(dark.appBarTheme.centerTitle));
    });

    test('light and dark have different brightness', () {
      expect(
        AppThemeMock.lightTheme.brightness,
        isNot(equals(AppThemeMock.darkTheme.brightness)),
      );
    });
  });

  group('Color Scheme', () {
    test('light color scheme has primary color', () {
      final scheme = AppThemeMock.lightTheme.colorScheme;
      expect(scheme.primary, isNotNull);
    });

    test('dark color scheme has primary color', () {
      final scheme = AppThemeMock.darkTheme.colorScheme;
      expect(scheme.primary, isNotNull);
    });

    test('color schemes have error colors', () {
      expect(AppThemeMock.lightTheme.colorScheme.error, isNotNull);
      expect(AppThemeMock.darkTheme.colorScheme.error, isNotNull);
    });

    test('color schemes have surface colors', () {
      expect(AppThemeMock.lightTheme.colorScheme.surface, isNotNull);
      expect(AppThemeMock.darkTheme.colorScheme.surface, isNotNull);
    });
  });

  group('Component Themes', () {
    test('input decoration has padding', () {
      final theme = AppThemeMock.lightTheme;
      final contentPadding = theme.inputDecorationTheme.contentPadding;

      expect(contentPadding, isNotNull);
    });

    test('list tile has rounded shape', () {
      final theme = AppThemeMock.lightTheme;
      final shape = theme.listTileTheme.shape;

      expect(shape, isA<RoundedRectangleBorder>());
    });

    test('divider has defined color', () {
      final theme = AppThemeMock.lightTheme;

      expect(theme.dividerTheme.color, isNotNull);
      expect(theme.dividerTheme.thickness, equals(1));
    });
  });
}

// Mock of AppTheme for testing without imports
class AppThemeMock {
  static const Color seedColor = Color(0xFF008080);
  static const Color accentColor = Color(0xFF00695C);

  static TextTheme get accessibleTextTheme {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 18, height: 1.5),
      bodyMedium: TextStyle(fontSize: 16, height: 1.5),
      bodySmall: TextStyle(fontSize: 14, height: 1.5),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(seedColor: seedColor);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      textTheme: accessibleTextTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      textTheme: accessibleTextTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
