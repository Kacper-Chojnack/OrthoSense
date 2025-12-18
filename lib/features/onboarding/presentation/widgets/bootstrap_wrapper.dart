import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:orthosense/features/onboarding/presentation/screens/disclaimer_screen.dart';
import 'package:orthosense/features/onboarding/presentation/screens/voice_selection_screen.dart';

class BootstrapWrapper extends ConsumerWidget {
  final Widget child;
  const BootstrapWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingStatus = ref.watch(onboardingControllerProvider);

    if (!onboardingStatus.disclaimerAccepted) {
      return const DisclaimerScreen();
    }

    if (!onboardingStatus.voiceSelected) {
      return const VoiceSelectionScreen();
    }

    return child;
  }
}
