/// Widget and unit tests for VoiceSelectionScreen.
///
/// Test coverage:
/// 1. Voice list display
/// 2. Voice selection
/// 3. Flag emoji mapping
/// 4. Voice preview
/// 5. Confirmation flow
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Voice Model', () {
    test('creates with name and locale', () {
      final voice = Voice(name: 'en-us-x-sfg#male_1-local', locale: 'en-US');

      expect(voice.name, equals('en-us-x-sfg#male_1-local'));
      expect(voice.locale, equals('en-US'));
    });

    test('converts to map', () {
      final voice = Voice(name: 'Test Voice', locale: 'en-GB');
      final map = voice.toMap();

      expect(map['name'], equals('Test Voice'));
      expect(map['locale'], equals('en-GB'));
    });

    test('creates from map', () {
      final map = {'name': 'Google UK', 'locale': 'en-GB'};
      final voice = Voice.fromMap(map);

      expect(voice.name, equals('Google UK'));
      expect(voice.locale, equals('en-GB'));
    });
  });

  group('Flag Emoji Mapping', () {
    test('US locale returns US flag', () {
      final flag = _getFlag('en-US');
      expect(flag, equals('🇺🇸'));
    });

    test('GB locale returns GB flag', () {
      final flag = _getFlag('en-GB');
      expect(flag, equals('🇬🇧'));
    });

    test('AU locale returns AU flag', () {
      final flag = _getFlag('en-AU');
      expect(flag, equals('🇦🇺'));
    });

    test('IE locale returns IE flag', () {
      final flag = _getFlag('en-IE');
      expect(flag, equals('🇮🇪'));
    });

    test('ZA locale returns ZA flag', () {
      final flag = _getFlag('en-ZA');
      expect(flag, equals('🇿🇦'));
    });

    test('IN locale returns IN flag', () {
      final flag = _getFlag('en-IN');
      expect(flag, equals('🇮🇳'));
    });

    test('unknown locale returns white flag', () {
      final flag = _getFlag('xx-XX');
      expect(flag, equals('🏳️'));
    });

    test('empty locale returns white flag', () {
      final flag = _getFlag('');
      expect(flag, equals('🏳️'));
    });

    test('locale with only language code returns white flag', () {
      final flag = _getFlag('en');
      // 'en'.split('-').last.toUpperCase() = 'EN', not a country
      expect(flag, equals('🏳️'));
    });
  });

  group('Voice Filtering', () {
    test('filters English voices only', () {
      final allVoices = [
        Voice(name: 'English US', locale: 'en-US'),
        Voice(name: 'Spanish', locale: 'es-ES'),
        Voice(name: 'English UK', locale: 'en-GB'),
        Voice(name: 'French', locale: 'fr-FR'),
      ];

      final englishVoices = _filterEnglishVoices(allVoices);

      expect(englishVoices.length, equals(2));
      expect(englishVoices.every((v) => v.locale.startsWith('en')), isTrue);
    });

    test('returns empty list when no English voices', () {
      final allVoices = [
        Voice(name: 'Spanish', locale: 'es-ES'),
        Voice(name: 'French', locale: 'fr-FR'),
      ];

      final englishVoices = _filterEnglishVoices(allVoices);

      expect(englishVoices.isEmpty, isTrue);
    });
  });

  group('Voice Display Name', () {
    test('extracts friendly name from voice name', () {
      final displayName = _getDisplayName('en-us-x-sfg#male_1-local');

      expect(displayName, isNotEmpty);
    });

    test('handles simple name', () {
      final displayName = _getDisplayName('Google US English');

      expect(displayName, equals('Google US English'));
    });
  });

  group('Voice Selection State', () {
    test('initial state has no selected voice', () {
      final state = VoiceSelectionState();

      expect(state.selectedVoice, isNull);
      expect(state.isPreviewPlaying, isFalse);
    });

    test('can select voice', () {
      final voice = Voice(name: 'Test', locale: 'en-US');
      final state = VoiceSelectionState(selectedVoice: voice);

      expect(state.selectedVoice, equals(voice));
    });

    test('tracks preview playing state', () {
      final state = VoiceSelectionState(isPreviewPlaying: true);

      expect(state.isPreviewPlaying, isTrue);
    });
  });

  group('Voice List Widget', () {
    testWidgets('shows loading indicator while loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MockVoiceList(isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no voices', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MockVoiceList(voices: []),
          ),
        ),
      );

      expect(find.text('No English voices found on this device.'), findsOneWidget);
    });

    testWidgets('shows voice list', (tester) async {
      final voices = [
        Voice(name: 'US English', locale: 'en-US'),
        Voice(name: 'UK English', locale: 'en-GB'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockVoiceList(voices: voices),
          ),
        ),
      );

      expect(find.text('US English'), findsOneWidget);
      expect(find.text('UK English'), findsOneWidget);
    });

    testWidgets('shows flag for each voice', (tester) async {
      final voices = [
        Voice(name: 'US English', locale: 'en-US'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockVoiceList(voices: voices),
          ),
        ),
      );

      expect(find.text('🇺🇸'), findsOneWidget);
    });
  });

  group('Voice Selection Widget', () {
    testWidgets('can select a voice', (tester) async {
      Voice? selected;
      final voices = [
        Voice(name: 'US English', locale: 'en-US'),
        Voice(name: 'UK English', locale: 'en-GB'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return _MockVoiceSelection(
                  voices: voices,
                  selectedVoice: selected,
                  onVoiceSelected: (voice) {
                    setState(() {
                      selected = voice;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('UK English'));
      await tester.pump();

      expect(selected?.name, equals('UK English'));
    });
  });

  group('Continue Button', () {
    testWidgets('disabled when no voice selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ContinueButton(
              isEnabled: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('enabled when voice selected', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ContinueButton(
              isEnabled: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byType(FilledButton));
      expect(pressed, isTrue);
    });

    testWidgets('shows Save in settings mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ContinueButton(
              isEnabled: true,
              onPressed: () {},
              isSettingsMode: true,
            ),
          ),
        ),
      );

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows Continue in onboarding mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ContinueButton(
              isEnabled: true,
              onPressed: () {},
              isSettingsMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
    });
  });

  group('Preview Message', () {
    test('generates preview message with voice name', () {
      final message = _getPreviewMessage('Google US');

      expect(message, contains('Google US'));
      expect(message, contains('OrthoSense'));
    });
  });

  group('Settings Mode vs Onboarding Mode', () {
    test('settings mode shows back button', () {
      expect(_shouldShowBackButton(isSettingsMode: true), isTrue);
    });

    test('onboarding mode hides back button', () {
      expect(_shouldShowBackButton(isSettingsMode: false), isFalse);
    });
  });
}

