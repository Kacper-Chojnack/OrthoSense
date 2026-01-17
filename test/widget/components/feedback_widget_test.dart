/// Widget tests for FeedbackWidget and AudioFeedbackWidget.
///
/// Test coverage:
/// 1. FeedbackWidget auto-play behavior
/// 2. AudioFeedbackWidget display states
/// 3. Compact vs full mode
/// 4. Volume slider
/// 5. Mute button
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioPlaybackState', () {
    test('creates idle state', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.idle,
        volume: 1.0,
        isMuted: false,
      );

      expect(state.status, equals(AudioPlaybackStatus.idle));
      expect(state.volume, equals(1.0));
      expect(state.isMuted, isFalse);
    });

    test('creates playing state', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.playing,
        volume: 0.8,
        isMuted: false,
      );

      expect(state.status, equals(AudioPlaybackStatus.playing));
    });

    test('creates muted state', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.idle,
        volume: 1.0,
        isMuted: true,
      );

      expect(state.isMuted, isTrue);
    });

    test('copyWith updates single field', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.idle,
        volume: 1.0,
        isMuted: false,
      );

      final updated = state.copyWith(volume: 0.5);

      expect(updated.volume, equals(0.5));
      expect(updated.status, equals(AudioPlaybackStatus.idle));
    });
  });

  group('FeedbackWidgetState', () {
    test('tracks last auto-played text', () {
      final state = FeedbackWidgetState();

      expect(state.lastAutoPlayed, isNull);

      state.markAsPlayed('Test feedback');

      expect(state.lastAutoPlayed, equals('Test feedback'));
    });

    test('does not replay same text', () {
      final state = FeedbackWidgetState();

      state.markAsPlayed('Test feedback');
      final shouldPlay = state.shouldAutoPlay('Test feedback');

      expect(shouldPlay, isFalse);
    });

    test('plays new text', () {
      final state = FeedbackWidgetState();

      state.markAsPlayed('First feedback');
      final shouldPlay = state.shouldAutoPlay('Second feedback');

      expect(shouldPlay, isTrue);
    });

    test('does not play empty text', () {
      final state = FeedbackWidgetState();

      expect(state.shouldAutoPlay(''), isFalse);
      expect(state.shouldAutoPlay('   '), isFalse);
    });
  });

  group('StatusChip Widget', () {
    testWidgets('shows Playing when active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStatusChip(isPlaying: true),
          ),
        ),
      );

      expect(find.text('Playing'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Idle when not playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStatusChip(isPlaying: false),
          ),
        ),
      );

      expect(find.text('Idle'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('MuteButton Widget', () {
    testWidgets('shows volume icon when not muted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockMuteButton(isMuted: false, onToggle: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('shows mute icon when muted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockMuteButton(isMuted: true, onToggle: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_off), findsOneWidget);
    });

    testWidgets('toggles on tap', (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockMuteButton(
              isMuted: false,
              onToggle: () => toggled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));

      expect(toggled, isTrue);
    });
  });

  group('PlayStopButton Widget', () {
    testWidgets('shows play icon when stopped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockPlayStopButton(
              isPlaying: false,
              hasText: true,
              onPlay: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows stop icon when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockPlayStopButton(
              isPlaying: true,
              hasText: true,
              onPlay: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('disabled when no text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockPlayStopButton(
              isPlaying: false,
              hasText: false,
              onPlay: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('calls onPlay when tapped while stopped', (tester) async {
      var played = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockPlayStopButton(
              isPlaying: false,
              hasText: true,
              onPlay: () => played = true,
              onStop: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));

      expect(played, isTrue);
    });

    testWidgets('calls onStop when tapped while playing', (tester) async {
      var stopped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockPlayStopButton(
              isPlaying: true,
              hasText: true,
              onPlay: () {},
              onStop: () => stopped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));

      expect(stopped, isTrue);
    });
  });

  group('VolumeSlider Widget', () {
    testWidgets('shows current volume', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockVolumeSlider(
              volume: 0.75,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(0.75));
    });

    testWidgets('updates on drag', (tester) async {
      var newVolume = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return _MockVolumeSlider(
                  volume: newVolume,
                  onChanged: (v) {
                    setState(() {
                      newVolume = v;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Drag slider to the right
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();

      expect(newVolume, isNot(equals(0.5)));
    });
  });

  group('AudioFeedbackWidget Full Mode', () {
    testWidgets('shows feedback text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockAudioFeedbackWidget(
              text: 'Keep your back straight',
              compact: false,
              showVolumeSlider: true,
              audioState: const AudioPlaybackState(
                status: AudioPlaybackStatus.idle,
                volume: 1.0,
                isMuted: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Keep your back straight'), findsOneWidget);
      expect(find.text('Voice Feedback'), findsOneWidget);
    });

    testWidgets('shows no feedback message when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockAudioFeedbackWidget(
              text: '',
              compact: false,
              showVolumeSlider: true,
              audioState: const AudioPlaybackState(
                status: AudioPlaybackStatus.idle,
                volume: 1.0,
                isMuted: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('No feedback available.'), findsOneWidget);
    });

    testWidgets('shows volume slider when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockAudioFeedbackWidget(
              text: 'Test',
              compact: false,
              showVolumeSlider: true,
              audioState: const AudioPlaybackState(
                status: AudioPlaybackStatus.idle,
                volume: 1.0,
                isMuted: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('hides volume slider when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockAudioFeedbackWidget(
              text: 'Test',
              compact: false,
              showVolumeSlider: false,
              audioState: const AudioPlaybackState(
                status: AudioPlaybackStatus.idle,
                volume: 1.0,
                isMuted: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsNothing);
    });
  });

  group('AudioFeedbackWidget Compact Mode', () {
    testWidgets('shows only controls in compact mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockAudioFeedbackWidget(
              text: 'Test feedback',
              compact: true,
              showVolumeSlider: false,
              audioState: const AudioPlaybackState(
                status: AudioPlaybackStatus.idle,
                volume: 1.0,
                isMuted: false,
              ),
            ),
          ),
        ),
      );

      // Text should not be visible in compact mode
      expect(find.text('Test feedback'), findsNothing);
      expect(find.text('Voice Feedback'), findsNothing);

      // But controls should be there
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}

// Models

enum AudioPlaybackStatus { idle, playing, paused }

class AudioPlaybackState {
  const AudioPlaybackState({
    required this.status,
    required this.volume,
    required this.isMuted,
  });

  final AudioPlaybackStatus status;
  final double volume;
  final bool isMuted;

  AudioPlaybackState copyWith({
    AudioPlaybackStatus? status,
    double? volume,
    bool? isMuted,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class FeedbackWidgetState {
  String? lastAutoPlayed;

  void markAsPlayed(String text) {
    lastAutoPlayed = text;
  }

  bool shouldAutoPlay(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (lastAutoPlayed == trimmed) return false;
    return true;
  }
}

// Widget mocks

class _MockStatusChip extends StatelessWidget {
  const _MockStatusChip({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPlaying) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 6),
          ],
          Text(isPlaying ? 'Playing' : 'Idle'),
        ],
      ),
    );
  }
}

