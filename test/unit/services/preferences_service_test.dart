/// Unit tests for Preferences Service.
///
/// Test coverage:
/// 1. Disclaimer preferences
/// 2. Privacy policy consent
/// 3. Biometric consent
/// 4. Voice selection
/// 5. Notifications settings
/// 6. Exercise video skip preferences
/// 7. Clear all functionality
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;
  late PreferencesService preferencesService;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    preferencesService = PreferencesService(mockPrefs);
  });

  group('Disclaimer Preferences', () {
    test('isDisclaimerAccepted returns false by default', () {
      when(
        () => mockPrefs.getBool(PreferencesService.keyDisclaimerAccepted),
      ).thenReturn(null);

      expect(preferencesService.isDisclaimerAccepted, isFalse);
    });

    test('isDisclaimerAccepted returns stored value', () {
      when(
        () => mockPrefs.getBool(PreferencesService.keyDisclaimerAccepted),
      ).thenReturn(true);

      expect(preferencesService.isDisclaimerAccepted, isTrue);
    });

    test('setDisclaimerAccepted saves value', () async {
      when(
        () => mockPrefs.setBool(
          PreferencesService.keyDisclaimerAccepted,
          true,
        ),
      ).thenAnswer((_) async => true);

      await preferencesService.setDisclaimerAccepted(value: true);

      verify(
        () => mockPrefs.setBool(PreferencesService.keyDisclaimerAccepted, true),
      ).called(1);
    });
  });

  group('Privacy Policy Preferences', () {
    test('isPrivacyPolicyAccepted returns false by default', () {
      when(
        () => mockPrefs.getBool(PreferencesService.keyPrivacyPolicyAccepted),
      ).thenReturn(null);

      expect(preferencesService.isPrivacyPolicyAccepted, isFalse);
    });

    test('isPrivacyPolicyAccepted returns stored value', () {
      when(
        () => mockPrefs.getBool(PreferencesService.keyPrivacyPolicyAccepted),
      ).thenReturn(true);

      expect(preferencesService.isPrivacyPolicyAccepted, isTrue);
    });

    test('setPrivacyPolicyAccepted saves value', () async {
      when(
        () => mockPrefs.setBool(
          PreferencesService.keyPrivacyPolicyAccepted,
          true,
        ),
      ).thenAnswer((_) async => true);

      await preferencesService.setPrivacyPolicyAccepted(value: true);

      verify(
        () => mockPrefs.setBool(
          PreferencesService.keyPrivacyPolicyAccepted,
          true,
        ),
      ).called(1);
    });
  });

  group('Biometric Consent Preferences', () {
    test('isBiometricConsentAccepted returns false by default', () {
      when(
        () => mockPrefs.getBool(PreferencesService.keyBiometricConsentAccepted),
      ).thenReturn(null);

      expect(preferencesService.isBiometricConsentAccepted, isFalse);
    });

    test('isBiometricConsentAccepted returns stored value', () {
      when(
        () => mockPrefs.getBool(PreferencesService.keyBiometricConsentAccepted),
      ).thenReturn(true);

      expect(preferencesService.isBiometricConsentAccepted, isTrue);
    });

    test('setBiometricConsentAccepted saves value', () async {
      when(
        () => mockPrefs.setBool(
          PreferencesService.keyBiometricConsentAccepted,
          true,
        ),
      ).thenAnswer((_) async => true);

      await preferencesService.setBiometricConsentAccepted(value: true);

      verify(
        () => mockPrefs.setBool(
          PreferencesService.keyBiometricConsentAccepted,
          true,
        ),
      ).called(1);
    });
  });

  group('Voice Selection Preferences', () {
    test('isVoiceSelected returns false by default', () {
      when(
        () => mockPrefs.getBool(PreferencesService.keyVoiceSelected),
      ).thenReturn(null);

      expect(preferencesService.isVoiceSelected, isFalse);
    });

    test('selectedVoiceKey returns null by default', () {
      when(
        () => mockPrefs.getString(PreferencesService.keySelectedVoiceMap),
      ).thenReturn(null);

      expect(preferencesService.selectedVoiceKey, isNull);
    });

    test('selectedVoiceKey returns stored value', () {
      when(
        () => mockPrefs.getString(PreferencesService.keySelectedVoiceMap),
      ).thenReturn('en-US-voice-1');

      expect(preferencesService.selectedVoiceKey, equals('en-US-voice-1'));
    });

    test('setSelectedVoiceKey saves value', () async {
      when(
        () => mockPrefs.setString(
          PreferencesService.keySelectedVoiceMap,
          'en-GB-voice-2',
        ),
      ).thenAnswer((_) async => true);

      await preferencesService.setSelectedVoiceKey('en-GB-voice-2');

      verify(
        () => mockPrefs.setString(
          PreferencesService.keySelectedVoiceMap,
          'en-GB-voice-2',
        ),
      ).called(1);
    });
  });

  group('Notifications Preferences', () {
    test('areNotificationsEnabled returns true by default', () {
      when(
        () => mockPrefs.getBool(PreferencesService.keyNotificationsEnabled),
      ).thenReturn(null);

      expect(preferencesService.areNotificationsEnabled, isTrue);
    });

    test('areNotificationsEnabled returns stored value', () {
      when(
        () => mockPrefs.getBool(PreferencesService.keyNotificationsEnabled),
      ).thenReturn(false);

      expect(preferencesService.areNotificationsEnabled, isFalse);
    });

    test('setNotificationsEnabled saves value', () async {
      when(
        () => mockPrefs.setBool(
          PreferencesService.keyNotificationsEnabled,
          false,
        ),
      ).thenAnswer((_) async => true);

      await preferencesService.setNotificationsEnabled(value: false);

      verify(
        () => mockPrefs.setBool(
          PreferencesService.keyNotificationsEnabled,
          false,
        ),
      ).called(1);
    });
  });

  group('Exercise Video Skip Preferences', () {
    test('shouldSkipExerciseVideo returns false by default', () {
      when(
        () => mockPrefs.getBool(
          '${PreferencesService.keySkipExerciseVideoPrefix}123',
        ),
      ).thenReturn(null);

      expect(preferencesService.shouldSkipExerciseVideo(123), isFalse);
    });

    test('shouldSkipExerciseVideo returns stored value', () {
      when(
        () => mockPrefs.getBool(
          '${PreferencesService.keySkipExerciseVideoPrefix}456',
        ),
      ).thenReturn(true);

      expect(preferencesService.shouldSkipExerciseVideo(456), isTrue);
    });

    test('setSkipExerciseVideo saves value', () async {
      when(
        () => mockPrefs.setBool(
          '${PreferencesService.keySkipExerciseVideoPrefix}789',
          true,
        ),
      ).thenAnswer((_) async => true);

      await preferencesService.setSkipExerciseVideo(
        exerciseId: 789,
        skip: true,
      );

      verify(
        () => mockPrefs.setBool(
          '${PreferencesService.keySkipExerciseVideoPrefix}789',
          true,
        ),
      ).called(1);
    });

    test(
      'resetAllExerciseVideoPreferences removes all skip preferences',
      () async {
        when(() => mockPrefs.getKeys()).thenReturn({
          '${PreferencesService.keySkipExerciseVideoPrefix}1',
          '${PreferencesService.keySkipExerciseVideoPrefix}2',
          'other_key',
        });
        when(
          () => mockPrefs.remove(
            '${PreferencesService.keySkipExerciseVideoPrefix}1',
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPrefs.remove(
            '${PreferencesService.keySkipExerciseVideoPrefix}2',
          ),
        ).thenAnswer((_) async => true);

        await preferencesService.resetAllExerciseVideoPreferences();

        verify(
          () => mockPrefs.remove(
            '${PreferencesService.keySkipExerciseVideoPrefix}1',
          ),
        ).called(1);
        verify(
          () => mockPrefs.remove(
            '${PreferencesService.keySkipExerciseVideoPrefix}2',
          ),
        ).called(1);
        verifyNever(() => mockPrefs.remove('other_key'));
      },
    );
  });

  group('Generic String Preferences', () {
    test('getString returns null by default', () {
      when(() => mockPrefs.getString('custom_key')).thenReturn(null);

      expect(preferencesService.getString('custom_key'), isNull);
    });

    test('getString returns stored value', () {
      when(() => mockPrefs.getString('custom_key')).thenReturn('custom_value');

      expect(
        preferencesService.getString('custom_key'),
        equals('custom_value'),
      );
    });

    test('setString saves value', () async {
      when(
        () => mockPrefs.setString('custom_key', 'new_value'),
      ).thenAnswer((_) async => true);

      await preferencesService.setString('custom_key', 'new_value');

      verify(() => mockPrefs.setString('custom_key', 'new_value')).called(1);
    });
  });

  group('Clear All', () {
    test('clearAll clears all preferences', () async {
      when(() => mockPrefs.clear()).thenAnswer((_) async => true);

      await preferencesService.clearAll();

      verify(() => mockPrefs.clear()).called(1);
    });
  });
}
