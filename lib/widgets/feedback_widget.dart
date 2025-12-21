import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/tts_provider.dart';
import 'package:orthosense/widgets/audio_feedback_widget.dart';

/// Widget that displays feedback text with auto-play TTS capability.
///
/// Automatically plays new feedback when [feedbackText] changes.
/// Uses queue for multiple rapid feedbacks from backend.
class FeedbackWidget extends ConsumerStatefulWidget {
  const FeedbackWidget({
    required this.feedbackText,
    super.key,
    this.autoPlay = true,
    this.showVolumeSlider = true,
    this.compact = false,
  });

  /// Text feedback to display and optionally play.
  final String feedbackText;

  /// Whether to auto-play new feedback via TTS. Defaults to true.
  final bool autoPlay;

  /// Whether to show volume slider. Defaults to true.
  final bool showVolumeSlider;

  /// Compact mode shows only control buttons.
  final bool compact;

  @override
  ConsumerState<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends ConsumerState<FeedbackWidget> {
  String? _lastAutoPlayed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAutoPlay();
  }

  @override
  void didUpdateWidget(covariant FeedbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedbackText != widget.feedbackText) {
      _maybeAutoPlay();
    }
  }

  void _maybeAutoPlay() {
    if (!widget.autoPlay) return;

    final text = widget.feedbackText.trim();
    if (text.isEmpty) return;
    if (_lastAutoPlayed == text) return;

    _lastAutoPlayed = text;

    final audio = ref.read(ttsServiceProvider);
    if (audio.state.value.isMuted) return;

    // Why: backend may send feedback in bursts; queue gives natural playback.
    audio.enqueue(text);
  }

  @override
  Widget build(BuildContext context) {
    return AudioFeedbackWidget(
      text: widget.feedbackText,
      showVolumeSlider: widget.showVolumeSlider,
      compact: widget.compact,
    );
  }
}
