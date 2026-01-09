import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/tts_provider.dart';
import 'package:orthosense/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:orthosense/features/onboarding/presentation/providers/voice_list_provider.dart';

class VoiceSelectionScreen extends ConsumerStatefulWidget {
  const VoiceSelectionScreen({
    super.key,
    this.isSettingsMode = false,
  });

  final bool isSettingsMode;

  @override
  ConsumerState<VoiceSelectionScreen> createState() =>
      _VoiceSelectionScreenState();
}

class _VoiceSelectionScreenState extends ConsumerState<VoiceSelectionScreen> {
  Map<String, String>? _selectedVoice;

  String _getFlag(String locale) {
    if (locale.isEmpty) return '🏳️';
    final countryCode = locale.split('-').last.toUpperCase();
    if (countryCode == 'US') return '🇺🇸';
    if (countryCode == 'GB') return '🇬🇧';
    if (countryCode == 'AU') return '🇦🇺';
    if (countryCode == 'IE') return '🇮🇪';
    if (countryCode == 'ZA') return '🇿🇦';
    if (countryCode == 'IN') return '🇮🇳';
    return '🏳️';
  }

  @override
  Widget build(BuildContext context) {
    final voicesAsync = ref.watch(voiceListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Voice'),
        automaticallyImplyLeading: widget.isSettingsMode,
      ),
      body: voicesAsync.when(
        data: (voices) {
          if (voices.isEmpty) {
            return const Center(
              child: Text('No English voices found on this device.'),
            );
          }

          // Auto-select first voice if none selected and preview it
          if (_selectedVoice == null && voices.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted && _selectedVoice == null) {
                final firstVoice = voices.first;
                setState(() {
                  _selectedVoice = firstVoice;
                });
                // Preview the auto-selected voice
                await _previewVoice(firstVoice);
              }
            });
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choose a voice for your exercise assistant.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: voices.length,
                  itemBuilder: (context, index) {
                    final voice = voices[index];

                    return RadioListTile<Map<String, String>>(
                      title: Text(voice['name'] ?? 'Unknown Voice'),
                      subtitle: Text(_getFlag(voice['locale'] ?? '')),
                      value: voice,
                      groupValue: _selectedVoice,
                      onChanged: (value) {
                        setState(() {
                          _selectedVoice = value;
                        });
                        if (value != null) {
                          _previewVoice(value);
                        }
                      },
                    );
                  },
                  child: ListView.builder(
                    itemCount: voices.length,
                    itemBuilder: (context, index) {
                      final voice = voices[index];

                      // Ensure we have a selection
                      if (_selectedVoice == null && index == 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedVoice = voice;
                          });
                        });
                      }

                      return RadioListTile<Map<String, String>>(
                        title: Text(voice['name'] ?? 'Unknown Voice'),
                        subtitle: Text(_getFlag(voice['locale'] ?? '')),
                        value: voice,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedVoice == null
                        ? null
                        : _confirmSelection,
                    child: Text(widget.isSettingsMode ? 'Save' : 'Continue'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _previewVoice(Map<String, String> voice) async {
    final tts = ref.read(ttsServiceProvider);
    await tts.setVoice(voice);
    await tts.speakNow("Hello, I am ${voice['name']}. Welcome to OrthoSense.");
  }

  Future<void> _confirmSelection() async {
    if (_selectedVoice != null) {
      await ref
          .read(onboardingControllerProvider.notifier)
          .completeVoiceSelection(_selectedVoice!);

      if (widget.isSettingsMode && mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
