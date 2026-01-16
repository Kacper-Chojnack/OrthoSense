/// Unit tests for TTS (Text-to-Speech) Service.
///
/// Test coverage:
/// 1. AudioPlaybackState immutability
/// 2. AudioPlaybackState copyWith
/// 3. Service initialization
/// 4. Queue operations
/// 5. State changes
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/tts_service.dart';

void main() {
  // Required for FlutterTts which uses platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioPlaybackState', () {
    test('initial state has correct default values', () {
      const state = AudioPlaybackState.initial();

      expect(state.status, equals(AudioPlaybackStatus.idle));
      expect(state.currentText, isNull);
      expect(state.isMuted, isFalse);
      expect(state.volume, equals(1.0));
      expect(state.rate, equals(0.48));
      expect(state.pitch, equals(1.0));
    });

    test('copyWith updates status', () {
      const original = AudioPlaybackState.initial();

      final updated = original.copyWith(status: AudioPlaybackStatus.playing);

      expect(updated.status, equals(AudioPlaybackStatus.playing));
      expect(updated.currentText, isNull);
      expect(updated.isMuted, isFalse);
    });

    test('copyWith updates currentText', () {
      const original = AudioPlaybackState.initial();

      final updated = original.copyWith(currentText: 'Hello world');

      expect(updated.currentText, equals('Hello world'));
      expect(updated.status, equals(AudioPlaybackStatus.idle));
    });

    test('copyWith clears currentText', () {
      const original = AudioPlaybackState(
        status: AudioPlaybackStatus.playing,
        currentText: 'Speaking now',
        isMuted: false,
        volume: 1.0,
        rate: 0.5,
        pitch: 1.0,
      );

      final updated = original.copyWith(clearCurrentText: true);

      expect(updated.currentText, isNull);
      expect(updated.status, equals(AudioPlaybackStatus.playing));
    });

    test('copyWith updates isMuted', () {
      const original = AudioPlaybackState.initial();

      final updated = original.copyWith(isMuted: true);

      expect(updated.isMuted, isTrue);
    });

    test('copyWith updates volume', () {
      const original = AudioPlaybackState.initial();

      final updated = original.copyWith(volume: 0.5);

      expect(updated.volume, equals(0.5));
    });

    test('copyWith updates rate', () {
      const original = AudioPlaybackState.initial();

      final updated = original.copyWith(rate: 0.75);

      expect(updated.rate, equals(0.75));
    });

    test('copyWith updates pitch', () {
      const original = AudioPlaybackState.initial();

      final updated = original.copyWith(pitch: 1.5);

      expect(updated.pitch, equals(1.5));
    });

    test('copyWith can update multiple fields', () {
      const original = AudioPlaybackState.initial();

      final updated = original.copyWith(
        status: AudioPlaybackStatus.playing,
        currentText: 'Testing',
        volume: 0.8,
        rate: 0.6,
      );

      expect(updated.status, equals(AudioPlaybackStatus.playing));
      expect(updated.currentText, equals('Testing'));
      expect(updated.volume, equals(0.8));
      expect(updated.rate, equals(0.6));
      expect(updated.pitch, equals(1.0)); // Unchanged
    });
  });

  group('AudioPlaybackStatus', () {
    test('has idle status', () {
      expect(AudioPlaybackStatus.idle, isNotNull);
    });

    test('has playing status', () {
      expect(AudioPlaybackStatus.playing, isNotNull);
    });

    test('all statuses are available', () {
      expect(AudioPlaybackStatus.values.length, equals(2));
    });
  });

  group('TtsService', () {
    late TtsService ttsService;

    setUpAll(() {
      // Mock the flutter_tts platform channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'awaitSpeakCompletion':
            case 'setVolume':
            case 'setSpeechRate':
            case 'setPitch':
            case 'setLanguage':
            case 'stop':
            case 'speak':
              return 1;
            case 'isLanguageAvailable':
              return 1;
            case 'getLanguages':
              return ['en-US'];
            case 'getVoices':
              return [];
            default:
              return null;
          }
        },
      );
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      );
    });

    setUp(() {
      ttsService = TtsService();
    });

    tearDown(() {
      ttsService.dispose();
    });

    test('service creates with initial state', () {
      expect(ttsService.state.value.status, equals(AudioPlaybackStatus.idle));
      expect(ttsService.state.value.isMuted, isFalse);
    });

    test('state notifier can be listened to', () {
      final states = <AudioPlaybackState>[];
      ttsService.state.addListener(() {
        states.add(ttsService.state.value);
      });

      // Manually trigger state change for test
      ttsService.state.value = ttsService.state.value.copyWith(isMuted: true);

      expect(states.last.isMuted, isTrue);
    });
  });

  group('TtsService State Management', () {
    late TtsService ttsService;

    setUpAll(() {
      // Mock the flutter_tts platform channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'awaitSpeakCompletion':
            case 'setVolume':
            case 'setSpeechRate':
            case 'setPitch':
            case 'setLanguage':
            case 'stop':
            case 'speak':
              return 1;
            case 'isLanguageAvailable':
              return 1;
            case 'getLanguages':
              return ['en-US'];
            case 'getVoices':
              return [];
            default:
              return null;
          }
        },
      );
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      );
    });

    setUp(() {
      ttsService = TtsService();
    });

    tearDown(() {
      ttsService.dispose();
    });

    test('state transitions from idle to muted', () {
      expect(ttsService.state.value.isMuted, isFalse);

      ttsService.state.value = ttsService.state.value.copyWith(isMuted: true);

      expect(ttsService.state.value.isMuted, isTrue);
    });

    test('volume can be adjusted', () {
      expect(ttsService.state.value.volume, equals(1.0));

      ttsService.state.value = ttsService.state.value.copyWith(volume: 0.5);

      expect(ttsService.state.value.volume, equals(0.5));
    });

    test('rate can be adjusted', () {
      final initialRate = ttsService.state.value.rate;

      ttsService.state.value = ttsService.state.value.copyWith(rate: 0.8);

      expect(ttsService.state.value.rate, equals(0.8));
      expect(ttsService.state.value.rate, isNot(equals(initialRate)));
    });
  });
}
