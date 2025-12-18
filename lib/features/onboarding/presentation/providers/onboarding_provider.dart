import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:orthosense/core/providers/preferences_provider.dart';
import 'package:orthosense/core/providers/tts_provider.dart';

part 'onboarding_provider.g.dart';

class OnboardingStatus {
  final bool disclaimerAccepted;
  final bool voiceSelected;

  OnboardingStatus({
    required this.disclaimerAccepted,
    required this.voiceSelected,
  });

  OnboardingStatus copyWith({
    bool? disclaimerAccepted,
    bool? voiceSelected,
  }) {
    return OnboardingStatus(
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
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
      voiceSelected: prefs.isVoiceSelected,
    );
  }

  Future<void> acceptDisclaimer() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setDisclaimerAccepted(true);
    state = state.copyWith(disclaimerAccepted: true);
  }

  Future<void> completeVoiceSelection(Map<String, String> voice) async {
    final prefs = ref.read(preferencesServiceProvider);
    final tts = ref.read(ttsServiceProvider);
    
    await tts.setVoice(voice);
    await prefs.setVoiceSelected(true);
    await prefs.setSelectedVoiceKey(voice['name'] ?? '');
    
    state = state.copyWith(voiceSelected: true);
  }
}
