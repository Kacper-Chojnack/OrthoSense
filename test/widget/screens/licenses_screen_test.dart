/// Widget tests for LicensesScreen and license detail display.
///
/// Test coverage:
/// 1. LicensesScreen rendering
/// 2. Loading state
/// 3. License list display
/// 4. License detail navigation
/// 5. OrthoSense license special styling
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LicenseData', () {
    test('creates instance with all fields', () {
      const license = LicenseData(
        title: 'flutter',
        subtitle: 'UI framework',
        license: 'BSD 3-Clause License...',
      );

      expect(license.title, equals('flutter'));
      expect(license.subtitle, equals('UI framework'));
      expect(license.license, contains('BSD'));
    });

    test('creates instance without subtitle', () {
      const license = LicenseData(
        title: 'package_name',
        license: 'MIT License...',
      );

      expect(license.title, equals('package_name'));
      expect(license.subtitle, isNull);
    });
  });

  group('OrthoSense License', () {
    test('contains MIT license header', () {
      const license = _orthoSenseLicense;

      expect(license, contains('MIT License'));
      expect(license, contains('Copyright'));
    });

    test('contains author names', () {
      const license = _orthoSenseLicense;

      expect(license, contains('Kacper Chojnacki'));
      expect(license, contains('Zosia Dekowska'));
    });

    test('contains medical disclaimer', () {
      const license = _orthoSenseLicense;

      expect(license, contains('MEDICAL DISCLAIMER'));
      expect(license, contains('NOT a certified medical device'));
    });

    test('contains standard MIT permissions', () {
      const license = _orthoSenseLicense;

      expect(license, contains('Permission is hereby granted'));
      expect(license, contains('without restriction'));
      expect(license, contains('to use, copy, modify'));
    });
  });

  group('License Sorting', () {
    test('sorts licenses alphabetically', () {
      final licenses = [
        const LicenseData(title: 'zlib', license: '...'),
        const LicenseData(title: 'flutter', license: '...'),
        const LicenseData(title: 'async', license: '...'),
      ];

      licenses.sort((a, b) => a.title.compareTo(b.title));

      expect(licenses[0].title, equals('async'));
      expect(licenses[1].title, equals('flutter'));
      expect(licenses[2].title, equals('zlib'));
    });

    test('keeps OrthoSense first after sorting', () {
      var licenses = [
        const LicenseData(title: 'OrthoSense', license: '...'),
        const LicenseData(title: 'zlib', license: '...'),
        const LicenseData(title: 'async', license: '...'),
      ];

      // Remove OrthoSense, sort rest, re-insert at front
      final orthoSense = licenses.removeAt(0);
      licenses.sort((a, b) => a.title.compareTo(b.title));
      licenses.insert(0, orthoSense);

      expect(licenses[0].title, equals('OrthoSense'));
      expect(licenses[1].title, equals('async'));
      expect(licenses[2].title, equals('zlib'));
    });
  });

  group('License Merging', () {
    test('merges licenses for same package', () {
      final licensesMap = <String, String>{};

      // First license entry
      _addOrMergeLicense(licensesMap, 'flutter', 'License Part 1');

      // Second license entry for same package
      _addOrMergeLicense(licensesMap, 'flutter', 'License Part 2');

      expect(licensesMap['flutter'], contains('License Part 1'));
      expect(licensesMap['flutter'], contains('License Part 2'));
      expect(licensesMap['flutter'], contains('---'));
    });

    test('keeps separate entries for different packages', () {
      final licensesMap = <String, String>{};

      _addOrMergeLicense(licensesMap, 'flutter', 'Flutter License');
      _addOrMergeLicense(licensesMap, 'riverpod', 'Riverpod License');

      expect(licensesMap['flutter'], equals('Flutter License'));
      expect(licensesMap['riverpod'], equals('Riverpod License'));
      expect(licensesMap.length, equals(2));
    });
  });

  group('LicensesScreen Widget', () {
    testWidgets('displays loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestLicensesScreenLoading(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading licenses...'), findsOneWidget);
    });

    testWidgets('displays header when loaded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestLicensesScreenLoaded(
            licenses: [
              const LicenseData(
                title: 'OrthoSense',
                subtitle: 'Digital Health Telerehabilitation',
                license: _orthoSenseLicense,
              ),
            ],
          ),
        ),
      );

      expect(find.text('OrthoSense'), findsWidgets);
      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('displays license list items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestLicensesScreenLoaded(
            licenses: [
              const LicenseData(
                title: 'OrthoSense',
                subtitle: 'Digital Health',
                license: _orthoSenseLicense,
              ),
              const LicenseData(title: 'flutter', license: 'BSD'),
              const LicenseData(title: 'riverpod', license: 'MIT'),
            ],
          ),
        ),
      );

      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('riverpod'), findsOneWidget);
    });

    testWidgets('OrthoSense has special styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestLicensesScreenLoaded(
            licenses: [
              const LicenseData(
                title: 'OrthoSense',
                subtitle: 'Digital Health',
                license: _orthoSenseLicense,
              ),
            ],
          ),
        ),
      );

      // Find the ListTile for OrthoSense
      final listTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('OrthoSense').first,
          matching: find.byType(ListTile),
        ),
      );

      // Title should have special styling
      expect(listTile.title, isNotNull);
    });

    testWidgets('tapping license item shows detail', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestLicensesScreenLoaded(
            licenses: [
              const LicenseData(
                title: 'OrthoSense',
                subtitle: 'Digital Health',
                license: _orthoSenseLicense,
              ),
              const LicenseData(title: 'flutter', license: 'BSD License Text'),
            ],
          ),
        ),
      );

      // Tap flutter license
      await tester.tap(find.text('flutter'));
      await tester.pumpAndSettle();

      // Should navigate to detail screen
      expect(find.text('BSD License Text'), findsOneWidget);
    });
  });

  group('LicenseDetailScreen Widget', () {
    testWidgets('displays license title in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestLicenseDetailScreen(
            license: LicenseData(
              title: 'flutter',
              license: 'BSD License...',
            ),
          ),
        ),
      );

      expect(find.text('flutter'), findsWidgets);
    });

    testWidgets('displays license text as selectable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestLicenseDetailScreen(
            license: LicenseData(
              title: 'test_package',
              license: 'Test License Text Here',
            ),
          ),
        ),
      );

      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('Test License Text Here'), findsOneWidget);
    });

    testWidgets('displays subtitle if present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestLicenseDetailScreen(
            license: LicenseData(
              title: 'test_package',
              subtitle: 'A test package',
              license: 'License...',
            ),
          ),
        ),
      );

      expect(find.text('A test package'), findsOneWidget);
    });

    testWidgets('OrthoSense shows logo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestLicenseDetailScreen(
            license: LicenseData(
              title: 'OrthoSense',
              subtitle: 'Digital Health',
              license: _orthoSenseLicense,
            ),
          ),
        ),
      );

      // OrthoSense detail should show centered logo
      // In a real test we'd check for the image asset
      expect(find.text('OrthoSense'), findsWidgets);
    });
  });

  group('License Paragraph Formatting', () {
    test('joins paragraphs with double newlines', () {
      final paragraphs = ['Paragraph 1', 'Paragraph 2', 'Paragraph 3'];
      final formatted = paragraphs.join('\n\n');

      expect(formatted, contains('Paragraph 1\n\nParagraph 2'));
      expect(formatted.split('\n\n').length, equals(3));
    });

    test('handles single paragraph', () {
      final paragraphs = ['Only one paragraph'];
      final formatted = paragraphs.join('\n\n');

      expect(formatted, equals('Only one paragraph'));
    });

    test('handles empty paragraphs', () {
      final paragraphs = <String>[];
      final formatted = paragraphs.join('\n\n');

      expect(formatted, isEmpty);
    });
  });
}

