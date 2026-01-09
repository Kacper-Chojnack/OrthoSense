import 'package:flutter/material.dart';

/// Generic legal document screen for Privacy Policy and Terms of Service.
class LegalScreen extends StatelessWidget {
  const LegalScreen({
    required this.title,
    required this.content,
    super.key,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'OrthoSense',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Engineering Thesis Project',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            SelectableText(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Last updated: January 2026',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Privacy Policy content for OrthoSense.
const String privacyPolicyContent = '''
PRIVACY POLICY

1. INTRODUCTION

OrthoSense is a telerehabilitation application developed as an engineering thesis project at Polish-Japanese Academy of Information Technology - Faculty in Gdańsk. This Privacy Policy explains how we handle information when you use our application.

2. DATA COLLECTION & PROCESSING

2.1 Local Processing
OrthoSense uses Edge AI technology to analyze your exercises. This means:
• Video from your camera is processed LOCALLY on your device
• Video streams are NEVER transmitted to external servers
• Pose estimation happens entirely on your smartphone

2.2 What We Store Locally
• Exercise session metadata (duration, repetitions, scores)
• User preferences and settings
• Profile information you provide

2.3 What We Send to Our Servers
• Anonymized exercise performance metrics (no video)
• Device information for app compatibility
• Crash reports to improve stability

3. DATA SECURITY

• All data transmission uses TLS 1.2/1.3 encryption
• User identifiers are hashed using SHA-256
• No personally identifiable information is stored on servers

4. THIRD-PARTY SERVICES

OrthoSense uses:
• Google ML Kit for pose detection (on-device only)
• TensorFlow Lite for exercise classification (on-device only)

These services process data locally and do not transmit your information.

5. YOUR RIGHTS

You can:
• Delete all local data by uninstalling the app
• Request account deletion through the app settings
• Export your exercise history

6. ACADEMIC USE

This application was developed for educational and research purposes. It is NOT a certified medical device.

7. CONTACT

For questions about this Privacy Policy, contact the development team through the university.

---

© 2025-2026 Kacper Chojnacki & Zosia Dekowska
Polish-Japanese Academy of Information Technology - Faculty in Gdańsk
''';

/// Terms of Service content for OrthoSense.
const String termsOfServiceContent = '''
TERMS OF SERVICE

1. ACCEPTANCE OF TERMS

By using OrthoSense, you agree to these Terms of Service. If you do not agree, please do not use the application.

2. NATURE OF THE APPLICATION

OrthoSense is an engineering thesis project developed for academic purposes. It is:
• A prototype/demonstration application
• NOT a certified medical device
• NOT a replacement for professional medical advice

3. INTENDED USE

OrthoSense is designed to:
• Assist with exercise monitoring during rehabilitation
• Provide real-time feedback on movement quality
• Track exercise progress over time

4. MEDICAL DISCLAIMER

IMPORTANT: This application is for educational and informational purposes only.

• Always consult a healthcare professional before starting any exercise program
• Do not rely solely on this app for medical decisions
• Stop exercising immediately if you experience pain or discomfort
• The developers are not liable for any injuries resulting from app use

5. USER RESPONSIBILITIES

You agree to:
• Use the application only for its intended purpose
• Provide accurate information when required
• Not attempt to reverse-engineer or modify the application
• Not use the app if advised against exercise by a medical professional

6. INTELLECTUAL PROPERTY

• OrthoSense is released under the MIT License
• Third-party libraries are subject to their respective licenses
• The OrthoSense name and logo are property of the developers

7. LIMITATION OF LIABILITY

This application is provided "AS IS" without warranty of any kind. The developers shall not be liable for:
• Any injuries sustained during exercise
• Data loss or corruption
• App malfunctions or errors
• Any indirect or consequential damages

8. UPDATES

These terms may be updated as the project evolves. Continued use after updates constitutes acceptance of new terms.

9. GOVERNING LAW

These terms are governed by the laws of Poland and the academic regulations of Polish-Japanese Academy of Information Technology.

10. CONTACT

For questions regarding these Terms of Service, please contact the development team through university channels.

---

© 2025-2026 Kacper Chojnacki & Zosia Dekowska
Polish-Japanese Academy of Information Technology - Faculty in Gdańsk
Engineering Thesis Project
''';
