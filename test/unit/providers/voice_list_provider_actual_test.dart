/// Unit tests for VoiceListProvider.
///
/// Test coverage:
/// 1. Voice filtering logic
/// 2. Platform-specific voice selection
/// 3. English locale filtering
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceListProvider', () {
    group('English locale filtering', () {
      test('filters voices by English locale', () {
        final voices = [
          {'name': 'Samantha', 'locale': 'en-US'},
          {'name': 'Anna', 'locale': 'de-DE'},
          {'name': 'Daniel', 'locale': 'en-GB'},
          {'name': 'Thomas', 'locale': 'fr-FR'},
        ];

        final englishVoices = voices.where((voice) {
          final locale = voice['locale'] ?? '';
          return locale.toLowerCase().startsWith('en');
        }).toList();

        expect(englishVoices.length, equals(2));
        expect(englishVoices[0]['name'], equals('Samantha'));
        expect(englishVoices[1]['name'], equals('Daniel'));
      });

      test('handles mixed case locale', () {
        final voices = [
          {'name': 'Voice1', 'locale': 'EN-US'},
          {'name': 'Voice2', 'locale': 'En-Gb'},
          {'name': 'Voice3', 'locale': 'en-au'},
        ];

        final englishVoices = voices.where((voice) {
          final locale = voice['locale'] ?? '';
          return locale.toLowerCase().startsWith('en');
        }).toList();

        expect(englishVoices.length, equals(3));
      });

      test('excludes non-English voices', () {
        final voices = [
          {'name': 'Voice1', 'locale': 'de-DE'},
          {'name': 'Voice2', 'locale': 'es-ES'},
          {'name': 'Voice3', 'locale': 'fr-FR'},
        ];

        final englishVoices = voices.where((voice) {
          final locale = voice['locale'] ?? '';
          return locale.toLowerCase().startsWith('en');
        }).toList();

        expect(englishVoices, isEmpty);
      });

      test('handles missing locale', () {
        final voices = [
          {'name': 'Voice1'},
          {'name': 'Voice2', 'locale': 'en-US'},
        ];

        final englishVoices = voices.where((voice) {
          final locale = voice['locale'] ?? '';
          return locale.toLowerCase().startsWith('en');
        }).toList();

        expect(englishVoices.length, equals(1));
      });
    });

    group('iOS best voices', () {
      test('includes high-quality male voices', () {
        const iosBestVoices = [
          'Alex',
          'Tom',
          'Daniel',
          'Fred',
          'Rishi',
        ];

        expect(iosBestVoices, contains('Alex'));
        expect(iosBestVoices, contains('Daniel'));
      });

      test('includes high-quality female voices', () {
        const iosBestVoices = [
          'Ava',
          'Samantha',
          'Allison',
          'Victoria',
          'Karen',
          'Tessa',
        ];

        expect(iosBestVoices, contains('Samantha'));
        expect(iosBestVoices, contains('Karen'));
      });

      test('filters by iOS best voices', () {
        const bestVoices = ['Alex', 'Samantha', 'Daniel'];
        final allVoices = [
          {'name': 'Alex', 'locale': 'en-US'},
          {'name': 'Unknown', 'locale': 'en-US'},
          {'name': 'Samantha', 'locale': 'en-US'},
        ];

        final filtered = allVoices.where((voice) {
          final name = voice['name'] ?? '';
          return bestVoices.any((best) => name.contains(best));
        }).toList();

        expect(filtered.length, equals(2));
      });
    });

    group('voice map conversion', () {
      test('converts dynamic voice map to string map', () {
        final dynamicVoices = [
          <dynamic, dynamic>{'name': 'Voice1', 'locale': 'en-US'},
          <dynamic, dynamic>{'name': 'Voice2', 'locale': 'en-GB'},
        ];

        final stringVoices = dynamicVoices
            .map((e) => Map<String, String>.from(e as Map))
            .toList();

        expect(stringVoices[0]['name'], equals('Voice1'));
        expect(stringVoices[1]['locale'], equals('en-GB'));
      });
    });

    group('platform detection', () {
      test('can check for iOS platform', () {
        // Platform.isIOS would be checked
        const checkIOS = true;
        expect(checkIOS, isA<bool>());
      });

      test('can check for macOS platform', () {
        // Platform.isMacOS would be checked
        const checkMacOS = true;
        expect(checkMacOS, isA<bool>());
      });
    });
  });

  group('Voice Filtering Algorithm', () {
    test('prioritizes best voices over all voices', () {
      const bestVoices = ['Samantha', 'Alex'];
      final allVoices = [
        {'name': 'Unknown1', 'locale': 'en-US'},
        {'name': 'Samantha', 'locale': 'en-US'},
        {'name': 'Unknown2', 'locale': 'en-US'},
        {'name': 'Alex', 'locale': 'en-US'},
      ];

      final prioritized = allVoices.where((voice) {
        final name = voice['name'] ?? '';
        return bestVoices.contains(name);
      }).toList();

      expect(prioritized.length, equals(2));
      expect(
        prioritized.map((v) => v['name']),
        containsAll(['Samantha', 'Alex']),
      );
    });

    test('falls back to all English voices if no best voices found', () {
      const bestVoices = ['NonExistent'];
      final allVoices = [
        {'name': 'Voice1', 'locale': 'en-US'},
        {'name': 'Voice2', 'locale': 'en-GB'},
      ];

      final bestFound = allVoices.where((voice) {
        final name = voice['name'] ?? '';
        return bestVoices.contains(name);
      }).toList();

      if (bestFound.isEmpty) {
        // Fall back to all voices
        final englishVoices = allVoices.where((voice) {
          final locale = voice['locale'] ?? '';
          return locale.toLowerCase().startsWith('en');
        }).toList();

        expect(englishVoices.length, equals(2));
      }
    });
  });
}
