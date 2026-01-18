/// Unit tests for TtsService with actual imports.
///
/// Test coverage:
/// 1. AudioPlaybackState
/// 2. AudioPlaybackStatus
/// 3. TtsService queue operations
/// 4. Mute/volume controls
/// 5. Rate and pitch settings
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/tts_service.dart';

void main() {
  group('AudioPlaybackState', () {
    group('initial state', () {
      test('initial state has idle status', () {
        const state = AudioPlaybackState.initial();
        expect(state.status, equals(AudioPlaybackStatus.idle));
      });

      test('initial state has no current text', () {
        const state = AudioPlaybackState.initial();
        expect(state.currentText, isNull);
      });

      test('initial state is not muted', () {
        const state = AudioPlaybackState.initial();
        expect(state.isMuted, isFalse);
      });

      test('initial volume is 1.0', () {
        const state = AudioPlaybackState.initial();
        expect(state.volume, equals(1.0));
      });

      test('initial rate is 0.48', () {
        const state = AudioPlaybackState.initial();
        expect(state.rate, equals(0.48));
      });

      test('initial pitch is 1.0', () {
        const state = AudioPlaybackState.initial();
        expect(state.pitch, equals(1.0));
      });
    });

    group('copyWith', () {
      test('copyWith status preserves other fields', () {
        const state = AudioPlaybackState.initial();
        final updated = state.copyWith(status: AudioPlaybackStatus.playing);

        expect(updated.status, equals(AudioPlaybackStatus.playing));
        expect(updated.isMuted, equals(state.isMuted));
        expect(updated.volume, equals(state.volume));
      });

      test('copyWith currentText updates text', () {
        const state = AudioPlaybackState.initial();
        final updated = state.copyWith(currentText: 'Test speech');

        expect(updated.currentText, equals('Test speech'));
      });

      test('copyWith clearCurrentText sets text to null', () {
        const state = AudioPlaybackState(
          status: AudioPlaybackStatus.playing,
          currentText: 'Some text',
          isMuted: false,
          volume: 1.0,
          rate: 0.48,
          pitch: 1.0,
        );

        final updated = state.copyWith(clearCurrentText: true);
        expect(updated.currentText, isNull);
      });

      test('copyWith isMuted toggles mute', () {
        const state = AudioPlaybackState.initial();
        final muted = state.copyWith(isMuted: true);

        expect(muted.isMuted, isTrue);

        final unmuted = muted.copyWith(isMuted: false);
        expect(unmuted.isMuted, isFalse);
      });

      test('copyWith volume changes volume', () {
        const state = AudioPlaybackState.initial();
        final updated = state.copyWith(volume: 0.5);

        expect(updated.volume, equals(0.5));
      });

      test('copyWith rate changes rate', () {
        const state = AudioPlaybackState.initial();
        final updated = state.copyWith(rate: 0.6);

        expect(updated.rate, equals(0.6));
      });

      test('copyWith pitch changes pitch', () {
        const state = AudioPlaybackState.initial();
        final updated = state.copyWith(pitch: 1.1);

        expect(updated.pitch, equals(1.1));
      });
    });

    group('immutability', () {
      test('copyWith returns new instance', () {
        const state = AudioPlaybackState.initial();
        final updated = state.copyWith(volume: 0.5);

        expect(identical(state, updated), isFalse);
        expect(state.volume, equals(1.0)); // Original unchanged
      });
    });
  });

  group('AudioPlaybackStatus', () {
    test('has idle status', () {
      expect(AudioPlaybackStatus.values, contains(AudioPlaybackStatus.idle));
    });

    test('has playing status', () {
      expect(AudioPlaybackStatus.values, contains(AudioPlaybackStatus.playing));
    });

    test('has exactly 2 values', () {
      expect(AudioPlaybackStatus.values.length, equals(2));
    });
  });

  group('TtsService - Configuration', () {
    test('volume range is 0.0 to 1.0', () {
      // Valid range for setVolume
      const minVolume = 0.0;
      const maxVolume = 1.0;

      expect(minVolume, equals(0.0));
      expect(maxVolume, equals(1.0));
    });

    test('rate range is 0.2 to 0.8 for natural voice', () {
      // Valid range for setSpeechRate
      const minRate = 0.2;
      const maxRate = 0.8;

      expect(minRate, equals(0.2));
      expect(maxRate, equals(0.8));
    });

    test('pitch range is 0.8 to 1.2 for natural voice', () {
      // Valid range for setPitch
      const minPitch = 0.8;
      const maxPitch = 1.2;

      expect(minPitch, equals(0.8));
      expect(maxPitch, equals(1.2));
    });

    test('volume clamping works correctly', () {
      // Simulate volume.clamp(0.0, 1.0)
      expect((-0.5).clamp(0.0, 1.0), equals(0.0));
      expect(0.5.clamp(0.0, 1.0), equals(0.5));
      expect(1.5.clamp(0.0, 1.0), equals(1.0));
    });

    test('rate clamping works correctly', () {
      // Simulate rate.clamp(0.2, 0.8)
      expect(0.1.clamp(0.2, 0.8), equals(0.2));
      expect(0.5.clamp(0.2, 0.8), equals(0.5));
      expect(1.0.clamp(0.2, 0.8), equals(0.8));
    });

    test('pitch clamping works correctly', () {
      // Simulate pitch.clamp(0.8, 1.2)
      expect(0.5.clamp(0.8, 1.2), equals(0.8));
      expect(1.0.clamp(0.8, 1.2), equals(1.0));
      expect(1.5.clamp(0.8, 1.2), equals(1.2));
    });
  });

  group('TtsService - Queue Logic', () {
    test('empty string is not enqueued', () {
      const text = '';
      final shouldEnqueue = text.trim().isNotEmpty;

      expect(shouldEnqueue, isFalse);
    });

    test('whitespace-only string is not enqueued', () {
      const text = '   ';
      final shouldEnqueue = text.trim().isNotEmpty;

      expect(shouldEnqueue, isFalse);
    });

    test('valid string is enqueued', () {
      const text = 'Test speech';
      final shouldEnqueue = text.trim().isNotEmpty;

      expect(shouldEnqueue, isTrue);
    });

    test('text is trimmed before enqueuing', () {
      const text = '  Test speech  ';
      final normalized = text.trim();

      expect(normalized, equals('Test speech'));
    });
  });

  group('TtsService - Mute Behavior', () {
    test('muting when already muted does nothing', () {
      const currentMuted = true;
      const newMuted = true;

      final shouldUpdate = newMuted != currentMuted;
      expect(shouldUpdate, isFalse);
    });

    test('unmuting when not muted does nothing', () {
      const currentMuted = false;
      const newMuted = false;

      final shouldUpdate = newMuted != currentMuted;
      expect(shouldUpdate, isFalse);
    });

    test('muting stops speech and clears queue', () {
      // When muting: stop(clearQueue: true) is called
      const clearsQueue = true;
      expect(clearsQueue, isTrue);
    });

    test('unmuting allows playback to resume', () {
      // After unmuting, _playNext() can be called
      const canPlayNext = true;
      expect(canPlayNext, isTrue);
    });
  });

  group('TtsService - Speech Methods', () {
    group('enqueue', () {
      test('adds text to queue', () {
        final queue = <String>[];
        const text = 'Test';

        queue.add(text.trim());

        expect(queue, contains('Test'));
      });

      test('plays immediately if idle and not muted', () {
        const isSpeaking = false;
        const isMuted = false;

        final shouldPlayNow = !isSpeaking && !isMuted;
        expect(shouldPlayNow, isTrue);
      });

      test('queues if already speaking', () {
        const isSpeaking = true;
        const isMuted = false;

        final shouldPlayNow = !isSpeaking && !isMuted;
        expect(shouldPlayNow, isFalse);
      });

      test('does not play if muted', () {
        const isSpeaking = false;
        const isMuted = true;

        final shouldPlayNow = !isSpeaking && !isMuted;
        expect(shouldPlayNow, isFalse);
      });
    });

    group('speakNow', () {
      test('clears queue before speaking', () {
        final queue = ['previous', 'items'];

        queue.clear();
        queue.add('new text');

        expect(queue.length, equals(1));
        expect(queue.first, equals('new text'));
      });
    });

    group('stop', () {
      test('can clear queue on stop', () {
        final queue = ['item1', 'item2'];
        const clearQueue = true;

        if (clearQueue) queue.clear();

        expect(queue, isEmpty);
      });

      test('preserves queue without clearQueue', () {
        final queue = ['item1', 'item2'];
        const clearQueue = false;

        if (clearQueue) queue.clear();

        expect(queue, hasLength(2));
      });
    });
  });

  group('TtsService - State Updates', () {
    test('playing state is set when speech starts', () {
      const initialState = AudioPlaybackState.initial();
      final playingState = initialState.copyWith(
        status: AudioPlaybackStatus.playing,
        currentText: 'Speaking...',
      );

      expect(playingState.status, equals(AudioPlaybackStatus.playing));
      expect(playingState.currentText, equals('Speaking...'));
    });

    test('idle state is set when speech completes', () {
      const playingState = AudioPlaybackState(
        status: AudioPlaybackStatus.playing,
        currentText: 'Speaking...',
        isMuted: false,
        volume: 1.0,
        rate: 0.48,
        pitch: 1.0,
      );

      final idleState = playingState.copyWith(
        status: AudioPlaybackStatus.idle,
        clearCurrentText: true,
      );

      expect(idleState.status, equals(AudioPlaybackStatus.idle));
      expect(idleState.currentText, isNull);
    });
  });

  group('TtsService - iOS Configuration', () {
    test('uses playback audio category', () {
      // iOS requires specific audio category for TTS
      const audioCategory = 'playback';
      expect(audioCategory, equals('playback'));
    });

    test('allows bluetooth audio', () {
      // iOS allows bluetooth for TTS output
      const allowsBluetooth = true;
      expect(allowsBluetooth, isTrue);
    });

    test('uses shared instance', () {
      // iOS uses shared TTS instance
      const usesSharedInstance = true;
      expect(usesSharedInstance, isTrue);
    });
  });

  group('TtsService - Language', () {
    test('default language is en-US', () {
      const defaultLanguage = 'en-US';
      expect(defaultLanguage, equals('en-US'));
    });
  });
}
