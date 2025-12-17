import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/camera/domain/repositories/camera_repository.dart';
import 'package:orthosense/features/camera/presentation/providers/camera_controller.dart';
import 'package:orthosense/features/camera/presentation/providers/camera_state.dart';
import 'package:orthosense/features/vision/presentation/widgets/ar_overlay_widget.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera screen displaying live preview.
/// Handles permissions, initialization, and lifecycle management.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize camera after first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(cameraControllerProvider.notifier);

    // Handle app lifecycle to properly manage camera resources
    if (state == AppLifecycleState.inactive) {
      controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      controller.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          if (cameraState is CameraStateReady)
            IconButton(
              icon: Icon(
                cameraState.lensDirection == CameraLensDirection.back
                    ? Icons.camera_front
                    : Icons.camera_rear,
              ),
              onPressed: () {
                ref.read(cameraControllerProvider.notifier).switchCamera();
              },
              tooltip: 'Switch Camera',
            ),
        ],
      ),
      body: _buildBody(context, cameraState),
    );
  }

  Widget _buildBody(BuildContext context, CameraState state) {
    return state.when(
      initial: () => _buildLoading('Preparing camera...'),
      requestingPermission: () => _buildLoading('Requesting permission...'),
      permissionDenied: (status) => _buildPermissionDenied(context, status),
      initializing: () => _buildLoading('Initializing camera...'),
      ready: (lensDirection) => _buildCameraPreview(context),
      error: (message, code) => _buildError(context, message, code),
      disposed: () => _buildLoading('Camera stopped'),
    );
  }

  Widget _buildLoading(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(
    BuildContext context,
    CameraPermissionStatus status,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPermanent = status == CameraPermissionStatus.permanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_photography,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isPermanent
                  ? 'Camera permission was permanently denied. '
                      'Please enable it in Settings to use this feature.'
                  : 'OrthoSense needs camera access to analyze your '
                      'movements during exercises.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            if (isPermanent)
              FilledButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  ref.read(cameraControllerProvider.notifier).initialize();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    final controller = ref.read(cameraControllerProvider.notifier);
    final previewWidget = controller.previewWidget;

    // If using real camera, display native preview
    if (previewWidget is cam.CameraPreview) {
      return Stack(
        fit: StackFit.expand,
        children: [
          previewWidget,
          const AROverlayWidget(showDebugInfo: true),
          _buildOverlay(context),
        ],
      );
    }

    // Mock camera - display placeholder with frame info
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildMockPreview(context),
        const AROverlayWidget(showDebugInfo: true),
        _buildOverlay(context),
      ],
    );
  }

  Widget _buildMockPreview(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Mock Camera Active',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            _buildFrameCounter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameCounter() {
    return StreamBuilder<int>(
      stream: ref
          .read(cameraControllerProvider.notifier)
          .frameStream
          .map((_) => 1)
          .fold<int>(0, (acc, _) => acc + 1)
          .asStream(),
      builder: (context, snapshot) {
        return Text(
          'Frames: ${snapshot.data ?? 0}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        );
      },
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Position yourself in frame',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, String? code) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (code != null) ...[
              const SizedBox(height: 8),
              Text(
                'Code: $code',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.read(cameraControllerProvider.notifier).initialize();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
