import 'package:orthosense/core/providers/preferences_provider.dart';
import 'package:orthosense/core/providers/tts_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

class OnboardingStatus {
  OnboardingStatus({
    required this.disclaimerAccepted,
    required this.privacyPolicyAccepted,
    required this.biometricConsentAccepted,
    required this.voiceSelected,
  });

  final bool disclaimerAccepted;
  final bool privacyPolicyAccepted;
  final bool biometricConsentAccepted;
  final bool voiceSelected;

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
    await prefs.setDisclaimerAccepted(value: true);
    state = state.copyWith(disclaimerAccepted: true);
  }

  Future<void> acceptPrivacyPolicy() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setPrivacyPolicyAccepted(value: true);
    state = state.copyWith(privacyPolicyAccepted: true);
  }

  Future<void> acceptBiometricConsent() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setBiometricConsentAccepted(value: true);
    state = state.copyWith(biometricConsentAccepted: true);
  }

  Future<void> completeVoiceSelection(Map<String, String> voice) async {
    final prefs = ref.read(preferencesServiceProvider);
    final tts = ref.read(ttsServiceProvider);

    await tts.setVoice(voice);
    await prefs.setVoiceSelected(value: true);
    await prefs.setSelectedVoiceKey(voice['name'] ?? '');

    state = state.copyWith(voiceSelected: true);
  }

  /// Resets all onboarding steps (for testing or re-onboarding).
  Future<void> resetOnboarding() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setDisclaimerAccepted(value: false);
    await prefs.setPrivacyPolicyAccepted(value: false);
    await prefs.setBiometricConsentAccepted(value: false);
    await prefs.setVoiceSelected(value: false);
    state = OnboardingStatus(
      disclaimerAccepted: false,
      privacyPolicyAccepted: false,
      biometricConsentAccepted: false,
      voiceSelected: false,
    );
  }
}
