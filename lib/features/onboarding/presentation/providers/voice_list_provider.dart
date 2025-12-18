import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:orthosense/core/providers/tts_provider.dart';

part 'voice_list_provider.g.dart';

@riverpod
Future<List<Map<String, String>>> voiceList(Ref ref) async {
  final tts = ref.read(ttsServiceProvider);
  final voices = await tts.getVoices();
  
  final allVoices = voices.map((e) => Map<String, String>.from(e as Map)).toList();

  // Define high-quality voice identifiers
  // Expanded list to ensure we get enough options on standard devices
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

  final androidBestVoices = [
    'en-us-x-iom', // Male
    'en-us-x-tpd', // Male
    'en-gb-x-rjs', // Male
    'en-us-x-iob', // Female
    'en-us-x-tpf', // Female
    'en-gb-x-fis', // Female
  ];

  return allVoices.where((voice) {
    final name = voice['name'] ?? '';
    final locale = voice['locale'] ?? '';
    
    // Basic English filter
    if (!locale.toLowerCase().startsWith('en')) return false;

    if (Platform.isIOS) {
      // Check if name contains any of the best identifiers
      return iosBestVoices.any((best) => name.contains(best));
    } else if (Platform.isAndroid) {
      // Check if name contains any of the best identifiers
      return androidBestVoices.any((best) => name.contains(best));
    }
    
    return true; // Fallback for other platforms
  }).toList();
}
