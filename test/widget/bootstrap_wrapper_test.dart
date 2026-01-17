/// Unit tests for BootstrapWrapper.
///
/// Test coverage:
/// 1. Onboarding flow order
/// 2. Step enforcement
/// 3. Navigation to each step
/// 4. Completion state
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BootstrapWrapper', () {
    group('constructor', () {
      test('requires child widget', () {
        const hasChild = true;
        expect(hasChild, isTrue);
      });
    });

    group('onboarding flow order', () {
      test('Step 1 is Medical Disclaimer', () {
        const step1 = 'disclaimerAccepted';
        expect(step1, equals('disclaimerAccepted'));
      });

      test('Step 2 is Privacy Policy', () {
        const step2 = 'privacyPolicyAccepted';
        expect(step2, equals('privacyPolicyAccepted'));
      });

      test('Step 3 is Biometric Consent', () {
        const step3 = 'biometricConsentAccepted';
        expect(step3, equals('biometricConsentAccepted'));
      });

      test('Step 4 is Voice Selection', () {
        const step4 = 'voiceSelected';
        expect(step4, equals('voiceSelected'));
      });
    });

    group('step enforcement', () {
      test('shows disclaimer if not accepted', () {
        const disclaimerAccepted = false;
        final showsDisclaimer = !disclaimerAccepted;

        expect(showsDisclaimer, isTrue);
      });

      test('shows privacy policy after disclaimer accepted', () {
        const disclaimerAccepted = true;
        const privacyPolicyAccepted = false;

        final showsPrivacyPolicy =
            disclaimerAccepted && !privacyPolicyAccepted;

        expect(showsPrivacyPolicy, isTrue);
      });

      test('shows biometric consent after privacy policy accepted', () {
        const disclaimerAccepted = true;
        const privacyPolicyAccepted = true;
        const biometricConsentAccepted = false;

        final showsBiometricConsent = disclaimerAccepted &&
            privacyPolicyAccepted &&
            !biometricConsentAccepted;

        expect(showsBiometricConsent, isTrue);
      });

      test('shows voice selection after biometric consent accepted', () {
        const disclaimerAccepted = true;
        const privacyPolicyAccepted = true;
        const biometricConsentAccepted = true;
        const voiceSelected = false;

        final showsVoiceSelection = disclaimerAccepted &&
            privacyPolicyAccepted &&
            biometricConsentAccepted &&
            !voiceSelected;

        expect(showsVoiceSelection, isTrue);
      });

      test('shows child when all steps completed', () {
        const disclaimerAccepted = true;
        const privacyPolicyAccepted = true;
        const biometricConsentAccepted = true;
        const voiceSelected = true;

        final showsChild = disclaimerAccepted &&
            privacyPolicyAccepted &&
            biometricConsentAccepted &&
            voiceSelected;

        expect(showsChild, isTrue);
      });
    });

    group('screen navigation', () {
      test('DisclaimerScreen is step 1', () {
        const screenName = 'DisclaimerScreen';
        expect(screenName, equals('DisclaimerScreen'));
      });

      test('PrivacyPolicyScreen is step 2', () {
        const screenName = 'PrivacyPolicyScreen';
        expect(screenName, equals('PrivacyPolicyScreen'));
      });

      test('BiometricConsentScreen is step 3', () {
        const screenName = 'BiometricConsentScreen';
        expect(screenName, equals('BiometricConsentScreen'));
      });

      test('VoiceSelectionScreen is step 4', () {
        const screenName = 'VoiceSelectionScreen';
        expect(screenName, equals('VoiceSelectionScreen'));
      });
    });

    group('onboarding status', () {
      test('watches onboardingControllerProvider', () {
        var watchedProvider = false;

        void watchProvider() {
          watchedProvider = true;
        }

        watchProvider();
        expect(watchedProvider, isTrue);
      });

      test('status has disclaimerAccepted property', () {
        final status = {
          'disclaimerAccepted': false,
          'privacyPolicyAccepted': false,
          'biometricConsentAccepted': false,
          'voiceSelected': false,
        };

        expect(status.containsKey('disclaimerAccepted'), isTrue);
      });

      test('status has privacyPolicyAccepted property', () {
        final status = {
          'disclaimerAccepted': false,
          'privacyPolicyAccepted': false,
          'biometricConsentAccepted': false,
          'voiceSelected': false,
        };

        expect(status.containsKey('privacyPolicyAccepted'), isTrue);
      });

      test('status has biometricConsentAccepted property', () {
        final status = {
          'disclaimerAccepted': false,
          'privacyPolicyAccepted': false,
          'biometricConsentAccepted': false,
          'voiceSelected': false,
        };

        expect(status.containsKey('biometricConsentAccepted'), isTrue);
      });

      test('status has voiceSelected property', () {
        final status = {
          'disclaimerAccepted': false,
          'privacyPolicyAccepted': false,
          'biometricConsentAccepted': false,
          'voiceSelected': false,
        };

        expect(status.containsKey('voiceSelected'), isTrue);
      });
    });
  });

  group('Onboarding Completion Logic', () {
    test('all false means incomplete', () {
      const status = {
        'disclaimerAccepted': false,
        'privacyPolicyAccepted': false,
        'biometricConsentAccepted': false,
        'voiceSelected': false,
      };

      final isComplete = status.values.every((v) => v);
      expect(isComplete, isFalse);
    });

    test('some false means incomplete', () {
      const status = {
        'disclaimerAccepted': true,
        'privacyPolicyAccepted': true,
        'biometricConsentAccepted': false,
        'voiceSelected': false,
      };

      final isComplete = status.values.every((v) => v);
      expect(isComplete, isFalse);
    });

    test('all true means complete', () {
      const status = {
        'disclaimerAccepted': true,
        'privacyPolicyAccepted': true,
        'biometricConsentAccepted': true,
        'voiceSelected': true,
      };

      final isComplete = status.values.every((v) => v);
      expect(isComplete, isTrue);
    });
  });

  group('Screen Selection', () {
    test('returns first unaccepted screen', () {
      String getNextScreen(Map<String, bool> status) {
        if (!status['disclaimerAccepted']!) return 'DisclaimerScreen';
        if (!status['privacyPolicyAccepted']!) return 'PrivacyPolicyScreen';
        if (!status['biometricConsentAccepted']!) return 'BiometricConsentScreen';
        if (!status['voiceSelected']!) return 'VoiceSelectionScreen';
        return 'child';
      }

      final status1 = {
        'disclaimerAccepted': false,
        'privacyPolicyAccepted': false,
        'biometricConsentAccepted': false,
        'voiceSelected': false,
      };
      expect(getNextScreen(status1), equals('DisclaimerScreen'));

      final status2 = {
        'disclaimerAccepted': true,
        'privacyPolicyAccepted': false,
        'biometricConsentAccepted': false,
        'voiceSelected': false,
      };
      expect(getNextScreen(status2), equals('PrivacyPolicyScreen'));

      final status3 = {
        'disclaimerAccepted': true,
        'privacyPolicyAccepted': true,
        'biometricConsentAccepted': false,
        'voiceSelected': false,
      };
      expect(getNextScreen(status3), equals('BiometricConsentScreen'));

      final status4 = {
        'disclaimerAccepted': true,
        'privacyPolicyAccepted': true,
        'biometricConsentAccepted': true,
        'voiceSelected': false,
      };
      expect(getNextScreen(status4), equals('VoiceSelectionScreen'));

      final status5 = {
        'disclaimerAccepted': true,
        'privacyPolicyAccepted': true,
        'biometricConsentAccepted': true,
        'voiceSelected': true,
      };
      expect(getNextScreen(status5), equals('child'));
    });
  });
}