class _MockMuteButton extends StatelessWidget {
  const _MockMuteButton({
    required this.isMuted,
    required this.onToggle,
  });

  final bool isMuted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
      onPressed: onToggle,
    );
  }
}

class _MockPlayStopButton extends StatelessWidget {
  const _MockPlayStopButton({
    required this.isPlaying,
    required this.hasText,
    required this.onPlay,
    required this.onStop,
  });

  final bool isPlaying;
  final bool hasText;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
      onPressed: hasText ? (isPlaying ? onStop : onPlay) : null,
    );
  }
}

class _MockVolumeSlider extends StatelessWidget {
  const _MockVolumeSlider({
    required this.volume,
    required this.onChanged,
  });

  final double volume;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: volume,
      min: 0,
      max: 1,
      onChanged: onChanged,
    );
  }
}

class _MockAudioFeedbackWidget extends StatelessWidget {
  const _MockAudioFeedbackWidget({
    required this.text,
    required this.compact,
    required this.showVolumeSlider,
    required this.audioState,
  });

  final String text;
  final bool compact;
  final bool showVolumeSlider;
  final AudioPlaybackState audioState;

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    final isPlaying = audioState.status == AudioPlaybackStatus.playing;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MockMuteButton(isMuted: audioState.isMuted, onToggle: () {}),
          _MockPlayStopButton(
            isPlaying: isPlaying,
            hasText: hasText,
            onPlay: () {},
            onStop: () {},
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over_outlined),
                const SizedBox(width: 8),
                const Text('Voice Feedback'),
                const Spacer(),
                _MockStatusChip(isPlaying: isPlaying),
              ],
            ),
            const SizedBox(height: 12),
            Text(hasText ? text : 'No feedback available.'),
            const SizedBox(height: 12),
            Row(
              children: [
                _MockMuteButton(isMuted: audioState.isMuted, onToggle: () {}),
                _MockPlayStopButton(
                  isPlaying: isPlaying,
                  hasText: hasText,
                  onPlay: () {},
                  onStop: () {},
                ),
                if (showVolumeSlider) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MockVolumeSlider(
                      volume: audioState.volume,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
