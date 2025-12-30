import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/exercise_classifier_provider.dart';
import 'package:orthosense/core/providers/movement_diagnostics_provider.dart';
import 'package:orthosense/core/providers/pose_detection_provider.dart';
import 'package:orthosense/core/services/exercise_classifier_service.dart';
import 'package:orthosense/core/services/movement_diagnostics_service.dart';
import 'package:orthosense/core/services/pose_detection_service.dart';
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart';

enum AnalysisPhase {
  idle,
  setup,
  calibrationClassification,
  calibrationVariant,
  analyzing,
}

class LiveAnalysisScreen extends ConsumerStatefulWidget {
  const LiveAnalysisScreen({super.key});

  @override
  ConsumerState<LiveAnalysisScreen> createState() => _LiveAnalysisScreenState();
}

class _LiveAnalysisScreenState extends ConsumerState<LiveAnalysisScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  AnalysisPhase _currentPhase = AnalysisPhase.idle;
  Timer? _phaseTimer;

  // Rolling buffer for live analysis (like external repo: 60 frames)
  final List<PoseFrame> _rawBuffer = []; // Rolling buffer, max 60 frames
  static const _windowSize = 60; // Buffer size (like external repo)
  static const _predictionInterval = 5; // Analyze every 5 frames (like external repo)
  
  // Calibration votes (like external repo)
  final List<String> _calibrationVotes = [];
  
  // Calibration results
  String? _detectedExercise;
  String? _detectedVariant;
  String? _currentFeedback;
  bool _hasError = false;

  // Frame processing throttling
  DateTime? _lastFrameProcessTime;
  static const _frameProcessingInterval = Duration(milliseconds: 66); // ~15 FPS
  int _frameCount = 0; // Track frame count for prediction interval

  // Visibility tracking
  final List<bool> _visibilityBuffer = []; // Track visibility of recent frames
  static const _visibilityWindowSize = 30; // Check last 30 frames
  static const _minVisibilityRatio = 0.7; // Need at least 70% visible frames

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
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
    _controller?.dispose();
    super.dispose();
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
    });

    // Start camera stream
    _controller!.startImageStream(_processCameraFrame).catchError((error) {
      debugPrint('Error starting image stream: $error');
      _handleError('Failed to start camera stream');
    });

    // Setup phase: 5 seconds
    _phaseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _currentPhase == AnalysisPhase.setup) {
        setState(() {
          _currentPhase = AnalysisPhase.calibrationClassification;
        });
        // Calibration classification: 10 seconds (like external repo)
        _phaseTimer = Timer(const Duration(seconds: 10), () {
          _performClassification();
        });
      }
    });
  }

  Future<void> _performClassification() async {
    debugPrint('[Classification] Starting classification with ${_calibrationVotes.length} votes');
    debugPrint('[Classification] All votes: $_calibrationVotes');
    
    if (_calibrationVotes.isEmpty) {
      debugPrint('[Classification] ERROR: No votes collected');
      _handleError('No exercise detected during calibration. Please ensure your full body is visible.');
      return;
    }

    // Count votes (like external repo)
    final voteCounts = <String, int>{};
    for (final vote in _calibrationVotes) {
      voteCounts[vote] = (voteCounts[vote] ?? 0) + 1;
    }

    debugPrint('[Classification] Vote counts: $voteCounts');

    String? winnerExercise;
    int maxVotes = 0;
    for (final entry in voteCounts.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winnerExercise = entry.key;
      }
    }

    if (winnerExercise == null) {
      debugPrint('[Classification] ERROR: No winner exercise');
      _handleError('No exercise detected with sufficient confidence.');
      return;
    }

    // Calculate voting confidence (like external repo)
    final votingConfidence = maxVotes / _calibrationVotes.length;
    debugPrint('[Classification] Winner: $winnerExercise ($maxVotes/${_calibrationVotes.length} votes, ${(votingConfidence * 100).toStringAsFixed(1)}%)');

    // Require at least 30% of votes to be for the winner (to avoid random selection)
    if (votingConfidence < 0.3) {
      debugPrint('[Classification] ERROR: Voting confidence too low (${(votingConfidence * 100).toStringAsFixed(1)}% < 30%)');
      _handleError('Exercise detection uncertain. Please try again.');
      return;
    }

    if (mounted) {
      setState(() {
        _detectedExercise = winnerExercise;
        _currentPhase = AnalysisPhase.calibrationVariant;
      });

      // Calibration variant detection: 4 seconds
      _phaseTimer = Timer(const Duration(seconds: 4), () {
        _performVariantDetection();
      });
    }
  }

  Future<void> _performVariantDetection() async {
    if (_detectedExercise == null) {
      _handleError('Exercise not detected');
      return;
    }

    // Use recent frames from buffer for variant detection
    if (_rawBuffer.length < 10) {
      // If not enough frames, use default
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
          .map((frame) => frame.landmarks.map((lm) => [lm.x, lm.y, lm.z]).toList())
          .toList();
      
      final variant = diagnostics.detectVariant(_detectedExercise!, skeletonData);

      if (mounted) {
        setState(() {
          _detectedVariant = variant;
          _currentPhase = AnalysisPhase.analyzing;
        });
      }
    } catch (e) {
      debugPrint('Variant detection error: $e');
      if (mounted) {
        setState(() {
          _detectedVariant = 'BOTH';
          _currentPhase = AnalysisPhase.analyzing;
        });
      }
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    // Throttle frame processing
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

      if (!mounted) return;

      // Check visibility before processing
      final isVisible = poseService.checkPoseVisibility(poseFrame);
      
      // Track visibility in buffer
      _visibilityBuffer.add(isVisible);
      if (_visibilityBuffer.length > _visibilityWindowSize) {
        _visibilityBuffer.removeAt(0);
      }

      // Add to rolling buffer (max 60 frames, like external repo)
      if (isVisible) {
        _rawBuffer.add(poseFrame);
        if (_rawBuffer.length > _windowSize) {
          _rawBuffer.removeAt(0);
        }
      }

      // In analyzing phase, check visibility ratio in recent frames
      if (_currentPhase == AnalysisPhase.analyzing && _visibilityBuffer.length >= _visibilityWindowSize) {
        final visibleCount = _visibilityBuffer.where((v) => v).length;
        final visibilityRatio = visibleCount / _visibilityBuffer.length;
        
        if (visibilityRatio < _minVisibilityRatio) {
          if (mounted) {
            setState(() {
              _currentFeedback = 'Insufficient body visibility - ensure full body is visible';
              _hasError = true;
            });
          }
          return;
        } else {
          if (mounted && _currentFeedback == 'Insufficient body visibility - ensure full body is visible') {
            setState(() {
              _currentFeedback = null;
              _hasError = false;
            });
          }
        }
      }

      // Analyze only if buffer is full and at prediction interval (like external repo)
      if (_rawBuffer.length == _windowSize && _frameCount % _predictionInterval == 0) {
        if (isVisible) {
          if (_currentPhase == AnalysisPhase.calibrationClassification) {
            // During calibration: classify and collect votes
            await _analyzeCalibrationFrame();
          } else if (_currentPhase == AnalysisPhase.analyzing) {
            // During analysis: diagnose with forced exercise
            await _analyzeFrame();
          }
        } else {
          // Not visible - show warning
          if (mounted && _currentPhase == AnalysisPhase.analyzing) {
            setState(() {
              _currentFeedback = 'Please ensure full body is visible';
              _hasError = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    }
  }

  Future<void> _analyzeCalibrationFrame() async {
    if (_rawBuffer.length < 60) return; // Need at least 60 frames (like PyTorch model)

    try {
      final poseService = ref.read(poseDetectionServiceProvider);
      final classifier = ref.read(exerciseClassifierServiceProvider);
      
      // Use last 60 frames (model sequence length, matching PyTorch)
      final windowFrames = _rawBuffer.length >= 60 
          ? _rawBuffer.sublist(_rawBuffer.length - 60)
          : _rawBuffer;
      
      // Filter frames with insufficient visibility (like video analysis)
      final validFrames = <PoseFrame>[];
      for (final frame in windowFrames) {
        if (poseService.checkPoseVisibility(frame)) {
          validFrames.add(frame);
        }
      }
      
      // Need at least some valid frames to classify
      if (validFrames.length < 30) {
        debugPrint('[Calibration] Insufficient valid frames: ${validFrames.length}/60');
        return;
      }
      
      final landmarks = PoseLandmarks(frames: validFrames, fps: 30.0);
      final classification = await classifier.classify(landmarks);

      // Collect votes (like external repo) - match exact logic: confidence > 0.50 and ex_name != "No Exercise Detected"
      final exName = classification.exercise;
      if (exName != 'Unknown Exercise' && 
          exName != 'No Exercise Detected' &&
          classification.confidence > 0.50) {
        _calibrationVotes.add(exName);
        debugPrint('[Calibration] Vote: $exName (${classification.confidence.toStringAsFixed(3)})');
      } else {
        debugPrint('[Calibration] Rejected: $exName (conf: ${classification.confidence.toStringAsFixed(3)})');
      }
    } catch (e) {
      debugPrint('Calibration analysis error: $e');
    }
  }

  Future<void> _analyzeFrame() async {
    if (_detectedExercise == null) return;
    if (_rawBuffer.length < 60) return; // Need at least 60 frames (like PyTorch model)

    try {
      final diagnostics = ref.read(movementDiagnosticsServiceProvider);
      // Use last 60 frames for analysis (matching PyTorch model window size)
      final windowFrames = _rawBuffer.length >= 60 
          ? _rawBuffer.sublist(_rawBuffer.length - 60)
          : _rawBuffer;
      final landmarks = PoseLandmarks(frames: windowFrames, fps: 30.0);
      
      final result = diagnostics.diagnose(
        _detectedExercise!,
        landmarks,
        forcedVariant: _detectedVariant,
      );

      if (mounted && _currentPhase == AnalysisPhase.analyzing) {
        setState(() {
          // Only update feedback if we're not showing visibility warning
          if (_currentFeedback != 'Insufficient body visibility - ensure full body is visible' &&
              _currentFeedback != 'Please ensure full body is visible') {
            _hasError = !result.isCorrect;
            if (result.isCorrect) {
              _currentFeedback = 'Good job';
            } else {
              // Show first error key without angle details
              final firstError = result.feedback.keys.first;
              // Remove angle details from error message
              String errorMsg = firstError;
              if (errorMsg.contains('°')) {
                errorMsg = errorMsg.split('°').first.trim();
                // Remove common angle-related suffixes
                errorMsg = errorMsg.replaceAll(RegExp(r'\([^)]*°[^)]*\)'), '');
              }
              _currentFeedback = errorMsg;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
    }
  }

  void _handleError(String message) {
    debugPrint('[Live Analysis] ERROR: $message');
    if (mounted) {
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
    _controller?.stopImageStream();
  }

  String _getPhaseMessage() {
    switch (_currentPhase) {
      case AnalysisPhase.idle:
        return 'Ready to start';
      case AnalysisPhase.setup:
        return 'Get ready...';
      case AnalysisPhase.calibrationClassification:
        return 'Analyzing exercise...';
      case AnalysisPhase.calibrationVariant:
        return 'Detecting side...';
      case AnalysisPhase.analyzing:
        return _detectedExercise ?? 'Analyzing...';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Analysis'),
        actions: [
          if (_currentPhase != AnalysisPhase.idle)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                setState(() {
                  _currentPhase = AnalysisPhase.idle;
                });
                _stopAnalysis();
              },
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: _controller!.value.isInitialized
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        var scale = size.aspectRatio * _controller!.value.aspectRatio;

                        if (scale < 1) scale = 1 / scale;

                        return Transform.scale(
                          scale: scale,
                          child: Center(
                            child: CameraPreview(_controller!),
                          ),
                        );
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Phase status overlay
          if (_currentPhase != AnalysisPhase.idle)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPhaseMessage(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Real-time feedback overlay - show in analyzing phase or when there's an error message
          if (_currentFeedback != null && 
              (_currentPhase == AnalysisPhase.analyzing || _hasError))
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _hasError ? Colors.red.withOpacity(0.8) : Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentFeedback!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Start button
          if (_currentPhase == AnalysisPhase.idle)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  onPressed: _startAnalysis,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Analysis'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
