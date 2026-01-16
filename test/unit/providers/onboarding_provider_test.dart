/// Unit tests for Onboarding Provider (OnboardingController).
///
/// Test coverage:
/// 1. Initial state loading from preferences
/// 2. Disclaimer acceptance
/// 3. Privacy policy acceptance
/// 4. Biometric consent acceptance
/// 5. Voice selection
/// 6. Onboarding reset
/// 7. isComplete computed property
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/providers/preferences_provider.dart';
import 'package:orthosense/core/providers/tts_provider.dart';
import 'package:orthosense/core/services/preferences_service.dart';
import 'package:orthosense/core/services/tts_service.dart';
import 'package:orthosense/features/onboarding/presentation/providers/onboarding_provider.dart';

// Mock classes
class MockPreferencesService extends Mock implements PreferencesService {}

class MockTtsService extends Mock implements TtsService {}

void main() {
  late MockPreferencesService mockPreferencesService;
  late MockTtsService mockTtsService;
  late ProviderContainer container;

  setUp(() {
    mockPreferencesService = MockPreferencesService();
    mockTtsService = MockTtsService();
  });

  tearDown(() {
    // Only dispose if container was initialized
    try {
      container.dispose();
    } catch (_) {
      // Container may not have been initialized in model-only tests
    }
  });

  ProviderContainer createContainer({
    bool disclaimerAccepted = false,
    bool privacyPolicyAccepted = false,
    bool biometricConsentAccepted = false,
    bool voiceSelected = false,
  }) {
    // Setup mock returns
    when(
      () => mockPreferencesService.isDisclaimerAccepted,
    ).thenReturn(disclaimerAccepted);
    when(
      () => mockPreferencesService.isPrivacyPolicyAccepted,
    ).thenReturn(privacyPolicyAccepted);
    when(
      () => mockPreferencesService.isBiometricConsentAccepted,
    ).thenReturn(biometricConsentAccepted);
    when(
      () => mockPreferencesService.isVoiceSelected,
    ).thenReturn(voiceSelected);

    return ProviderContainer(
      overrides: [
        preferencesServiceProvider.overrideWithValue(mockPreferencesService),
        ttsServiceProvider.overrideWithValue(mockTtsService),
      ],
    );
  }

  group('OnboardingStatus Model', () {
    test('isComplete returns true when all steps completed', () {
      final status = OnboardingStatus(
        disclaimerAccepted: true,
        privacyPolicyAccepted: true,
        biometricConsentAccepted: true,
        voiceSelected: true,
      );

      expect(status.isComplete, isTrue);
    });

    test('isComplete returns false when disclaimer not accepted', () {
      final status = OnboardingStatus(
        disclaimerAccepted: false,
        privacyPolicyAccepted: true,
        biometricConsentAccepted: true,
        voiceSelected: true,
      );

      expect(status.isComplete, isFalse);
    });

    test('isComplete returns false when privacy policy not accepted', () {
      final status = OnboardingStatus(
        disclaimerAccepted: true,
        privacyPolicyAccepted: false,
        biometricConsentAccepted: true,
        voiceSelected: true,
      );

      expect(status.isComplete, isFalse);
    });

    test('isComplete returns false when biometric consent not accepted', () {
      final status = OnboardingStatus(
        disclaimerAccepted: true,
        privacyPolicyAccepted: true,
        biometricConsentAccepted: false,
        voiceSelected: true,
      );

      expect(status.isComplete, isFalse);
    });

    test('isComplete returns false when voice not selected', () {
      final status = OnboardingStatus(
        disclaimerAccepted: true,
        privacyPolicyAccepted: true,
        biometricConsentAccepted: true,
        voiceSelected: false,
      );

      expect(status.isComplete, isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      final original = OnboardingStatus(
        disclaimerAccepted: false,
        privacyPolicyAccepted: false,
        biometricConsentAccepted: false,
        voiceSelected: false,
      );

      final updated = original.copyWith(disclaimerAccepted: true);

      expect(updated.disclaimerAccepted, isTrue);
      expect(updated.privacyPolicyAccepted, isFalse);
      expect(updated.biometricConsentAccepted, isFalse);
      expect(updated.voiceSelected, isFalse);
    });

    test('copyWith preserves unchanged values', () {
      final original = OnboardingStatus(
        disclaimerAccepted: true,
        privacyPolicyAccepted: true,
        biometricConsentAccepted: false,
        voiceSelected: false,
      );

      final updated = original.copyWith(biometricConsentAccepted: true);

      expect(updated.disclaimerAccepted, isTrue);
      expect(updated.privacyPolicyAccepted, isTrue);
      expect(updated.biometricConsentAccepted, isTrue);
      expect(updated.voiceSelected, isFalse);
    });
  });

  group('OnboardingController Initial State', () {
    test('loads initial state from preferences - all false', () {
      container = createContainer();

      final state = container.read(onboardingControllerProvider);

      expect(state.disclaimerAccepted, isFalse);
      expect(state.privacyPolicyAccepted, isFalse);
      expect(state.biometricConsentAccepted, isFalse);
      expect(state.voiceSelected, isFalse);
      expect(state.isComplete, isFalse);
    });

    test('loads initial state from preferences - all true', () {
      container = createContainer(
        disclaimerAccepted: true,
        privacyPolicyAccepted: true,
        biometricConsentAccepted: true,
        voiceSelected: true,
      );

      final state = container.read(onboardingControllerProvider);

      expect(state.disclaimerAccepted, isTrue);
      expect(state.privacyPolicyAccepted, isTrue);
      expect(state.biometricConsentAccepted, isTrue);
      expect(state.voiceSelected, isTrue);
      expect(state.isComplete, isTrue);
    });

    test('loads partial completion state', () {
      container = createContainer(
        disclaimerAccepted: true,
        privacyPolicyAccepted: true,
        biometricConsentAccepted: false,
        voiceSelected: false,
      );

      final state = container.read(onboardingControllerProvider);

      expect(state.disclaimerAccepted, isTrue);
      expect(state.privacyPolicyAccepted, isTrue);
      expect(state.biometricConsentAccepted, isFalse);
      expect(state.voiceSelected, isFalse);
      expect(state.isComplete, isFalse);
    });
  });

  group('Disclaimer Acceptance', () {
    test('acceptDisclaimer updates state and persists', () async {
      container = createContainer();

      when(
        () => mockPreferencesService.setDisclaimerAccepted(value: true),
      ).thenAnswer((_) async {});

      await container
          .read(onboardingControllerProvider.notifier)
          .acceptDisclaimer();

      final state = container.read(onboardingControllerProvider);
      expect(state.disclaimerAccepted, isTrue);

      verify(
        () => mockPreferencesService.setDisclaimerAccepted(value: true),
      ).called(1);
    });
  });

  group('Privacy Policy Acceptance', () {
    test('acceptPrivacyPolicy updates state and persists', () async {
      container = createContainer();

      when(
        () => mockPreferencesService.setPrivacyPolicyAccepted(value: true),
      ).thenAnswer((_) async {});

      await container
          .read(onboardingControllerProvider.notifier)
          .acceptPrivacyPolicy();

      final state = container.read(onboardingControllerProvider);
      expect(state.privacyPolicyAccepted, isTrue);

      verify(
        () => mockPreferencesService.setPrivacyPolicyAccepted(value: true),
      ).called(1);
    });
  });

  group('Biometric Consent Acceptance', () {
    test('acceptBiometricConsent updates state and persists', () async {
      container = createContainer();

      when(
        () => mockPreferencesService.setBiometricConsentAccepted(value: true),
      ).thenAnswer((_) async {});

      await container
          .read(onboardingControllerProvider.notifier)
          .acceptBiometricConsent();

      final state = container.read(onboardingControllerProvider);
      expect(state.biometricConsentAccepted, isTrue);

      verify(
        () => mockPreferencesService.setBiometricConsentAccepted(value: true),
      ).called(1);
    });
  });

  group('Voice Selection', () {
    test('completeVoiceSelection updates state and persists', () async {
      container = createContainer();

      final testVoice = {'name': 'Samantha', 'locale': 'en-US'};

      when(() => mockTtsService.setVoice(testVoice)).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setVoiceSelected(value: true),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setSelectedVoiceKey('Samantha'),
      ).thenAnswer((_) async {});

      await container
          .read(onboardingControllerProvider.notifier)
          .completeVoiceSelection(testVoice);

      final state = container.read(onboardingControllerProvider);
      expect(state.voiceSelected, isTrue);

      verify(() => mockTtsService.setVoice(testVoice)).called(1);
      verify(
        () => mockPreferencesService.setVoiceSelected(value: true),
      ).called(1);
      verify(
        () => mockPreferencesService.setSelectedVoiceKey('Samantha'),
      ).called(1);
    });

    test('completeVoiceSelection handles empty voice name', () async {
      container = createContainer();

      final testVoice = <String, String>{'locale': 'en-US'};

      when(() => mockTtsService.setVoice(testVoice)).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setVoiceSelected(value: true),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setSelectedVoiceKey(''),
      ).thenAnswer((_) async {});

      await container
          .read(onboardingControllerProvider.notifier)
          .completeVoiceSelection(testVoice);

      verify(() => mockPreferencesService.setSelectedVoiceKey('')).called(1);
    });
  });

  group('Reset Onboarding', () {
    test('resetOnboarding clears all states and persists', () async {
      container = createContainer(
        disclaimerAccepted: true,
        privacyPolicyAccepted: true,
        biometricConsentAccepted: true,
        voiceSelected: true,
      );

      when(
        () => mockPreferencesService.setDisclaimerAccepted(value: false),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setPrivacyPolicyAccepted(value: false),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setBiometricConsentAccepted(value: false),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setVoiceSelected(value: false),
      ).thenAnswer((_) async {});

      await container
          .read(onboardingControllerProvider.notifier)
          .resetOnboarding();

      final state = container.read(onboardingControllerProvider);
      expect(state.disclaimerAccepted, isFalse);
      expect(state.privacyPolicyAccepted, isFalse);
      expect(state.biometricConsentAccepted, isFalse);
      expect(state.voiceSelected, isFalse);
      expect(state.isComplete, isFalse);

      verify(
        () => mockPreferencesService.setDisclaimerAccepted(value: false),
      ).called(1);
      verify(
        () => mockPreferencesService.setPrivacyPolicyAccepted(value: false),
      ).called(1);
      verify(
        () => mockPreferencesService.setBiometricConsentAccepted(value: false),
      ).called(1);
      verify(
        () => mockPreferencesService.setVoiceSelected(value: false),
      ).called(1);
    });
  });

  group('Complete Onboarding Flow', () {
    test('sequential completion leads to isComplete = true', () async {
      container = createContainer();

      // Setup all mocks
      when(
        () => mockPreferencesService.setDisclaimerAccepted(value: true),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setPrivacyPolicyAccepted(value: true),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setBiometricConsentAccepted(value: true),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setVoiceSelected(value: true),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferencesService.setSelectedVoiceKey(any()),
      ).thenAnswer((_) async {});
      when(() => mockTtsService.setVoice(any())).thenAnswer((_) async {});

      final notifier = container.read(onboardingControllerProvider.notifier);

      // Step 1: Accept disclaimer
      await notifier.acceptDisclaimer();
      expect(
        container.read(onboardingControllerProvider).isComplete,
        isFalse,
      );

      // Step 2: Accept privacy policy
      await notifier.acceptPrivacyPolicy();
      expect(
        container.read(onboardingControllerProvider).isComplete,
        isFalse,
      );

      // Step 3: Accept biometric consent
      await notifier.acceptBiometricConsent();
      expect(
        container.read(onboardingControllerProvider).isComplete,
        isFalse,
      );

      // Step 4: Select voice
      await notifier.completeVoiceSelection({
        'name': 'Alex',
        'locale': 'en-US',
      });
      expect(
        container.read(onboardingControllerProvider).isComplete,
        isTrue,
      );
    });
  });
}
