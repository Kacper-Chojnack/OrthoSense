import 'dart:async' show unawaited;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:orthosense/core/providers/exercise_classifier_provider.dart';
import 'package:orthosense/core/providers/movement_diagnostics_provider.dart';
import 'package:orthosense/core/providers/pose_detection_provider.dart';
import 'package:orthosense/core/services/pose_detection_service.dart'
    show PoseAnalysisCancelledException, PoseAnalysisCancellationToken;
import 'package:orthosense/core/theme/app_colors.dart';
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart';
import 'package:video_player/video_player.dart';

class GalleryAnalysisScreen extends ConsumerStatefulWidget {
  const GalleryAnalysisScreen({super.key});

  @override
  ConsumerState<GalleryAnalysisScreen> createState() =>
      _GalleryAnalysisScreenState();
}

class _GalleryAnalysisScreenState extends ConsumerState<GalleryAnalysisScreen> {
  File? _selectedVideo;
  File? _selectedVideoTempCopy;
  VideoPlayerController? _videoController;
  bool _isAnalyzing = false;
  bool _isExtractingLandmarks = false;
  Map<String, dynamic>? _result;
  String? _error;
  double _extractionProgress = 0;
  PoseLandmarks? _extractedLandmarks;
  int _analysisRunId = 0;
  PoseAnalysisCancellationToken? _analysisCancelToken;

  @override
  void dispose() {
    _cancelCurrentAnalysis(resetUi: false);
    _videoController?.dispose();
    _deleteTempCopyIfAny();
    super.dispose();
  }

  void _deleteTempCopyIfAny() {
    final file = _selectedVideoTempCopy;
    _selectedVideoTempCopy = null;
    if (file == null) return;
    try {
      unawaited(file.delete());
    } catch (_) {}
  }

  void _cancelCurrentAnalysis({required bool resetUi}) {
    _analysisCancelToken?.cancel();
    _analysisCancelToken = null;
    _analysisRunId++;

    if (resetUi && mounted) {
      setState(() {
        _isAnalyzing = false;
        _isExtractingLandmarks = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    _cancelCurrentAnalysis(resetUi: true);
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      await _videoController?.dispose();
      _deleteTempCopyIfAny();

      final original = File(video.path);
      File fileToUse = original;

      try {
        final tmpDir = await getTemporaryDirectory();
        final ext = p.extension(video.path);
        final tmpPath = p.join(
          tmpDir.path,
          'orthosense_gallery_${DateTime.now().microsecondsSinceEpoch}$ext',
        );
        fileToUse = await original.copy(tmpPath);
        _selectedVideoTempCopy = fileToUse;
      } catch (e) {
        fileToUse = original;
      }

      final controller = VideoPlayerController.file(fileToUse);

      await controller.initialize();

      setState(() {
        _selectedVideo = fileToUse;
        _videoController = controller;
        _result = null;
        _error = null;
        _extractionProgress = 0;
        _extractedLandmarks = null;
      });
    }
  }

  Future<void> _analyzeVideo() async {
    if (_selectedVideo == null) return;

    _cancelCurrentAnalysis(resetUi: false);
    final runId = _analysisRunId;
    final cancelToken = PoseAnalysisCancellationToken();
    _analysisCancelToken = cancelToken;
    final videoToAnalyze = _selectedVideo!;

    setState(() {
      _isAnalyzing = true;
      _isExtractingLandmarks = true;
      _error = null;
      _extractionProgress = 0;
      _extractedLandmarks = null;
      _result = null;
    });

    try {
      final poseService = ref.read(poseDetectionServiceProvider);

      final landmarks = await poseService.extractLandmarksFromVideo(
        videoToAnalyze,
        cancelToken: cancelToken,
        onProgress: (progress) {
          if (!mounted || runId != _analysisRunId) return;
          if (mounted) {
            setState(() {
              _extractionProgress = progress;
            });
          }
        },
      );

      if (!mounted || runId != _analysisRunId) return;

      if (landmarks.isEmpty) {
        if (mounted && runId == _analysisRunId) {
          setState(() {
            _error = 'No pose detected in the video or video is too short.';
            _isAnalyzing = false;
            _isExtractingLandmarks = false;
          });
        }
        return;
      }

      int visibleCount = 0;
      for (final frame in landmarks.frames) {
        if (poseService.checkPoseVisibility(frame)) visibleCount++;
      }

      final validLandmarks = landmarks;

      if (mounted && runId == _analysisRunId) {
        setState(() {
          _isExtractingLandmarks = false;
          _extractedLandmarks = validLandmarks;
        });
      }

      final classifier = ref.read(exerciseClassifierServiceProvider);
      final classification = await classifier.classify(
        validLandmarks,
      );

      if (!mounted || runId != _analysisRunId) return;

      final diagnostics = ref.read(movementDiagnosticsServiceProvider);
      final diagnosticsResult = diagnostics.diagnose(
        classification.exercise,
        validLandmarks,
      );

      final textReport = diagnostics.generateReport(
        diagnosticsResult,
        classification.exercise,
      );

      if (mounted && runId == _analysisRunId) {
        setState(() {
          _result = {
            'exercise': classification.exercise,
            'confidence': classification.confidence,
            'is_correct': diagnosticsResult.isCorrect,
            'feedback': diagnosticsResult.feedback,
            'text_report': textReport,
          };
        });
      }
    } catch (e) {
      if (e is PoseAnalysisCancelledException) {
        return;
      }
      if (mounted) {
        setState(() {
          final msg = e.toString();
          if (msg.contains('Insufficient pose frames detected')) {
            _error =
                'Insufficient body visibility detected. Please ensure your full body is visible in the video.';
          } else {
            _error = 'Analysis failed: $e';
          }
        });
      }
    } finally {
      if (mounted && runId == _analysisRunId) {
        setState(() {
          _isAnalyzing = false;
          _isExtractingLandmarks = false;
        });
      }
    }
  }

  void _clearSelection() {
    _cancelCurrentAnalysis(resetUi: true);
    _videoController?.dispose();
    _deleteTempCopyIfAny();
    setState(() {
      _selectedVideo = null;
      _videoController = null;
      _result = null;
      _error = null;
      _extractionProgress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery Analysis'),
        actions: [
          if (_selectedVideo != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear selection',
              onPressed: _clearSelection,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VideoSelectionArea(
              selectedVideo: _selectedVideo,
              videoController: _videoController,
              onPickVideo: _pickVideo,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _ActionButtons(
              selectedVideo: _selectedVideo,
              isAnalyzing: _isAnalyzing,
              isExtractingLandmarks: _isExtractingLandmarks,
              extractionProgress: _extractionProgress,
              onPickVideo: _pickVideo,
              onAnalyze: _analyzeVideo,
            ),
            const SizedBox(height: 24),
            if (_error != null)
              _ErrorCard(error: _error!, colorScheme: colorScheme),
            if (_result != null) _ResultCard(result: _result!, theme: theme),
          ],
        ),
      ),
    );
  }
}

class _VideoSelectionArea extends StatelessWidget {
  const _VideoSelectionArea({
    required this.selectedVideo,
    required this.videoController,
    required this.onPickVideo,
    required this.colorScheme,
  });

  final File? selectedVideo;
  final VideoPlayerController? videoController;
  final VoidCallback onPickVideo;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selectedVideo == null ? onPickVideo : null,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: selectedVideo == null
            ? _EmptyState(colorScheme: colorScheme)
            : _VideoPreview(controller: videoController),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 56,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to select a video',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'MP4, MOV, AVI supported',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.controller});

  final VideoPlayerController? controller;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        Positioned.fill(
          child: Container(color: AppColors.videoOverlay),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            });
          },
          icon: Icon(
            controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
            size: 64,
            color: Colors.white,
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.videoControlsBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Video selected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.selectedVideo,
    required this.isAnalyzing,
    required this.isExtractingLandmarks,
    required this.extractionProgress,
    required this.onPickVideo,
    required this.onAnalyze,
  });

