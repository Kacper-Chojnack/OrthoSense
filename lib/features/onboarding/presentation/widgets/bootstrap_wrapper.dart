import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:orthosense/features/onboarding/presentation/screens/biometric_consent_screen.dart';
import 'package:orthosense/features/onboarding/presentation/screens/disclaimer_screen.dart';
import 'package:orthosense/features/onboarding/presentation/screens/privacy_policy_screen.dart';
import 'package:orthosense/features/onboarding/presentation/screens/voice_selection_screen.dart';

/// Wrapper that enforces onboarding flow completion before accessing the app.
/// Order: Disclaimer → Privacy Policy → Biometric Consent → Voice Selection
class BootstrapWrapper extends ConsumerWidget {
  const BootstrapWrapper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingStatus = ref.watch(onboardingControllerProvider);

    // Step 1: Medical Disclaimer
    if (!onboardingStatus.disclaimerAccepted) {
      return const DisclaimerScreen();
    }

    // Step 2: Privacy Policy & GDPR Consent
    if (!onboardingStatus.privacyPolicyAccepted) {
      return const PrivacyPolicyScreen();
    }

    // Step 3: Biometric Data Processing Consent
    if (!onboardingStatus.biometricConsentAccepted) {
      return const BiometricConsentScreen();
    }

    // Step 4: Voice Selection
    if (!onboardingStatus.voiceSelected) {
      return const VoiceSelectionScreen();
    }

    return child;
  }
}
