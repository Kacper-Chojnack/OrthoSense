import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:orthosense/core/services/tts_service.dart';

part 'tts_provider.g.dart';

@Riverpod(keepAlive: true)
TtsService ttsService(Ref ref) {
  return TtsService();
}
