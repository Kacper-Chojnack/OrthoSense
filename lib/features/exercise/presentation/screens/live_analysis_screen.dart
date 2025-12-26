import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:orthosense/core/providers/tts_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Real-time exercise analysis screen with camera feed and AI feedback.
class LiveAnalysisScreen extends ConsumerStatefulWidget {
  const LiveAnalysisScreen({
    required this.useFrontCamera,
    this.exerciseName,
    super.key,
  });

  final String? exerciseName;
  final bool useFrontCamera;

  @override
  ConsumerState<LiveAnalysisScreen> createState() => _LiveAnalysisScreenState();
}

class _LiveAnalysisScreenState extends ConsumerState<LiveAnalysisScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSubscription;
  Timer? _frameTimer;

  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _isProcessingFrame = false;
  bool _isConnected = false;

  String _feedback = '';
  String _lastVoiceMessage = '';
  bool _isCorrect = true;
  int _framesBuffered = 0;
  int _framesNeeded = 30;

  String _connectionStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _stopAnalysis();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initialize() async {
    await _initializeCamera();
    _connectWebSocket();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }

      final targetDirection = widget.useFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == targetDirection,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitialized = true;
      });
    } catch (e) {
      _showError('Camera initialization failed: $e');
    }
  }

  void _connectWebSocket() {
    try {
      final wsUrl = _getWebSocketUrl();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _wsSubscription = _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: (Object error) {
          debugPrint('WebSocket error: $error');
          if (!mounted) return;
          setState(() {
            _connectionStatus = 'Connection error';
            _isConnected = false;
          });
        },
        onDone: () {
          debugPrint('WebSocket closed');
          if (!mounted) return;
          setState(() {
            _connectionStatus = 'Disconnected';
            _isConnected = false;
          });
        },
      );

      setState(() {
        _connectionStatus = 'Connected';
        _isConnected = true;
      });

      final exerciseData = widget.exerciseName != null
          ? {'exercise': widget.exerciseName}
          : <String, dynamic>{};
      _sendCommand('start', exerciseData);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = 'Failed to connect';
      });
      _showError('WebSocket connection failed: $e');
    }
  }

  String _getWebSocketUrl() {
    const host = String.fromEnvironment(
      'WS_HOST',
      defaultValue: '192.168.0.23',
    );
    const port = String.fromEnvironment(
      'WS_PORT',
      defaultValue: '8000',
    );

    final clientId = DateTime.now().millisecondsSinceEpoch.toString();
    return 'ws://$host:$port/api/v1/analysis/ws/$clientId';
  }

  void _handleWebSocketMessage(dynamic message) {
    if (!mounted) return;

    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;

      final status = data['status'] as String?;
      final feedback = data['feedback'] as String?;
      final voiceMessage = data['voice_message'] as String?;
      final isCorrect = data['is_correct'] as bool?;
      final framesBuffered = data['frames_buffered'] as int?;
      final framesNeeded = data['frames_needed'] as int?;

      setState(() {
        if (feedback != null && feedback.isNotEmpty) {
          _feedback = feedback;
        }
        if (isCorrect != null) {
          _isCorrect = isCorrect;
        }
        if (framesBuffered != null) {
          _framesBuffered = framesBuffered;
        }
        if (framesNeeded != null) {
          _framesNeeded = framesNeeded;
        }

        if (status == 'buffering') {
          _feedback = 'Analyzing... $_framesBuffered/$_framesNeeded frames';
        } else if (status == 'no_pose') {
          _feedback = 'Position yourself in the camera view';
        } else if (status == 'started') {
          final exerciseText = widget.exerciseName ?? 'your exercise';
          _feedback = 'Get ready to perform $exerciseText';
        }
      });

      if (voiceMessage != null &&
          voiceMessage.isNotEmpty &&
          voiceMessage != _lastVoiceMessage) {
        _lastVoiceMessage = voiceMessage;
        ref.read(ttsServiceProvider).speak(voiceMessage);
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _sendCommand(String action, [Map<String, dynamic>? extra]) {
    if (_channel == null) return;

    final payload = {'action': action, ...?extra};
    _channel!.sink.add(jsonEncode(payload));
  }

  void _startAnalysis() {
    if (!_isInitialized || _isAnalyzing) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _isAnalyzing = true;
      _feedback = 'Starting analysis...';
    });

    DateTime? lastProcessed;
    controller.startImageStream((CameraImage image) {
      if (!_isAnalyzing || _isProcessingFrame) return;

      final now = DateTime.now();
      if (lastProcessed != null &&
          now.difference(lastProcessed!).inMilliseconds < 150) {
        return;
      }
      lastProcessed = now;

      _processImageStream(image);
    });
  }

  void _stopAnalysis() {
    _cameraController?.stopImageStream();
    _frameTimer?.cancel();
    _frameTimer = null;

    setState(() {
      _isAnalyzing = false;
    });

    _sendCommand('stop');
  }

  Future<void> _processImageStream(CameraImage image) async {
    if (_isProcessingFrame || _channel == null) return;

    _isProcessingFrame = true;

    try {
      final jpegBytes = await _convertImageToJpeg(image);
      if (jpegBytes != null && jpegBytes.isNotEmpty) {
        _channel?.sink.add(jpegBytes);
      }
    } catch (e) {
      debugPrint('Error processing image stream: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<Uint8List?> _convertImageToJpeg(CameraImage image) async {
    try {
      final img.Image? imgImage = _convertCameraImageToImage(image);
      if (imgImage == null) return null;

      final jpegBytes = Uint8List.fromList(
        img.encodeJpg(imgImage, quality: 85),
      );
      return jpegBytes;
    } catch (e) {
      debugPrint('Error converting image: $e');
      return null;
    }
  }

  img.Image? _convertCameraImageToImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToImage(cameraImage);
      }
      return null;
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yBuffer = cameraImage.planes[0].bytes;
    final uBuffer = cameraImage.planes[1].bytes;
    final vBuffer = cameraImage.planes[2].bytes;

    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      final yp = y * yRowStride;
      final uvRowStart = (y ~/ 2) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final uvIndex = uvRowStart + (x ~/ 2) * uvPixelStride;
        final yIndex = yp + x;

        final yVal = yBuffer[yIndex];
        final u = uBuffer[uvIndex];
        final v = vBuffer[uvIndex];

        final r = (yVal + 1.402 * (v - 128)).clamp(0, 255).toInt();
        final g = (yVal - 0.344 * (u - 128) - 0.714 * (v - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yVal + 1.772 * (u - 128)).clamp(0, 255).toInt();

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }

  img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final buffer = cameraImage.planes[0].bytes;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = (y * width + x) * 4;
        final b = buffer[index];
        final g = buffer[index + 1];
        final r = buffer[index + 2];
        final a = buffer[index + 3];

        image.setPixelRgba(x, y, r, g, b, a);
      }
    }

    return image;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frameTimer?.cancel();
    _wsSubscription?.cancel();
    _cameraController?.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isInitialized && _cameraController != null)
              Positioned.fill(
                child: _cameraController!.value.isInitialized
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          var scale =
                              size.aspectRatio *
                              _cameraController!.value.aspectRatio;

                          if (scale < 1) scale = 1 / scale;

                          return Transform.scale(
                            scale: scale,
                            child: Center(
                              child: CameraPreview(_cameraController!),
                            ),
                          );
                        },
                      )
                    : const Center(child: CircularProgressIndicator()),
              )
            else
              const Center(child: CircularProgressIndicator()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(context, colorScheme),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomOverlay(context, theme, colorScheme),
            ),
            if (_isAnalyzing)
              Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: _buildFeedbackBanner(colorScheme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Image.asset(
              'assets/images/logo.png',
              height: 24,
              color: Colors.white,
            ),
            onPressed: () {
              _stopAnalysis();
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.exerciseName ?? 'Detecting Exercise...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Image.asset(
              'assets/images/logo.png',
              height: 24,
              color: Colors.white,
            ),
            onPressed: null,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _isCorrect
            ? Colors.green.withValues(alpha: 0.9)
            : Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 28,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _feedback.isNotEmpty ? _feedback : 'Analyzing...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAnalyzing) ...[
            LinearProgressIndicator(
              value: _framesNeeded > 0 ? _framesBuffered / _framesNeeded : 0,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isCorrect ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Frames: $_framesBuffered',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                label: 'Audio',
                onPressed: () {
                  final tts = ref.read(ttsServiceProvider);
                  final isMuted = tts.state.value.isMuted;
                  tts.setMuted(muted: !isMuted);
                },
              ),
              _buildMainButton(colorScheme),
              _buildControlButton(
                label: 'Guide',
                onPressed: _showInstructions,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Image.asset(
            'assets/images/logo.png',
            height: 28,
            color: Colors.white,
          ),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _isConnected
          ? (_isAnalyzing ? _stopAnalysis : _startAnalysis)
          : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isAnalyzing ? Colors.red : colorScheme.primary,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: (_isAnalyzing ? Colors.red : colorScheme.primary)
                  .withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/logo.png',
          height: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showInstructions() {
    final exerciseTitle = widget.exerciseName != null
        ? 'Tips for ${widget.exerciseName}'
        : 'General Tips';
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Image.asset('assets/images/logo.png', height: 24),
              title: const Text('Make sure your full body is visible'),
            ),
            ListTile(
              leading: Image.asset('assets/images/logo.png', height: 24),
              title: const Text('Good lighting helps AI detection'),
            ),
            ListTile(
              leading: Image.asset('assets/images/logo.png', height: 24),
              title: const Text('Stand 2-3 meters from the camera'),
            ),
            ListTile(
              leading: Image.asset('assets/images/logo.png', height: 24),
              title: const Text('Wear fitted clothing for better tracking'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
