import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/exercise_classifier_provider.dart';
import 'package:orthosense/core/providers/movement_diagnostics_provider.dart';
import 'package:orthosense/core/providers/pose_detection_provider.dart';
import 'package:orthosense/core/providers/tts_provider.dart';
import 'package:orthosense/core/services/movement_diagnostics_service.dart';
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart';
import 'package:orthosense/features/exercise/presentation/widgets/countdown_overlay.dart';

/// Analysis phases for the exercise session.
enum AnalysisPhase {
  idle,
  countdown,
  setup,
  calibrationClassification,
  calibrationVariant,
  analyzing,
  completed,
}

/// Professional live analysis screen with countdown and TTS feedback.
class LiveAnalysisScreen extends ConsumerStatefulWidget {
  const LiveAnalysisScreen({super.key});

  @override
  ConsumerState<LiveAnalysisScreen> createState() => _LiveAnalysisScreenState();
}

class _LiveAnalysisScreenState extends ConsumerState<LiveAnalysisScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  AnalysisPhase _currentPhase = AnalysisPhase.idle;
  Timer? _phaseTimer;

  final List<PoseFrame> _rawBuffer = [];
  static const _windowSize = 60;
  static const _predictionInterval = 5;

  final List<String> _calibrationVotes = [];

  String? _detectedExercise;
  String? _detectedVariant;
  String? _currentFeedback;
  bool _hasError = false;

  DateTime? _lastFrameProcessTime;
  static const _frameProcessingInterval = Duration(milliseconds: 66);
  int _frameCount = 0;

  final List<bool> _visibilityBuffer = [];
  static const _visibilityWindowSize = 30;
  static const _minVisibilityRatio = 0.7;

  PoseFrame? _debugPose;
  PoseFrame? _lastSmoothedPose;
  Size? _sourceImageSize;

  final Map<String, int> _sessionErrorCounts = {};
  int _totalAnalysisFrames = 0;
  int _correctFrames = 0;

  // Animation controllers
  late AnimationController _feedbackAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _feedbackScaleAnimation;
  late Animation<double> _pulseAnimation;

  // Session timer
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
  Duration _sessionDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
    _initializeTts();
  }

  void _initializeAnimations() {
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _feedbackScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeTts() async {
    final tts = ref.read(ttsServiceProvider);
    await tts.init();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final imageFormatGroup = Platform.isIOS
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.yuv420;

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: imageFormatGroup,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _stopAnalysis();
    _feedbackAnimationController.dispose();
    _pulseController.dispose();
    _sessionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _currentPhase = AnalysisPhase.countdown;
    });
  }

  void _onCountdownTick(int count) {
    final tts = ref.read(ttsServiceProvider);
    tts.speak('$count');
    HapticFeedback.mediumImpact();
  }

  void _onCountdownComplete() {
    final tts = ref.read(ttsServiceProvider);
    tts.speak('Go! Start your exercise.');
    HapticFeedback.heavyImpact();
    _startAnalysis();
  }

  void _startAnalysis() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _currentPhase = AnalysisPhase.setup;
      _rawBuffer.clear();
      _calibrationVotes.clear();
      _detectedExercise = null;
      _detectedVariant = null;
      _currentFeedback = null;
      _hasError = false;
      _visibilityBuffer.clear();
      _frameCount = 0;
      _debugPose = null;
      _lastSmoothedPose = null;
      _sessionErrorCounts.clear();
      _totalAnalysisFrames = 0;
      _correctFrames = 0;
      _sessionStartTime = DateTime.now();
      _sessionDuration = Duration.zero;
    });

    _pulseController.repeat(reverse: true);

    // Start session timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionStartTime != null && mounted) {
        setState(() {
          _sessionDuration = DateTime.now().difference(_sessionStartTime!);
        });
      }
    });

    _controller!.startImageStream(_processCameraFrame).catchError((
      Object error,
    ) {
      debugPrint('Error starting image stream: $error');
      _handleError('Failed to start camera stream');
    });

    _phaseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _currentPhase == AnalysisPhase.setup) {
        setState(() {
          _currentPhase = AnalysisPhase.calibrationClassification;
        });
        final tts = ref.read(ttsServiceProvider);
        tts.speak('Analyzing your exercise. Keep moving.');

        _phaseTimer = Timer(const Duration(seconds: 6), () {
          _performClassification();
        });
      }
    });
  }

  void _finishAndShowReport() {
    _stopAnalysis();

    final tts = ref.read(ttsServiceProvider);
    tts.speak('Analysis complete. Great job!');

    setState(() {
      _currentPhase = AnalysisPhase.completed;
    });

    if (_totalAnalysisFrames < 5 || _detectedExercise == null) {
      _showResultsDialog(null);
      return;
    }

    final correctRatio = _correctFrames / _totalAnalysisFrames;
    final isSessionCorrect = correctRatio > 0.7;

    final Map<String, dynamic> finalFeedback = {};

    if (!isSessionCorrect) {
      final threshold = _totalAnalysisFrames * 0.10;

      _sessionErrorCounts.forEach((key, count) {
        if (count > threshold) {
          finalFeedback[key] = true;
        }
      });

      if (finalFeedback.isEmpty && _sessionErrorCounts.isNotEmpty) {
        final sorted = _sessionErrorCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        finalFeedback[sorted.first.key] = true;
      }
    }

    final finalResult = DiagnosticsResult(
      isCorrect: isSessionCorrect,
      feedback: finalFeedback,
    );

    _showResultsDialog(finalResult);
  }

  void _showResultsDialog(DiagnosticsResult? result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final diagnostics = ref.read(movementDiagnosticsServiceProvider);

    String reportText;
    bool isSuccess;

    if (result == null || _detectedExercise == null) {
      reportText =
          'Session was too short to generate meaningful feedback. '
          'Try exercising for at least 10 seconds.';
      isSuccess = false;
    } else {
      reportText = diagnostics.generateReport(result, _detectedExercise!);
      isSuccess = result.isCorrect;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle : Icons.info_outline,
                      size: 48,
                      color: isSuccess ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSuccess ? 'Great Session!' : 'Session Complete',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_detectedExercise != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _detectedExercise!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Duration: ${_formatDuration(_sessionDuration)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Report content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    reportText,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            // Action button
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _currentPhase = AnalysisPhase.idle;
                  });
                },
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _performClassification() async {
    debugPrint(
      '[Classification] Starting classification with ${_calibrationVotes.length} votes',
    );

    if (_calibrationVotes.isEmpty) {
      _handleError('Unable to detect exercise, please try again');
      return;
    }

    final voteCounts = <String, int>{};
    for (final vote in _calibrationVotes) {
      voteCounts[vote] = (voteCounts[vote] ?? 0) + 1;
    }

    String? winnerExercise;
    int maxVotes = 0;
    for (final entry in voteCounts.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winnerExercise = entry.key;
      }
    }

    if (winnerExercise == null) {
      _handleError('Unable to detect exercise, please try again');
      return;
    }

    final votingConfidence = maxVotes / _calibrationVotes.length;
    debugPrint('[Classification] Winner: $winnerExercise ($maxVotes votes)');

    if (votingConfidence < 0.3) {
      _handleError('Unable to detect exercise, please try again');
      return;
    }

    if (mounted) {
      setState(() {
        _detectedExercise = winnerExercise;
        _currentPhase = AnalysisPhase.calibrationVariant;
      });

      final tts = ref.read(ttsServiceProvider);
      tts.speak('Detected $winnerExercise. Analyzing form.');

      _phaseTimer = Timer(const Duration(seconds: 4), () {
        _performVariantDetection();
      });
    }
  }

  Future<void> _performVariantDetection() async {
    if (_detectedExercise == null) {
      _handleError('Unable to detect exercise, please try again');
      return;
    }

    if (_rawBuffer.length < 10) {
      if (mounted) {
        setState(() {
          _detectedVariant = 'BOTH';
          _currentPhase = AnalysisPhase.analyzing;
        });
      }
      return;
    }

    try {
      final diagnostics = ref.read(movementDiagnosticsServiceProvider);
      final recentFrames = _rawBuffer.length > 30
          ? _rawBuffer.sublist(_rawBuffer.length - 30)
          : _rawBuffer;
      final skeletonData = recentFrames
          .map(
            (frame) => frame.landmarks.map((lm) => [lm.x, lm.y, lm.z]).toList(),
          )
          .toList();

      final variant = diagnostics.detectVariant(
        _detectedExercise!,
        skeletonData,
      );

      if (mounted) {
        setState(() {
          _detectedVariant = variant;
          _currentPhase = AnalysisPhase.analyzing;
        });

        final tts = ref.read(ttsServiceProvider);
        tts.speak('Now monitoring your form. Keep going!');
      }
    } catch (e) {
      debugPrint('Variant detection error: $e');
      _handleError('Unable to detect exercise, please try again');
    }
  }

  PoseFrame _smoothPose(PoseFrame newPose) {
    if (_lastSmoothedPose == null) {
      _lastSmoothedPose = newPose;
      return newPose;
    }

    const double alpha = 0.6;
    final smoothedLandmarks = <PoseLandmark>[];

    for (int i = 0; i < newPose.landmarks.length; i++) {
      final prevLm = _lastSmoothedPose!.landmarks[i];
      final newLm = newPose.landmarks[i];

      final smoothedX = (prevLm.x * (1 - alpha)) + (newLm.x * alpha);
      final smoothedY = (prevLm.y * (1 - alpha)) + (newLm.y * alpha);
      final smoothedZ = (prevLm.z * (1 - alpha)) + (newLm.z * alpha);

      smoothedLandmarks.add(
        PoseLandmark(
          x: smoothedX,
          y: smoothedY,
          z: smoothedZ,
        ),
      );
    }

    final smoothedPose = PoseFrame(landmarks: smoothedLandmarks);

    _lastSmoothedPose = smoothedPose;

    return smoothedPose;
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    final now = DateTime.now();
    if (_lastFrameProcessTime != null &&
        now.difference(_lastFrameProcessTime!) < _frameProcessingInterval) {
      return;
    }
    _lastFrameProcessTime = now;

    if (_controller == null) return;

    try {
      final poseService = ref.read(poseDetectionServiceProvider);
      final poseFrame = await poseService.detectPoseFromCameraImage(
        image,
        _controller!.description,
      );

      if (poseFrame == null) return;

      if (mounted) {
        final smoothedPose = _smoothPose(poseFrame);

        setState(() {
          _debugPose = smoothedPose;
          _sourceImageSize = Size(
            image.width.toDouble(),
            image.height.toDouble(),
          );
        });
      }

      if (!mounted) return;

      final isVisible = poseService.checkPoseVisibility(poseFrame);

      _visibilityBuffer.add(isVisible);
      if (_visibilityBuffer.length > _visibilityWindowSize) {
        _visibilityBuffer.removeAt(0);
      }

      if (isVisible) {
        _rawBuffer.add(poseFrame);
        if (_rawBuffer.length > _windowSize) {
          _rawBuffer.removeAt(0);
        }
      }

      if (_currentPhase == AnalysisPhase.analyzing &&
          _visibilityBuffer.length >= _visibilityWindowSize) {
        final visibleCount = _visibilityBuffer.where((v) => v).length;
        final visibilityRatio = visibleCount / _visibilityBuffer.length;

        if (visibilityRatio < _minVisibilityRatio) {
          if (mounted) {
            _updateFeedback('Step back - full body needed', isError: true);
          }
          return;
        } else {
          if (mounted && _currentFeedback == 'Step back - full body needed') {
            _updateFeedback(null, isError: false);
          }
        }
      }

      if (_rawBuffer.length == _windowSize &&
          _frameCount % _predictionInterval == 0) {
        if (isVisible) {
          if (_currentPhase == AnalysisPhase.calibrationClassification) {
            await _analyzeCalibrationFrame();
          } else if (_currentPhase == AnalysisPhase.analyzing) {
            await _analyzeFrame();
          }
        } else {
          if (mounted && _currentPhase == AnalysisPhase.analyzing) {
            _updateFeedback('Move into frame', isError: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    }
  }

  void _updateFeedback(String? feedback, {required bool isError}) {
    if (_currentFeedback != feedback) {
      setState(() {
        _currentFeedback = feedback;
        _hasError = isError;
      });
      _feedbackAnimationController.forward(from: 0);
    }
  }

  Future<void> _analyzeCalibrationFrame() async {
    if (_rawBuffer.length < 60) return;

    try {
      final poseService = ref.read(poseDetectionServiceProvider);
      final classifier = ref.read(exerciseClassifierServiceProvider);

      final windowFrames = _rawBuffer.length >= 60
          ? _rawBuffer.sublist(_rawBuffer.length - 60)
          : _rawBuffer;

      final validFrames = <PoseFrame>[];
      for (final frame in windowFrames) {
        if (poseService.checkPoseVisibility(frame)) {
          validFrames.add(frame);
        }
      }

      if (validFrames.length < 30) return;

      final landmarks = PoseLandmarks(frames: validFrames, fps: 30.0);
      final classification = await classifier.classify(landmarks);

      final exName = classification.exercise;
      if (exName != 'Unknown Exercise' &&
          exName != 'No Exercise Detected' &&
          classification.confidence > 0.50) {
        _calibrationVotes.add(exName);
      }
    } catch (e) {
      debugPrint('Calibration analysis error: $e');
    }
  }

  Future<void> _analyzeFrame() async {
    if (_detectedExercise == null) return;
    if (_rawBuffer.length < 60) return;

    try {
      final diagnostics = ref.read(movementDiagnosticsServiceProvider);
      final windowFrames = _rawBuffer.length >= 60
          ? _rawBuffer.sublist(_rawBuffer.length - 60)
          : _rawBuffer;
      final landmarks = PoseLandmarks(frames: windowFrames, fps: 30.0);

      final result = diagnostics.diagnose(
        _detectedExercise!,
        landmarks,
        forcedVariant: _detectedVariant,
      );

      if (_currentPhase == AnalysisPhase.analyzing) {
        _totalAnalysisFrames++;
        if (result.isCorrect) {
          _correctFrames++;
        } else {
          for (final key in result.feedback.keys) {
            _sessionErrorCounts[key] = (_sessionErrorCounts[key] ?? 0) + 1;
          }
        }
      }

      if (mounted && _currentPhase == AnalysisPhase.analyzing) {
        if (_currentFeedback != 'Step back - full body needed' &&
            _currentFeedback != 'Move into frame') {
          if (result.isCorrect) {
            _updateFeedback('Perfect form!', isError: false);
          } else {
            final firstError = result.feedback.keys.first;
            String errorMsg = firstError;
            if (errorMsg.contains('°')) {
              errorMsg = errorMsg.split('°').first.trim();
              errorMsg = errorMsg.replaceAll(RegExp(r'\([^)]*°[^)]*\)'), '');
            }
            _updateFeedback(errorMsg, isError: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
    }
  }

  void _handleError(String message) {
    debugPrint('[Live Analysis] ERROR: $message');
    if (mounted) {
      final tts = ref.read(ttsServiceProvider);
      tts.speak(message);

      setState(() {
        _currentPhase = AnalysisPhase.idle;
        _currentFeedback = message;
        _hasError = true;
      });
      _stopAnalysis();
    }
  }

  void _stopAnalysis() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _pulseController.stop();
    _controller?.stopImageStream();
    setState(() {
      _debugPose = null;
    });
  }

  String _getPhaseTitle() {
    switch (_currentPhase) {
      case AnalysisPhase.idle:
        return 'Ready';
      case AnalysisPhase.countdown:
        return 'Get Ready';
      case AnalysisPhase.setup:
        return 'Preparing...';
      case AnalysisPhase.calibrationClassification:
        return 'Detecting Exercise';
      case AnalysisPhase.calibrationVariant:
        return 'Analyzing Side';
      case AnalysisPhase.analyzing:
        return _detectedExercise ?? 'Analyzing';
      case AnalysisPhase.completed:
        return 'Complete';
    }
  }

  String _getPhaseSubtitle() {
    switch (_currentPhase) {
      case AnalysisPhase.idle:
        return 'Tap start when ready';
      case AnalysisPhase.countdown:
        return 'Position yourself in frame';
      case AnalysisPhase.setup:
        return 'Setting up camera...';
      case AnalysisPhase.calibrationClassification:
        return 'Keep exercising naturally';
      case AnalysisPhase.calibrationVariant:
        return 'Detecting movement side';
      case AnalysisPhase.analyzing:
        return _detectedVariant != null
            ? 'Side: $_detectedVariant'
            : 'Monitoring form';
      case AnalysisPhase.completed:
        return 'Great work!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Initializing Camera...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          _buildCameraPreview(),

          // Gradient overlays
          _buildGradientOverlays(),

          // Top status bar
          _buildTopBar(theme, colorScheme),

          // Feedback indicator
          if (_currentFeedback != null &&
              _currentPhase == AnalysisPhase.analyzing)
            _buildFeedbackIndicator(theme, colorScheme),

          // Bottom controls
          _buildBottomControls(theme, colorScheme),

          // Countdown overlay
          if (_currentPhase == AnalysisPhase.countdown)
            CountdownOverlay(
              onComplete: _onCountdownComplete,
              onCountdown: _onCountdownTick,
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Positioned.fill(
      child: _controller!.value.isInitialized
          ? LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                var scale = size.aspectRatio * _controller!.value.aspectRatio;

                if (scale < 1) scale = 1 / scale;

                return Transform.scale(
                  scale: scale,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: CameraPreview(_controller!),
                      ),
                      if (_debugPose != null && _sourceImageSize != null)
                        CustomPaint(
                          painter: _AdvancedPosePainter(
                            pose: _debugPose!,
                            imageSize: _sourceImageSize!,
                            isFrontCamera:
                                _controller!.description.lensDirection ==
                                CameraLensDirection.front,
                            isCorrect: !_hasError,
                          ),
                        ),
                    ],
                  ),
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildGradientOverlays() {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Top gradient
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black87,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black87,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, ColorScheme colorScheme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                ),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              // Status info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPhaseTitle(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getPhaseSubtitle(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Timer (when analyzing)
              if (_currentPhase == AnalysisPhase.analyzing) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 8 * _pulseAnimation.value,
                            height: 8 * _pulseAnimation.value,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_sessionDuration),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackIndicator(ThemeData theme, ColorScheme colorScheme) {
    final isPositive = !_hasError;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 24,
      right: 24,
      child: AnimatedBuilder(
        animation: _feedbackScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _feedbackScaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPositive
                      ? [
                          const Color(0xFF00C853),
                          const Color(0xFF00E676),
                        ]
                      : [
                          const Color(0xFFFF5252),
                          const Color(0xFFFF1744),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(
                      0.4,
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPositive ? Icons.check_circle : Icons.warning_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _currentFeedback!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme, ColorScheme colorScheme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main action button
              if (_currentPhase == AnalysisPhase.idle ||
                  _currentPhase == AnalysisPhase.completed)
                _buildStartButton(colorScheme)
              else if (_currentPhase != AnalysisPhase.countdown)
                _buildStopButton(colorScheme),

              const SizedBox(height: 16),

              // Quick tips
              if (_currentPhase == AnalysisPhase.idle)
                Text(
                  'Ensure good lighting and full body visibility',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _startCountdown,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStopButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _finishAndShowReport,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.stop_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Advanced pose painter with color coding and smoother rendering.
class _AdvancedPosePainter extends CustomPainter {
  _AdvancedPosePainter({
    required this.pose,
    required this.imageSize,
    this.isFrontCamera = true,
    this.isCorrect = true,
  });

  final PoseFrame pose;
  final Size imageSize;
  final bool isFrontCamera;
  final bool isCorrect;

  static const List<List<int>> connections = [
    [11, 12], // shoulders
    [11, 13], [13, 15], // left arm
    [12, 14], [14, 16], // right arm
    [11, 23], [12, 24], // torso sides
    [23, 24], // hips
    [23, 25], [25, 27], // left leg
    [24, 26], [26, 28], // right leg
  ];

  static const List<int> allowedLandmarks = [
    11, 12, 13, 14, 15, 16, // upper body
    23, 24, 25, 26, 27, 28, // lower body
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (pose.landmarks.isEmpty) return;

    final color = isCorrect ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..color = color;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final jointGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    double screenRatio = size.width / size.height;
    double imageRatio = imageSize.width / imageSize.height;

    double contentWidth, contentHeight;

    if (screenRatio > imageRatio) {
      contentHeight = size.height;
      contentWidth = size.height * imageRatio;
    } else {
      contentWidth = size.width;
      contentHeight = size.width / imageRatio;
    }

    double offsetX = (size.width - contentWidth) / 2;
    double offsetY = (size.height - contentHeight) / 2;

    Offset getPoint(int index) {
      if (index >= pose.landmarks.length) return Offset.zero;

      final landmark = pose.landmarks[index];
      double x = landmark.x * contentWidth + offsetX;
      double y = landmark.y * contentHeight + offsetY;

      return Offset(x, y);
    }

    // Draw glow connections
    for (final pair in connections) {
      if (pair[0] < pose.landmarks.length && pair[1] < pose.landmarks.length) {
        final start = getPoint(pair[0]);
        final end = getPoint(pair[1]);

        if (start != Offset.zero && end != Offset.zero) {
          canvas.drawLine(start, end, glowPaint);
        }
      }
    }

    // Draw solid connections
    for (final pair in connections) {
      if (pair[0] < pose.landmarks.length && pair[1] < pose.landmarks.length) {
        final start = getPoint(pair[0]);
        final end = getPoint(pair[1]);

        if (start != Offset.zero && end != Offset.zero) {
          canvas.drawLine(start, end, linePaint);
        }
      }
    }

    // Draw joints with glow
    for (final index in allowedLandmarks) {
      if (index < pose.landmarks.length) {
        final point = getPoint(index);
        if (point != Offset.zero) {
          canvas.drawCircle(point, 10.0, jointGlowPaint);
          canvas.drawCircle(point, 6.0, jointPaint);

          // White center dot
          final centerPaint = Paint()..color = Colors.white;
          canvas.drawCircle(point, 3.0, centerPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AdvancedPosePainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.isCorrect != isCorrect;
  }
}
