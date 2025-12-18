import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:orthosense/core/providers/preferences_provider.dart';
import 'package:orthosense/core/providers/tts_provider.dart';

part 'onboarding_provider.g.dart';

class OnboardingStatus {
  final bool disclaimerAccepted;
  final bool privacyPolicyAccepted;
  final bool biometricConsentAccepted;
  final bool voiceSelected;

  OnboardingStatus({
    required this.disclaimerAccepted,
    required this.privacyPolicyAccepted,
    required this.biometricConsentAccepted,
    required this.voiceSelected,
  });

  /// Returns true if all onboarding steps are completed.
  bool get isComplete =>
      disclaimerAccepted &&
      privacyPolicyAccepted &&
      biometricConsentAccepted &&
      voiceSelected;

  OnboardingStatus copyWith({
    bool? disclaimerAccepted,
    bool? privacyPolicyAccepted,
    bool? biometricConsentAccepted,
    bool? voiceSelected,
  }) {
    return OnboardingStatus(
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      privacyPolicyAccepted:
          privacyPolicyAccepted ?? this.privacyPolicyAccepted,
      biometricConsentAccepted:
          biometricConsentAccepted ?? this.biometricConsentAccepted,
      voiceSelected: voiceSelected ?? this.voiceSelected,
    );
  }
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingStatus build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return OnboardingStatus(
      disclaimerAccepted: prefs.isDisclaimerAccepted,
      privacyPolicyAccepted: prefs.isPrivacyPolicyAccepted,
      biometricConsentAccepted: prefs.isBiometricConsentAccepted,
      voiceSelected: prefs.isVoiceSelected,
    );
  }

  Future<void> acceptDisclaimer() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setDisclaimerAccepted(true);
    state = state.copyWith(disclaimerAccepted: true);
  }

  Future<void> acceptPrivacyPolicy() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setPrivacyPolicyAccepted(true);
    state = state.copyWith(privacyPolicyAccepted: true);
  }

  Future<void> acceptBiometricConsent() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setBiometricConsentAccepted(true);
    state = state.copyWith(biometricConsentAccepted: true);
  }

  Future<void> completeVoiceSelection(Map<String, String> voice) async {
    final prefs = ref.read(preferencesServiceProvider);
    final tts = ref.read(ttsServiceProvider);

    await tts.setVoice(voice);
    await prefs.setVoiceSelected(true);
    await prefs.setSelectedVoiceKey(voice['name'] ?? '');

    state = state.copyWith(voiceSelected: true);
  }

  /// Resets all onboarding steps (for testing or re-onboarding).
  Future<void> resetOnboarding() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setDisclaimerAccepted(false);
    await prefs.setPrivacyPolicyAccepted(false);
    await prefs.setBiometricConsentAccepted(false);
    await prefs.setVoiceSelected(false);
    state = OnboardingStatus(
      disclaimerAccepted: false,
      privacyPolicyAccepted: false,
      biometricConsentAccepted: false,
      voiceSelected: false,
    );
  }
}
