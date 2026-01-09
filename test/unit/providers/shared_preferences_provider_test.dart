/// Unit tests for Shared Preferences Provider.
///
/// Test coverage:
/// 1. Provider throws unimplemented error when not overridden
/// 2. Provider can be overridden with mock
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('SharedPreferencesProvider', () {
    test('throws UnimplementedError when not overridden', () {
      final container = ProviderContainer();

      expect(
        () => container.read(sharedPreferencesProvider),
        throwsA(isA<UnimplementedError>()),
      );

      container.dispose();
    });

    test('returns mock when overridden', () {
      final mockPrefs = MockSharedPreferences();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );

      final result = container.read(sharedPreferencesProvider);

      expect(result, equals(mockPrefs));

      container.dispose();
    });

    test('provider is kept alive', () {
      final mockPrefs = MockSharedPreferences();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );

      // Read provider multiple times
      final result1 = container.read(sharedPreferencesProvider);
      final result2 = container.read(sharedPreferencesProvider);

      expect(identical(result1, result2), isTrue);

      container.dispose();
    });
  });
}