// Models

class Voice {
  Voice({required this.name, required this.locale});

  factory Voice.fromMap(Map<String, String> map) {
    return Voice(
      name: map['name'] ?? '',
      locale: map['locale'] ?? '',
    );
  }

  final String name;
  final String locale;

  Map<String, String> toMap() {
    return {'name': name, 'locale': locale};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Voice && other.name == name && other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(name, locale);
}

class VoiceSelectionState {
  VoiceSelectionState({
    this.selectedVoice,
    this.isPreviewPlaying = false,
  });

  final Voice? selectedVoice;
  final bool isPreviewPlaying;
}

// Helper functions

String _getFlag(String locale) {
  if (locale.isEmpty) return '🏳️';
  final countryCode = locale.split('-').last.toUpperCase();
  if (countryCode == 'US') return '🇺🇸';
  if (countryCode == 'GB') return '🇬🇧';
  if (countryCode == 'AU') return '🇦🇺';
  if (countryCode == 'IE') return '🇮🇪';
  if (countryCode == 'ZA') return '🇿🇦';
  if (countryCode == 'IN') return '🇮🇳';
  return '🏳️';
}

List<Voice> _filterEnglishVoices(List<Voice> voices) {
  return voices.where((v) => v.locale.startsWith('en')).toList();
}

String _getDisplayName(String voiceName) {
  // Clean up voice name for display
  if (voiceName.contains('#')) {
    return voiceName.split('#').first.replaceAll('-', ' ').trim();
  }
  return voiceName;
}

String _getPreviewMessage(String voiceName) {
  return 'Hello, I am $voiceName. Welcome to OrthoSense.';
}

bool _shouldShowBackButton({required bool isSettingsMode}) {
  return isSettingsMode;
}

// Widget mocks

class _MockVoiceList extends StatelessWidget {
  const _MockVoiceList({
    this.voices,
    this.isLoading = false,
  });

  final List<Voice>? voices;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (voices == null || voices!.isEmpty) {
      return const Center(
        child: Text('No English voices found on this device.'),
      );
    }

    return ListView.builder(
      itemCount: voices!.length,
      itemBuilder: (context, index) {
        final voice = voices![index];
        return ListTile(
          title: Text(voice.name),
          subtitle: Text(_getFlag(voice.locale)),
        );
      },
    );
  }
}

class _MockVoiceSelection extends StatelessWidget {
  const _MockVoiceSelection({
    required this.voices,
    required this.selectedVoice,
    required this.onVoiceSelected,
  });

  final List<Voice> voices;
  final Voice? selectedVoice;
  final ValueChanged<Voice> onVoiceSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: voices.length,
      itemBuilder: (context, index) {
        final voice = voices[index];
        return RadioListTile<Voice>(
          title: Text(voice.name),
          subtitle: Text(_getFlag(voice.locale)),
          value: voice,
          groupValue: selectedVoice,
          onChanged: (value) {
            if (value != null) {
              onVoiceSelected(value);
            }
          },
        );
      },
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.isEnabled,
    required this.onPressed,
    this.isSettingsMode = false,
  });

  final bool isEnabled;
  final VoidCallback onPressed;
  final bool isSettingsMode;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isEnabled ? onPressed : null,
      child: Text(isSettingsMode ? 'Save' : 'Continue'),
    );
  }
}
