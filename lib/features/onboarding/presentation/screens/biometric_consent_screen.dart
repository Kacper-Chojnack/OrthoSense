import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/onboarding/presentation/providers/onboarding_provider.dart';

/// Biometric Data Processing Consent Screen.
/// Required before first use of camera for pose estimation.
/// Explains how pose data is anonymized and processed locally.
class BiometricConsentScreen extends ConsumerStatefulWidget {
  const BiometricConsentScreen({super.key});

  @override
  ConsumerState<BiometricConsentScreen> createState() =>
      _BiometricConsentScreenState();
}

class _BiometricConsentScreenState
    extends ConsumerState<BiometricConsentScreen> {
  bool _understandsLocalProcessing = false;
  bool _consentsToMetricsStorage = false;
  bool _understandsNoVideoStorage = false;

  bool get _canAccept =>
      _understandsLocalProcessing &&
      _consentsToMetricsStorage &&
      _understandsNoVideoStorage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_enhance,
                          size: 48,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Biometric Data Consent',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Camera & Pose Estimation',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // How It Works Section
                    _buildInfoSection(
                      context,
                      icon: Icons.memory,
                      title: 'How It Works',
                      description:
                          'OrthoSense uses your device camera to track your body '
                          "movements during exercises. Here's what you need to know:",
                    ),
                    const SizedBox(height: 24),

                    // Key Points with Icons
                    _buildKeyPoint(
                      context,
                      icon: Icons.phone_android,
                      iconColor: Colors.green,
                      title: 'On-Device Processing',
                      description:
                          'All pose estimation happens locally on your device '
                          'using Edge AI (MediaPipe). Your camera feed is NEVER '
                          'sent to any server.',
                    ),
                    const SizedBox(height: 16),

                    _buildKeyPoint(
                      context,
                      icon: Icons.videocam_off,
                      iconColor: Colors.red,
                      title: 'No Video Storage',
                      description:
                          'Raw video is processed in real-time and immediately '
                          'discarded. We do NOT store, record, or transmit any '
                          'video footage.',
                    ),
                    const SizedBox(height: 16),

                    _buildKeyPoint(
                      context,
                      icon: Icons.analytics,
                      iconColor: Colors.blue,
                      title: 'Anonymized Metrics Only',
                      description:
                          'We only store anonymized numerical data: joint angles, '
                          'movement velocities, and exercise scores. This data '
                          'cannot identify you visually.',
                    ),
                    const SizedBox(height: 16),

                    _buildKeyPoint(
                      context,
                      icon: Icons.lock,
                      iconColor: Colors.purple,
                      title: 'Secure & Encrypted',
                      description:
                          'All stored metrics are encrypted and can only be '
                          'accessed by you and your authorized therapist.',
                    ),
                    const SizedBox(height: 32),

                    // Visual Diagram
                    _buildProcessDiagram(context),
                    const SizedBox(height: 32),

                    // Consent Checkboxes
                    Text(
                      'Please confirm your understanding:',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildConsentItem(
                      context,
                      value: _understandsLocalProcessing,
                      label:
                          'I understand that camera processing happens entirely '
                          'on my device and video never leaves my phone.',
                      onChanged: (value) {
                        setState(
                          () => _understandsLocalProcessing = value ?? false,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildConsentItem(
                      context,
                      value: _consentsToMetricsStorage,
                      label:
                          'I consent to the storage and synchronization of '
                          'anonymized movement metrics for tracking my rehabilitation progress.',
                      onChanged: (value) {
                        setState(
                          () => _consentsToMetricsStorage = value ?? false,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildConsentItem(
                      context,
                      value: _understandsNoVideoStorage,
                      label:
                          'I understand that NO video or images of me are ever '
                          'stored, recorded, or transmitted.',
                      onChanged: (value) {
                        setState(
                          () => _understandsNoVideoStorage = value ?? false,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_canAccept)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Please confirm all items to continue',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _canAccept
                          ? () {
                              ref
                                  .read(onboardingControllerProvider.notifier)
                                  .acceptBiometricConsent();
                            }
                          : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('I Consent & Understand'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPoint(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessDiagram(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Data Flow',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDiagramStep(
                  context,
                  icon: Icons.videocam,
                  label: 'Camera',
                  color: Colors.blue,
                ),
                Icon(
                  Icons.arrow_forward,
                  color: colorScheme.outline,
                ),
                _buildDiagramStep(
                  context,
                  icon: Icons.phone_android,
                  label: 'On-Device\nAI',
                  color: Colors.green,
                ),
                Icon(
                  Icons.arrow_forward,
                  color: colorScheme.outline,
                ),
                _buildDiagramStep(
                  context,
                  icon: Icons.numbers,
                  label: 'Metrics\nOnly',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Video NEVER uploaded',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagramStep(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildConsentItem(
    BuildContext context, {
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: value
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
