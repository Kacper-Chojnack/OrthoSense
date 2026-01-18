import 'dart:io';

import 'package:orthosense/core/providers/tts_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_list_provider.g.dart';

@riverpod
Future<List<Map<String, String>>> voiceList(Ref ref) async {
  final tts = ref.read(ttsServiceProvider);
  final voices = await tts.getVoices();

  final allVoices = voices
      .map((dynamic e) => Map<String, String>.from(e as Map))
      .toList();

  // Define high-quality voice identifiers for iOS
  final iosBestVoices = [
    // Male
    'Alex',
    'Tom',
    'Daniel',
    'Fred',
    'Rishi',
    // Female
    'Ava',
    'Samantha',
    'Allison',
    'Victoria',
    'Karen',
    'Tessa',
  ];

  return allVoices.where((Map<String, String> voice) {
    final name = voice['name'] ?? '';
    final locale = voice['locale'] ?? '';

    // Basic English filter
    if (!locale.toLowerCase().startsWith('en')) return false;

    // On iOS and macOS, filter to high-quality voices
    if (Platform.isIOS || Platform.isMacOS) {
      // Check if name contains any of the best identifiers
      return iosBestVoices.any(name.contains);
    }

    // Fallback for other platforms (shouldn't happen in iOS-only app)
    return true;
  }).toList();
}