  final File? selectedVideo;
  final bool isAnalyzing;
  final bool isExtractingLandmarks;
  final double extractionProgress;
  final VoidCallback onPickVideo;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isAnalyzing ? null : onPickVideo,
                icon: const Icon(Icons.folder_open),
                label: Text(
                  selectedVideo == null ? 'Select Video' : 'Change Video',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: (selectedVideo == null || isAnalyzing)
                    ? null
                    : onAnalyze,
                icon: isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics),
                label: Text(isAnalyzing ? 'Analyzing...' : 'Analyze'),
              ),
            ),
          ],
        ),
        if (isExtractingLandmarks && extractionProgress < 1.0) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: extractionProgress),
          const SizedBox(height: 4),
          Text(
            'Analysing: ${(extractionProgress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (isAnalyzing && !isExtractingLandmarks) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 4),
          Text(
            'Classifying exercise and analyzing movement...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.colorScheme});

  final String error;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.theme});

  final Map<String, dynamic> result;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isCorrect = result['is_correct'] == true;
    final confidence = (result['confidence'] as num? ?? 0) * 100;
    final exercise = result['exercise'] as String? ?? 'Unknown Exercise';

    final feedbackRaw = result['feedback'];
    final String feedback;
    if (feedbackRaw is Map<String, dynamic>) {
      if (feedbackRaw.isEmpty) {
        feedback = 'No feedback available';
      } else {
        feedback = feedbackRaw.entries
            .map((e) => e.value == true ? e.key : '${e.key}: ${e.value}')
            .join('\n');
      }
    } else if (feedbackRaw is String) {
      feedback = feedbackRaw;
    } else {
      feedback = 'No feedback available';
    }

    final textReport = result['text_report'] as String?;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analysis Results',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _ResultRow(
              label: 'Exercise Detected',
              value: exercise,
              theme: theme,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ResultRow(
                    label: 'Confidence',
                    value: '${confidence.toStringAsFixed(1)}%',
                    theme: theme,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getCorrectnessColor(isCorrect: isCorrect),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isCorrect ? 'Correct Form' : 'Needs Improvement',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Feedback',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(feedback, style: theme.textTheme.bodyMedium),
            if (textReport != null && textReport.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Detailed Report',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      textReport,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
