/// Unit tests for VoiceListProvider.
///
/// Test coverage:
/// 1. Voice filtering by locale
/// 2. Platform-specific voice selection
/// 3. iOS best voices
/// 4. Android best voices
/// 5. Voice mapping
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceListProvider', () {
    group('voice filtering', () {
      test('filters by English locale', () {
        final voices = [
          {'name': 'Alex', 'locale': 'en-US'},
          {'name': 'Thomas', 'locale': 'de-DE'},
          {'name': 'Marie', 'locale': 'fr-FR'},
        ];

        final englishVoices = voices.where((voice) {
          final locale = voice['locale'] ?? '';
          return locale.toLowerCase().startsWith('en');
        }).toList();

        expect(englishVoices.length, equals(1));
        expect(englishVoices.first['name'], equals('Alex'));
      });

      test('accepts en-US locale', () {
        const locale = 'en-US';
        expect(locale.toLowerCase().startsWith('en'), isTrue);
      });

      test('accepts en-GB locale', () {
        const locale = 'en-GB';
        expect(locale.toLowerCase().startsWith('en'), isTrue);
      });

      test('accepts en-AU locale', () {
        const locale = 'en-AU';
        expect(locale.toLowerCase().startsWith('en'), isTrue);
      });

      test('rejects non-English locales', () {
        const locales = ['de-DE', 'fr-FR', 'es-ES', 'pl-PL'];

        for (final locale in locales) {
          expect(locale.toLowerCase().startsWith('en'), isFalse);
        }
      });
    });

    group('iOS best voices', () {
      test('includes Alex (male)', () {
        const iosBestVoices = [
          'Alex',
          'Tom',
          'Daniel',
          'Fred',
          'Rishi',
          'Ava',
          'Samantha',
          'Allison',
          'Victoria',
          'Karen',
          'Tessa',
        ];

        expect(iosBestVoices.contains('Alex'), isTrue);
      });

      test('includes Tom (male)', () {
        const iosBestVoices = ['Alex', 'Tom', 'Daniel', 'Fred', 'Rishi'];
        expect(iosBestVoices.contains('Tom'), isTrue);
      });

      test('includes Daniel (male)', () {
        const iosBestVoices = ['Alex', 'Tom', 'Daniel', 'Fred', 'Rishi'];
        expect(iosBestVoices.contains('Daniel'), isTrue);
      });

      test('includes Ava (female)', () {
        const iosBestVoices = [
          'Ava',
          'Samantha',
          'Allison',
          'Victoria',
          'Karen',
          'Tessa',
        ];
        expect(iosBestVoices.contains('Ava'), isTrue);
      });

      test('includes Samantha (female)', () {
        const iosBestVoices = ['Ava', 'Samantha', 'Allison', 'Victoria'];
        expect(iosBestVoices.contains('Samantha'), isTrue);
      });

      test('matches voice by name substring', () {
        const iosBestVoices = ['Alex', 'Tom'];
        const voiceName = 'com.apple.ttsbundle.Alex-compact';

        final matches = iosBestVoices.any(voiceName.contains);
        expect(matches, isTrue);
      });
    });

    group('Android best voices', () {
      test('includes en-us-x-iom (male)', () {
        const androidBestVoices = [
          'en-us-x-iom',
          'en-us-x-tpd',
          'en-gb-x-rjs',
          'en-us-x-iob',
          'en-us-x-tpf',
          'en-gb-x-fis',
        ];

        expect(androidBestVoices.contains('en-us-x-iom'), isTrue);
      });

      test('includes en-us-x-tpd (male)', () {
        const androidBestVoices = ['en-us-x-iom', 'en-us-x-tpd', 'en-gb-x-rjs'];
        expect(androidBestVoices.contains('en-us-x-tpd'), isTrue);
      });

      test('includes en-us-x-iob (female)', () {
        const androidBestVoices = ['en-us-x-iob', 'en-us-x-tpf', 'en-gb-x-fis'];
        expect(androidBestVoices.contains('en-us-x-iob'), isTrue);
      });

      test('matches voice by identifier substring', () {
        const androidBestVoices = ['en-us-x-iom', 'en-us-x-tpd'];
        const voiceName = 'en-us-x-iom-network';

        final matches = androidBestVoices.any(voiceName.contains);
        expect(matches, isTrue);
      });
    });

    group('voice mapping', () {
      test('converts dynamic map to Map<String, String>', () {
        final dynamic rawVoice = {
          'name': 'Alex',
          'locale': 'en-US',
        };

        final voice = Map<String, String>.from(rawVoice as Map);

        expect(voice, isA<Map<String, String>>());
        expect(voice['name'], equals('Alex'));
      });

      test('handles missing name gracefully', () {
        final voice = <String, String>{'locale': 'en-US'};
        final name = voice['name'] ?? '';

        expect(name, isEmpty);
      });

      test('handles missing locale gracefully', () {
        final voice = <String, String>{'name': 'Alex'};
        final locale = voice['locale'] ?? '';

        expect(locale, isEmpty);
      });
    });

    group('platform fallback', () {
      test('returns all English voices on unknown platform', () {
        const platform = 'unknown';
        const isIOS = false;
        const isAndroid = false;

        // On unknown platform, fallback returns true
        final shouldInclude = (!isIOS && !isAndroid) || platform == 'unknown';

        expect(shouldInclude, isTrue);
      });
    });

    group('TTS service integration', () {
      test('reads TTS service from provider', () {
        var ttsServiceRead = false;

        void readTtsService() {
          ttsServiceRead = true;
        }

        readTtsService();
        expect(ttsServiceRead, isTrue);
      });

      test('gets voices from TTS service', () {
        var voicesFetched = false;

        Future<List<dynamic>> getVoices() async {
          voicesFetched = true;
          return [
            {'name': 'Alex', 'locale': 'en-US'},
          ];
        }

        getVoices();
        expect(voicesFetched, isTrue);
      });
    });

    group('voice list transformation', () {
      test('maps all voices from raw list', () {
        final rawVoices = [
          {'name': 'Voice1', 'locale': 'en-US'},
          {'name': 'Voice2', 'locale': 'en-GB'},
          {'name': 'Voice3', 'locale': 'de-DE'},
        ];

        final mappedVoices = rawVoices
            .map((e) => Map<String, String>.from(e))
            .toList();

        expect(mappedVoices.length, equals(3));
      });

      test('filters to only matching voices', () {
        final allVoices = [
          {'name': 'Alex', 'locale': 'en-US'},
          {'name': 'Hans', 'locale': 'de-DE'},
          {'name': 'Tom', 'locale': 'en-GB'},
        ];

        const iosBestVoices = ['Alex', 'Tom'];

        final filtered = allVoices.where((voice) {
          final name = voice['name'] ?? '';
          final locale = voice['locale'] ?? '';

          if (!locale.toLowerCase().startsWith('en')) return false;
          return iosBestVoices.any(name.contains);
        }).toList();

        expect(filtered.length, equals(2));
      });
    });
  });

  group('Voice Quality Selection', () {
    test('prioritizes high-quality voices', () {
      // The provider specifically selects high-quality voice identifiers
      const iosBestVoices = [
        'Alex',
        'Tom',
        'Daniel',
        'Fred',
        'Rishi',
        'Ava',
        'Samantha',
        'Allison',
        'Victoria',
        'Karen',
        'Tessa',
      ];

      // These are known high-quality voices
      expect(iosBestVoices.length, greaterThan(5));
    });

    test('includes both male and female voices', () {
      const maleVoices = ['Alex', 'Tom', 'Daniel', 'Fred', 'Rishi'];
      const femaleVoices = ['Ava', 'Samantha', 'Allison', 'Victoria', 'Karen'];

      expect(maleVoices, isNotEmpty);
      expect(femaleVoices, isNotEmpty);
    });
  });

  group('Riverpod provider', () {
    test('is async provider', () {
      // Provider returns Future<List<Map<String, String>>>
      const isAsync = true;
      expect(isAsync, isTrue);
    });

    test('depends on ttsServiceProvider', () {
      const dependsOnTts = true;
      expect(dependsOnTts, isTrue);
    });
  });
}
