import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/tts_provider.dart';
import 'package:orthosense/core/services/tts_service.dart';

/// Widget displaying audio feedback controls with playback status.
class AudioFeedbackWidget extends ConsumerWidget {
  const AudioFeedbackWidget({
    required this.text,
    super.key,
    this.showVolumeSlider = true,
    this.compact = false,
  });

  final String text;
  final bool showVolumeSlider;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(ttsServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<AudioPlaybackState>(
      valueListenable: service.state,
      builder: (context, audioState, _) {
        final isPlaying = audioState.status == AudioPlaybackStatus.playing;
        final hasText = text.trim().isNotEmpty;

        if (compact) {
          return _CompactControls(
            service: service,
            audioState: audioState,
            isPlaying: isPlaying,
            hasText: hasText,
            text: text,
          );
        }

        return Card(
          elevation: 1,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.record_voice_over_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voice Feedback',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _StatusChip(isPlaying: isPlaying),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasText ? text : 'No feedback available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasText
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MuteButton(service: service, audioState: audioState),
                    const SizedBox(width: 4),
                    _PlayStopButton(
                      service: service,
                      isPlaying: isPlaying,
                      hasText: hasText,
                      text: text,
                    ),
                    if (showVolumeSlider) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VolumeSlider(
                          service: service,
                          audioState: audioState,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactControls extends StatelessWidget {
  const _CompactControls({
    required this.service,
    required this.audioState,
    required this.isPlaying,
    required this.hasText,
    required this.text,
  });

  final TtsService service;
  final AudioPlaybackState audioState;
  final bool isPlaying;
  final bool hasText;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MuteButton(service: service, audioState: audioState),
        _PlayStopButton(
          service: service,
          isPlaying: isPlaying,
          hasText: hasText,
          text: text,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPlaying
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPlaying) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            isPlaying ? 'Playing' : 'Idle',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPlaying
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuteButton extends StatelessWidget {
  const _MuteButton({
    required this.service,
    required this.audioState,
  });

  final TtsService service;
  final AudioPlaybackState audioState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: audioState.isMuted ? 'Unmute' : 'Mute',
      onPressed: () => service.setMuted(muted: !audioState.isMuted),
      icon: Icon(
        audioState.isMuted
            ? Icons.volume_off_outlined
            : Icons.volume_up_outlined,
        color: audioState.isMuted ? colorScheme.error : colorScheme.onSurface,
      ),
    );
  }
}

class _PlayStopButton extends StatelessWidget {
  const _PlayStopButton({
    required this.service,
    required this.isPlaying,
    required this.hasText,
    required this.text,
  });

  final TtsService service;
  final bool isPlaying;
  final bool hasText;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: isPlaying ? 'Stop' : 'Play',
      onPressed: hasText
          ? () async {
              if (isPlaying) {
                await service.stop();
              } else {
                await service.enqueue(text);
              }
            }
          : null,
      icon: Icon(
        isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
        color: hasText
            ? colorScheme.primary
            : colorScheme.onSurface.withAlpha(97),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.service,
    required this.audioState,
  });

  final TtsService service;
  final AudioPlaybackState audioState;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.volume_down_outlined, size: 18),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: audioState.volume,
              onChanged: audioState.isMuted ? null : service.setVolume,
            ),
          ),
        ),
        const Icon(Icons.volume_up_outlined, size: 18),
      ],
    );
  }
}
