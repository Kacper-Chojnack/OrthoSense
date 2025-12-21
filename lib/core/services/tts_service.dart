import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Playback status for audio feedback.
enum AudioPlaybackStatus { idle, playing }

/// Immutable state representing current audio playback configuration.
@immutable
class AudioPlaybackState {
  const AudioPlaybackState({
    required this.status,
    required this.currentText,
    required this.isMuted,
    required this.volume,
    required this.rate,
    required this.pitch,
  });

  const AudioPlaybackState.initial()
    : status = AudioPlaybackStatus.idle,
      currentText = null,
      isMuted = false,
      volume = 1.0,
      rate = 0.48,
      pitch = 1.0;

  final AudioPlaybackStatus status;
  final String? currentText;
  final bool isMuted;
  final double volume;
  final double rate;
  final double pitch;

  AudioPlaybackState copyWith({
    AudioPlaybackStatus? status,
    String? currentText,
    bool clearCurrentText = false,
    bool? isMuted,
    double? volume,
    double? rate,
    double? pitch,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      currentText: clearCurrentText ? null : (currentText ?? this.currentText),
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
    );
  }
}

/// TTS service with queue support, mute/volume controls, and playback state.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  final Queue<String> _queue = Queue<String>();

  /// Observable playback state for UI binding.
  final ValueNotifier<AudioPlaybackState> state = ValueNotifier(
    const AudioPlaybackState.initial(),
  );

  bool _initialized = false;
  bool _isSpeaking = false;

  /// Initialize TTS engine. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
      );
    }

    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');

    await _applyVoiceParams(
      volume: state.value.volume,
      rate: state.value.rate,
      pitch: state.value.pitch,
    );

    _tts.setStartHandler(() {
      _isSpeaking = true;
      state.value = state.value.copyWith(status: AudioPlaybackStatus.playing);
    });

    void onDone() {
      _isSpeaking = false;
      state.value = state.value.copyWith(
        status: AudioPlaybackStatus.idle,
        clearCurrentText: true,
      );
      unawaited(_playNext());
    }

    _tts.setCompletionHandler(onDone);
    _tts.setCancelHandler(onDone);
    _tts.setErrorHandler((_) => onDone());
  }

  /// Add text to queue. Plays immediately if idle and not muted.
  Future<void> enqueue(String text) async {
    await init();
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    _queue.addLast(normalized);

    if (!_isSpeaking && !state.value.isMuted) {
      await _playNext();
    }
  }

  /// Stop current speech, clear queue, and speak immediately.
  Future<void> speakNow(String text) async {
    await init();
    await stop(clearQueue: true);
    await enqueue(text);
  }

  /// Speak text (legacy method, uses queue internally).
  Future<void> speak(String text) async {
    await enqueue(text);
  }

  /// Stop current speech and optionally clear pending queue.
  Future<void> stop({bool clearQueue = false}) async {
    await init();
    if (clearQueue) _queue.clear();
    await _tts.stop();
    _isSpeaking = false;
    state.value = state.value.copyWith(
      status: AudioPlaybackStatus.idle,
      clearCurrentText: true,
    );
  }

  /// Toggle mute. When muted, stops speech and clears queue.
  Future<void> setMuted({required bool muted}) async {
    await init();
    if (muted == state.value.isMuted) return;

    state.value = state.value.copyWith(isMuted: muted);

    if (muted) {
      await stop(clearQueue: true);
      return;
    }

    if (!_isSpeaking) {
      await _playNext();
    }
  }

  /// Set volume (0.0 - 1.0).
  Future<void> setVolume(double volume) async {
    await init();
    final v = volume.clamp(0.0, 1.0);
    state.value = state.value.copyWith(volume: v);
    await _tts.setVolume(v);
  }

  /// Set speech rate (0.2 - 0.8 for natural voice).
  Future<void> setRate(double rate) async {
    await init();
    final r = rate.clamp(0.2, 0.8);
    state.value = state.value.copyWith(rate: r);
    await _tts.setSpeechRate(r);
  }

  /// Set pitch (0.8 - 1.2 for natural voice).
  Future<void> setPitch(double pitch) async {
    await init();
    final p = pitch.clamp(0.8, 1.2);
    state.value = state.value.copyWith(pitch: p);
    await _tts.setPitch(p);
  }

  /// Get available voices.
  Future<List<dynamic>> getVoices() async {
    await init();
    try {
      final voices = await _tts.getVoices;
      return voices as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  /// Set specific voice.
  Future<void> setVoice(Map<String, String> voice) async {
    await init();
    await _tts.setVoice(voice);
  }

  /// Dispose resources.
  Future<void> dispose() async {
    if (!_initialized) return;
    await _tts.stop();
    state.dispose();
  }

  /// Raw TTS instance for advanced usage.
  FlutterTts get instance => _tts;

  Future<void> _applyVoiceParams({
    required double volume,
    required double rate,
    required double pitch,
  }) async {
    await _tts.setVolume(volume.clamp(0.0, 1.0));
    await _tts.setSpeechRate(rate.clamp(0.2, 0.8));
    await _tts.setPitch(pitch.clamp(0.8, 1.2));
  }

  Future<void> _playNext() async {
    if (state.value.isMuted) return;
    if (_isSpeaking) return;
    if (_queue.isEmpty) return;

    final next = _queue.removeFirst();
    state.value = state.value.copyWith(currentText: next);

    await _tts.speak(next);
  }
}