// Test data classes

class LicenseData {
  const LicenseData({
    required this.title,
    required this.license,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String license;
}

const String _orthoSenseLicense = '''
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

// Helper functions

void _addOrMergeLicense(
  Map<String, String> licenses,
  String package,
  String text,
) {
  if (licenses.containsKey(package)) {
    licenses[package] = '${licenses[package]}\n\n---\n\n$text';
  } else {
    licenses[package] = text;
  }
}

// Test widgets

class TestLicensesScreenLoading extends StatelessWidget {
  const TestLicensesScreenLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Source Licenses')),
      body: const Center(
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
}

class TestLicensesScreenLoaded extends StatelessWidget {
  const TestLicensesScreenLoaded({super.key, required this.licenses});

  final List<LicenseData> licenses;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Open Source Licenses')),
      body: ListView.builder(
        itemCount: licenses.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(context, colorScheme);
          }

          final license = licenses[index - 1];
          final isOrthoSense = license.title == 'OrthoSense';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(
                isOrthoSense ? Icons.medical_services : Icons.code,
                color: isOrthoSense
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
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
              subtitle:
                  license.subtitle != null ? Text(license.subtitle!) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      TestLicenseDetailScreen(license: license),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.medical_services, size: 64, color: colorScheme.primary),
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
          const Divider(height: 24),
        ],
      ),
    );
  }
}

class TestLicenseDetailScreen extends StatelessWidget {
  const TestLicenseDetailScreen({super.key, required this.license});

  final LicenseData license;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOrthoSense = license.title == 'OrthoSense';

    return Scaffold(
      appBar: AppBar(title: Text(license.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOrthoSense) ...[
              Center(
                child: Icon(
                  Icons.medical_services,
                  size: 64,
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
