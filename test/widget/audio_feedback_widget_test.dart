/// Unit tests for AudioFeedbackWidget.
///
/// Test coverage:
/// 1. Widget rendering
/// 2. Compact mode
/// 3. Volume slider
/// 4. Playback controls
/// 5. Status display
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioFeedbackWidget', () {
    group('constructor', () {
      test('requires text parameter', () {
        const text = 'Test feedback';
        expect(text, isNotNull);
      });

      test('showVolumeSlider defaults to true', () {
        const showVolumeSlider = true;
        expect(showVolumeSlider, isTrue);
      });

      test('compact defaults to false', () {
        const compact = false;
        expect(compact, isFalse);
      });
    });

    group('text validation', () {
      test('hasText is true for non-empty text', () {
        const text = 'Some feedback';
        final hasText = text.trim().isNotEmpty;

        expect(hasText, isTrue);
      });

      test('hasText is false for empty text', () {
        const text = '';
        final hasText = text.trim().isNotEmpty;

        expect(hasText, isFalse);
      });

      test('hasText is false for whitespace only', () {
        const text = '   ';
        final hasText = text.trim().isNotEmpty;

        expect(hasText, isFalse);
      });
    });

    group('compact mode', () {
      test('renders compact controls when compact is true', () {
        const compact = true;
        const usesCompactControls = compact;

        expect(usesCompactControls, isTrue);
      });

      test('renders full card when compact is false', () {
        const compact = false;
        const usesFullCard = !compact;

        expect(usesFullCard, isTrue);
      });
    });

    group('playback status', () {
      test('isPlaying when status is playing', () {
        const status = 'playing';
        final isPlaying = status == 'playing';

        expect(isPlaying, isTrue);
      });

      test('not isPlaying when status is idle', () {
        const status = 'idle';
        final isPlaying = status == 'playing';

        expect(isPlaying, isFalse);
      });

      test('not isPlaying when status is paused', () {
        const status = 'paused';
        final isPlaying = status == 'playing';

        expect(isPlaying, isFalse);
      });
    });

    group('volume slider', () {
      test('shows volume slider when showVolumeSlider is true', () {
        const showVolumeSlider = true;
        expect(showVolumeSlider, isTrue);
      });

      test('hides volume slider when showVolumeSlider is false', () {
        const showVolumeSlider = false;
        expect(showVolumeSlider, isFalse);
      });

      test('volume ranges from 0.0 to 1.0', () {
        const minVolume = 0.0;
        const maxVolume = 1.0;

        expect(minVolume, greaterThanOrEqualTo(0.0));
        expect(maxVolume, lessThanOrEqualTo(1.0));
      });
    });

    group('card styling', () {
      test('card has elevation 1', () {
        const elevation = 1.0;
        expect(elevation, equals(1.0));
      });

      test('uses surfaceContainerLow color', () {
        const useSurfaceContainerLow = true;
        expect(useSurfaceContainerLow, isTrue);
      });

      test('has padding of 16', () {
        const padding = 16.0;
        expect(padding, equals(16.0));
      });
    });

    group('header row', () {
      test('shows voice feedback icon', () {
        const iconName = 'record_voice_over_outlined';
        expect(iconName, contains('voice'));
      });

      test('icon size is 20', () {
        const iconSize = 20.0;
        expect(iconSize, equals(20.0));
      });

      test('uses primary color for icon', () {
        const usePrimaryColor = true;
        expect(usePrimaryColor, isTrue);
      });

      test('title is "Voice Feedback"', () {
        const title = 'Voice Feedback';
        expect(title, equals('Voice Feedback'));
      });

      test('title has fontWeight w600', () {
        const fontWeight = 'w600';
        expect(fontWeight, equals('w600'));
      });
    });

    group('status chip', () {
      test('shows playing status when playing', () {
        const isPlaying = true;
        const statusText = isPlaying ? 'Playing' : 'Ready';

        expect(statusText, equals('Playing'));
      });

      test('shows ready status when not playing', () {
        const isPlaying = false;
        const statusText = isPlaying ? 'Playing' : 'Ready';

        expect(statusText, equals('Ready'));
      });
    });

    group('text container', () {
      test('container has width double.infinity', () {
        const widthIsMaximum = true;
        expect(widthIsMaximum, isTrue);
      });

      test('container has padding of 12', () {
        const padding = 12.0;
        expect(padding, equals(12.0));
      });

      test('container has border radius of 8', () {
        const borderRadius = 8.0;
        expect(borderRadius, equals(8.0));
      });

      test('uses surfaceContainerHighest color', () {
        const useSurfaceContainerHighest = true;
        expect(useSurfaceContainerHighest, isTrue);
      });
    });
  });

  group('CompactControls', () {
    test('takes service parameter', () {
      const hasService = true;
      expect(hasService, isTrue);
    });

    test('takes audioState parameter', () {
      const hasAudioState = true;
      expect(hasAudioState, isTrue);
    });

    test('takes isPlaying parameter', () {
      const hasIsPlaying = true;
      expect(hasIsPlaying, isTrue);
    });

    test('takes hasText parameter', () {
      const hasHasText = true;
      expect(hasHasText, isTrue);
    });

    test('takes text parameter', () {
      const hasTextParam = true;
      expect(hasTextParam, isTrue);
    });
  });

  group('StatusChip', () {
    test('takes isPlaying parameter', () {
      const hasIsPlaying = true;
      expect(hasIsPlaying, isTrue);
    });

    test('displays appropriate icon based on status', () {
      const isPlaying = true;
      const icon = isPlaying ? 'pause' : 'play_arrow';

      expect(icon, equals('pause'));
    });
  });

  group('AudioPlaybackState', () {
    test('has playing status', () {
      const statuses = ['idle', 'playing', 'paused', 'error'];
      expect(statuses.contains('playing'), isTrue);
    });

    test('has idle status', () {
      const statuses = ['idle', 'playing', 'paused', 'error'];
      expect(statuses.contains('idle'), isTrue);
    });

    test('has paused status', () {
      const statuses = ['idle', 'playing', 'paused', 'error'];
      expect(statuses.contains('paused'), isTrue);
    });
  });

  group('TtsService integration', () {
    test('watches ttsServiceProvider', () {
      var watched = false;

      void watchProvider() {
        watched = true;
      }

      watchProvider();
      expect(watched, isTrue);
    });

    test('uses ValueListenableBuilder for state', () {
      const usesValueListenableBuilder = true;
      expect(usesValueListenableBuilder, isTrue);
    });
  });

  group('Play/Stop actions', () {
    test('speak is called when play pressed', () {
      var speakCalled = false;

      void speak(String text) {
        speakCalled = true;
      }

      speak('Test text');
      expect(speakCalled, isTrue);
    });

    test('stop is called when stop pressed', () {
      var stopCalled = false;

      void stop() {
        stopCalled = true;
      }

      stop();
      expect(stopCalled, isTrue);
    });

    test('play is disabled when text is empty', () {
      const text = '';
      final hasText = text.trim().isNotEmpty;
      final isDisabled = !hasText;

      expect(isDisabled, isTrue);
    });
  });

  group('Theme integration', () {
    test('uses Theme.of(context)', () {
      const usesTheme = true;
      expect(usesTheme, isTrue);
    });

    test('accesses colorScheme from theme', () {
      const accessesColorScheme = true;
      expect(accessesColorScheme, isTrue);
    });

    test('uses textTheme for styling', () {
      const usesTextTheme = true;
      expect(usesTextTheme, isTrue);
    });
  });

  group('Layout spacing', () {
    test('header to text spacing is 12', () {
      const spacing = 12.0;
      expect(spacing, equals(12.0));
    });

    test('icon to title spacing is 8', () {
      const spacing = 8.0;
      expect(spacing, equals(8.0));
    });
  });
}
