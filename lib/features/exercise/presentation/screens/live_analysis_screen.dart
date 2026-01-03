import 'dart:async';
import 'dart:io'; 
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
      _debugPose = null;
      _lastSmoothedPose = null;
    });

    _controller!.startImageStream(_processCameraFrame).catchError((error) {
      debugPrint('Error starting image stream: $error');
      _handleError('Failed to start camera stream');
    });

    _phaseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _currentPhase == AnalysisPhase.setup) {
        setState(() {
          _currentPhase = AnalysisPhase.calibrationClassification;
        });
        _phaseTimer = Timer(const Duration(seconds: 10), () {
          _performClassification();
        });
      }
    });
  }

  Future<void> _performClassification() async {
    debugPrint('[Classification] Starting classification with ${_calibrationVotes.length} votes');
    
    if (_calibrationVotes.isEmpty) {
      _handleError('No exercise detected. Ensure full body is visible.');
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
      _handleError('No exercise detected with sufficient confidence.');
      return;
    }

    final votingConfidence = maxVotes / _calibrationVotes.length;
    debugPrint('[Classification] Winner: $winnerExercise ($maxVotes votes)');

    if (votingConfidence < 0.3) {
      _handleError('Exercise detection uncertain. Please try again.');
      return;
    }

    if (mounted) {
      setState(() {
        _detectedExercise = winnerExercise;
        _currentPhase = AnalysisPhase.calibrationVariant;
      });

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

      smoothedLandmarks.add(PoseLandmark(
        x: smoothedX,
        y: smoothedY,
        z: smoothedZ,
      ));
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
          _sourceImageSize = Size(image.width.toDouble(), image.height.toDouble());
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

      if (_currentPhase == AnalysisPhase.analyzing && _visibilityBuffer.length >= _visibilityWindowSize) {
        final visibleCount = _visibilityBuffer.where((v) => v).length;
        final visibilityRatio = visibleCount / _visibilityBuffer.length;

        if (visibilityRatio < _minVisibilityRatio) {
          if (mounted) {
            setState(() {
              _currentFeedback = 'Insufficient body visibility';
              _hasError = true;
            });
          }
          return;
        } else {
          if (mounted && _currentFeedback == 'Insufficient body visibility') {
            setState(() {
              _currentFeedback = null;
              _hasError = false;
            });
          }
        }
      }

      if (_rawBuffer.length == _windowSize && _frameCount % _predictionInterval == 0) {
        if (isVisible) {
          if (_currentPhase == AnalysisPhase.calibrationClassification) {
            await _analyzeCalibrationFrame();
          } else if (_currentPhase == AnalysisPhase.analyzing) {
            await _analyzeFrame();
          }
        } else {
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

      if (mounted && _currentPhase == AnalysisPhase.analyzing) {
        setState(() {
          if (_currentFeedback != 'Insufficient body visibility' &&
              _currentFeedback != 'Please ensure full body is visible') {
            _hasError = !result.isCorrect;
            if (result.isCorrect) {
              _currentFeedback = 'Good job';
            } else {
              final firstError = result.feedback.keys.first;
              String errorMsg = firstError;
              if (errorMsg.contains('°')) {
                errorMsg = errorMsg.split('°').first.trim();
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
    setState(() {
      _debugPose = null;
    });
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
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Center(
                                child: CameraPreview(_controller!),
                              ),
                              if (_debugPose != null && _sourceImageSize != null)
                                CustomPaint(
                                  painter: PosePainter(
                                    pose: _debugPose!,
                                    imageSize: _sourceImageSize!,
                                    isFrontCamera: _controller!.description.lensDirection ==
                                        CameraLensDirection.front,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            )
          else
            const Center(child: CircularProgressIndicator()),

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

class PosePainter extends CustomPainter {
  final PoseFrame pose;
  final Size imageSize;
  final bool isFrontCamera;

  static const List<List<int>> connections = [
    [11, 12], 
    [11, 13], [13, 15], 
    [12, 14], [14, 16], 
    [11, 23], [12, 24], 
    [23, 24], 
    [23, 25], [25, 27], 
    [24, 26], [26, 28], 
  ];

  static const List<int> allowedLandmarks = [
    11, 12, 13, 14, 15, 16, 
    23, 24, 25, 26, 27, 28  
  ];

  PosePainter({
    required this.pose,
    required this.imageSize,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose.landmarks.isEmpty) return;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;

    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green;

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
    
    bool mirrorX = false; 
    // if (isFrontCamera) mirrorX = true; 

    Offset getPoint(int index) {
      if (index >= pose.landmarks.length) return Offset.zero;
      
      final landmark = pose.landmarks[index];
      double x = landmark.x * contentWidth + offsetX;
      double y = landmark.y * contentHeight + offsetY;

      if (mirrorX) {
        x = size.width - x; 
      }
      return Offset(x, y);
    }

    for (final pair in connections) {
      if (pair[0] < pose.landmarks.length && pair[1] < pose.landmarks.length) {
        final start = getPoint(pair[0]);
        final end = getPoint(pair[1]);
        
        if (start != Offset.zero && end != Offset.zero) {
           canvas.drawLine(start, end, linePaint);
        }
      }
    }

    for (final index in allowedLandmarks) {
      if (index < pose.landmarks.length) {
        final point = getPoint(index);
        if (point != Offset.zero) {
          canvas.drawCircle(point, 4.0, jointPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose;
  }
}