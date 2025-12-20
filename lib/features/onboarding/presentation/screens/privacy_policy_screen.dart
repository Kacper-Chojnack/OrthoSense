import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/onboarding/presentation/providers/onboarding_provider.dart';

/// GDPR-compliant Privacy Policy and Data Processing Consent Screen.
/// Enforced during onboarding before accessing the main app.
class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() =>
      _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  bool _dataProcessingConsent = false;
  bool _anonymizationConsent = false;

  bool get _canAccept => _dataProcessingConsent && _anonymizationConsent;

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
                      child: Icon(
                        Icons.privacy_tip,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Privacy Policy & Data Consent',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'GDPR Compliant',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Data We Collect Section
                    _buildSectionHeader(
                      context,
                      icon: Icons.data_usage,
                      title: 'Data We Collect',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildBulletPoint(
                          context,
                          'Account Information',
                          'Email address, name, role (patient/therapist)',
                        ),
                        _buildBulletPoint(
                          context,
                          'Exercise Session Data',
                          'Anonymized movement metrics, scores, pain levels',
                        ),
                        _buildBulletPoint(
                          context,
                          'Treatment Progress',
                          'Rehabilitation plan adherence and outcomes',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // How We Protect Your Data
                    _buildSectionHeader(
                      context,
                      icon: Icons.security,
                      title: 'How We Protect Your Data',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildBulletPoint(
                          context,
                          'On-Device Processing',
                          'Video from your camera is NEVER uploaded. '
                              'All pose analysis happens locally on your device.',
                        ),
                        _buildBulletPoint(
                          context,
                          'Anonymized Metadata',
                          'Only anonymized joint coordinates and metrics '
                              'are synced, never raw video.',
                        ),
                        _buildBulletPoint(
                          context,
                          'Secure Storage',
                          'All data is encrypted in transit (TLS 1.3) '
                              'and at rest (AES-256).',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Your Rights (GDPR)
                    _buildSectionHeader(
                      context,
                      icon: Icons.gavel,
                      title: 'Your Rights (GDPR)',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildBulletPoint(
                          context,
                          'Right to Access',
                          'Download all your data anytime from Settings.',
                        ),
                        _buildBulletPoint(
                          context,
                          'Right to Rectification',
                          'Update or correct your personal information.',
                        ),
                        _buildBulletPoint(
                          context,
                          'Right to Erasure',
                          'Delete your account and ALL associated data '
                              'permanently ("Right to be Forgotten").',
                        ),
                        _buildBulletPoint(
                          context,
                          'Right to Portability',
                          'Export your data in a machine-readable format.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Consent Checkboxes
                    _buildConsentCheckbox(
                      context,
                      value: _dataProcessingConsent,
                      title: 'Data Processing Consent',
                      description:
                          'I consent to the processing of my personal data '
                          'as described in this privacy policy for the purpose '
                          'of providing telerehabilitation services.',
                      onChanged: (value) {
                        setState(() => _dataProcessingConsent = value ?? false);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildConsentCheckbox(
                      context,
                      value: _anonymizationConsent,
                      title: 'Anonymization Understanding',
                      description:
                          'I understand that video captured by my camera is '
                          'processed locally and NEVER leaves my device. '
                          'Only anonymized movement metrics are stored and synced.',
                      onChanged: (value) {
                        setState(() => _anonymizationConsent = value ?? false);
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
                        'Please accept both consents to continue',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canAccept
                          ? () {
                              ref
                                  .read(onboardingControllerProvider.notifier)
                                  .acceptPrivacyPolicy();
                            }
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Accept & Continue'),
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(
    BuildContext context,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
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
      ),
    );
  }

  Widget _buildConsentCheckbox(
    BuildContext context, {
    required bool value,
    required String title,
    required String description,
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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
              ),
              const SizedBox(width: 8),
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
          ),
        ),
      ),
    );
  }
}
