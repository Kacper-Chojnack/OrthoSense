import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/shared_preferences_provider.dart';
import 'package:orthosense/core/services/preferences_service.dart';
import 'package:video_player/video_player.dart';

/// Demo video data model for local/hardcoded videos.
/// In production, this would come from API.
class DemoVideo {
  const DemoVideo({
    required this.title,
    required this.description,
    required this.assetPath,
    this.viewAngle = 'front',
  });

  final String title;
  final String description;
  final String assetPath;
  final String viewAngle;
}

/// Widget that shows an exercise demo video before starting analysis.
/// User can choose "Don't show again" to skip for this exercise.
class ExerciseDemoVideoSheet extends ConsumerStatefulWidget {
  const ExerciseDemoVideoSheet({
    required this.exerciseId,
    required this.exerciseName,
    required this.demoVideo,
    required this.onContinue,
    super.key,
  });

  final int exerciseId;
  final String exerciseName;
  final DemoVideo demoVideo;
  final VoidCallback onContinue;

  /// Shows the demo video sheet if user hasn't opted to skip.
  /// Returns true if user should proceed, false if cancelled.
  static Future<bool> showIfNeeded({
    required BuildContext context,
    required WidgetRef ref,
    required int exerciseId,
    required String exerciseName,
    DemoVideo? demoVideo,
    required VoidCallback onContinue,
  }) async {
    // Check if user opted to skip demo for this exercise
    final prefs = PreferencesService(ref.read(sharedPreferencesProvider));
    if (prefs.shouldSkipExerciseVideo(exerciseId)) {
      return true; // Skip video, proceed directly
    }

    // No demo video configured for this exercise
    if (demoVideo == null) {
      return true;
    }

    // Show the demo video sheet
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDemoVideoSheet(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        demoVideo: demoVideo,
        onContinue: onContinue,
      ),
    );

    return result ?? false;
  }

  @override
  ConsumerState<ExerciseDemoVideoSheet> createState() =>
      _ExerciseDemoVideoSheetState();
}

class _ExerciseDemoVideoSheetState
    extends ConsumerState<ExerciseDemoVideoSheet> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _dontShowAgain = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.demoVideo.assetPath);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load demo video';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    // Save preference if user checked "Don't show again"
    if (_dontShowAgain) {
      final prefs = PreferencesService(ref.read(sharedPreferencesProvider));
      await prefs.setSkipExerciseVideo(
        exerciseId: widget.exerciseId,
        skip: true,
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Title
                    Text(
                      'How to perform',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.exerciseName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Video Player
                    Container(
                      height: screenHeight * 0.35,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildVideoContent(),
                    ),
                    const SizedBox(height: 16),

                    // Video description
                    Text(
                      widget.demoVideo.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.demoVideo.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // "Don't show again" checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _dontShowAgain,
                          onChanged: (value) {
                            setState(() {
                              _dontShowAgain = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _dontShowAgain = !_dontShowAgain;
                              });
                            },
                            child: Text(
                              "Don't show this video again for this exercise",
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Continue button
                    FilledButton(
                      onPressed: _handleContinue,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Start Exercise'),
                    ),
                    const SizedBox(height: 16),

                    // Cancel button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        // Play/Pause overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            },
            child: AnimatedOpacity(
              opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black38,
                child: const Icon(
                  Icons.play_arrow,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        // View angle badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.demoVideo.viewAngle.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
