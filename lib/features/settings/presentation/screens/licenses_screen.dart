import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom licenses screen that includes OrthoSense license and all dependencies.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  final List<_LicenseData> _licenses = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    // Add OrthoSense license first
    _licenses.add(
      _LicenseData(
        title: 'OrthoSense',
        subtitle: 'Digital Health Telerehabilitation',
        license: _orthoSenseLicense,
      ),
    );

    // Load all Flutter package licenses
    await LicenseRegistry.licenses.forEach((license) {
      final packages = license.packages.toList();
      final paragraphs = license.paragraphs.map((p) => p.text).join('\n\n');

      for (final package in packages) {
        final existingIndex = _licenses.indexWhere((l) => l.title == package);
        if (existingIndex >= 0) {
          // Append to existing license
          _licenses[existingIndex] = _LicenseData(
            title: _licenses[existingIndex].title,
            subtitle: _licenses[existingIndex].subtitle,
            license:
                '${_licenses[existingIndex].license}\n\n---\n\n$paragraphs',
          );
        } else {
          _licenses.add(
            _LicenseData(
              title: package,
              subtitle: null,
              license: paragraphs,
            ),
          );
        }
      }
    });

    // Sort licenses alphabetically (but keep OrthoSense first)
    final orthoSense = _licenses.removeAt(0);
    _licenses.sort((a, b) => a.title.compareTo(b.title));
    _licenses.insert(0, orthoSense);

    if (mounted) {
      setState(() {
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Source Licenses'),
      ),
      body: _loaded
          ? ListView.builder(
              itemCount: _licenses.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader(context, colorScheme);
                }

                final license = _licenses[index - 1];
                final isOrthoSense = index == 1;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  color: isOrthoSense
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : null,
                  child: ListTile(
                    leading: isOrthoSense
                        ? Image.asset(
                            'assets/images/logo.png',
                            width: 32,
                            height: 32,
                            color: colorScheme.primary,
                          )
                        : Icon(
                            Icons.code,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    title: Text(
                      license.title,
                      style: isOrthoSense
                          ? TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                    subtitle: license.subtitle != null
                        ? Text(license.subtitle!)
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLicenseDetails(context, license),
                  ),
                );
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading licenses...'),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'OrthoSense',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This app uses the following open source packages:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  void _showLicenseDetails(BuildContext context, _LicenseData license) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _LicenseDetailScreen(license: license),
      ),
    );
  }

  static const String _orthoSenseLicense = '''
MIT License

Copyright (c) 2025-2026 Kacper Chojnacki & Zosia Dekowska

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

MEDICAL DISCLAIMER

This software is intended for educational and research purposes only. It is NOT
a certified medical device and should NOT be used as a substitute for professional
medical advice, diagnosis, or treatment. Always seek the advice of a qualified
healthcare provider with any questions regarding a medical condition or
rehabilitation program.

The authors and contributors of this software make no representations or warranties
of any kind concerning the safety, suitability, or efficacy of this software for
any particular purpose. Use at your own risk.
''';
}

class _LicenseData {
  const _LicenseData({
    required this.title,
    required this.license,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String license;
}

class _LicenseDetailScreen extends StatelessWidget {
  const _LicenseDetailScreen({required this.license});

  final _LicenseData license;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOrthoSense = license.title == 'OrthoSense';

    return Scaffold(
      appBar: AppBar(
        title: Text(license.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOrthoSense) ...[
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 64,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (license.subtitle != null)
              Text(
                license.subtitle!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            const SizedBox(height: 16),
            SelectableText(
              license.license,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
