import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as ml_kit;
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart'
    show PoseLandmark, PoseFrame, PoseLandmarks;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class PoseDetectionService {
  PoseDetectionService() {
    _initializeDetector();
  }

  ml_kit.PoseDetector? _streamDetector;
  ml_kit.PoseDetector? _singleDetector;
  bool _isInitialized = false;

  void _initializeDetector() {
    if (_isInitialized) return;

    final streamOptions = ml_kit.PoseDetectorOptions(
      model: ml_kit.PoseDetectionModel.base,
      mode: ml_kit.PoseDetectionMode.stream,
    );

    final singleOptions = ml_kit.PoseDetectorOptions(
      model: ml_kit.PoseDetectionModel.base,
      mode: ml_kit.PoseDetectionMode.single,
    );

    _streamDetector = ml_kit.PoseDetector(options: streamOptions);
    _singleDetector = ml_kit.PoseDetector(options: singleOptions);
    _isInitialized = true;
  }

  Future<PoseLandmarks> extractLandmarksFromVideo(
    File videoFile, {
    ValueChanged<double>? onProgress,
  }) async {
    if (!_isInitialized) _initializeDetector();

    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    final duration = controller.value.duration;
    final fps = 30.0;
    await controller.dispose();

    final frames = <PoseFrame>[];

    final frameSkip = duration.inSeconds > 10 ? 3 : 2;
    final stepMs = ((1000 / fps) * frameSkip).round();
    final totalFrames = (duration.inMilliseconds / stepMs).ceil();
    int processedFrames = 0;

    if (kDebugMode) {
      debugPrint(
        '[VideoPose] durationMs=${duration.inMilliseconds} fps=$fps '
        'frameSkip=$frameSkip stepMs=$stepMs totalFrames=$totalFrames',
      );
    }

    double fingerprint = 0.0;

    for (int frameIdx = 0; frameIdx < totalFrames; frameIdx++) {
      final positionMs = (frameIdx * stepMs).clamp(0, duration.inMilliseconds);
      try {
        final thumbnailPath = await vt.VideoThumbnail.thumbnailFile(
          video: videoFile.path,
          imageFormat: vt.ImageFormat.PNG,
          timeMs: positionMs,
          quality: 100,
          maxWidth: 480,
        );

        if (thumbnailPath != null) {
          final thumbnailFile = File(thumbnailPath);
          if (await thumbnailFile.exists()) {
            final landmarks = await _detectPoseFromFile(thumbnailFile);
            if (landmarks != null) {
              frames.add(landmarks);

              if (kDebugMode && frames.length <= 10) {
                const idxs = [0, 11, 12, 23, 24, 25, 26];
                for (final idx in idxs) {
                  if (idx < landmarks.landmarks.length) {
                    final p = landmarks.landmarks[idx];
                    fingerprint +=
                        (p.x * 1000.0) + (p.y * 10000.0) + (p.z * 100000.0);
                  }
                }
              }
            }
            try {
              await thumbnailFile.delete();
            } catch (_) {}
          }
        }

        processedFrames++;
        final progress = (processedFrames / totalFrames).clamp(0.0, 1.0);
        onProgress?.call(progress);
      } catch (e) {
        debugPrint('Error processing frame at ${positionMs}ms: $e');
      }
    }

    if (frames.isEmpty) throw Exception('No pose detected in video');

    if (kDebugMode) {
      debugPrint(
        '[VideoPose] detectedFrames=${frames.length}/${totalFrames} '
        'fingerprint10=${fingerprint.toStringAsFixed(3)}',
      );
    }

    return PoseLandmarks(frames: frames, fps: fps);
  }

  Future<PoseFrame?> _detectPoseFromFile(File imageFile) async {
    if (_singleDetector == null) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final ui.Image image = await decodeImageFromList(bytes);
      double width = image.width.toDouble();
      double height = image.height.toDouble();
      image.dispose();

      final inputImage = ml_kit.InputImage.fromFilePath(imageFile.path);
      final poses = await _singleDetector!.processImage(inputImage);
      if (poses.isEmpty) return null;

      if (width > height) {
        final temp = width;
        width = height;
        height = temp;
      }

      final mappedLandmarks = _mapMlKitToMediaPipe(
        poses.first,
        width,
        height,
        false,
      );
      return PoseFrame(landmarks: mappedLandmarks);
    } catch (e) {
      debugPrint('Error detecting pose: $e');
      return null;
    }
  }

  Future<PoseFrame?> detectPoseFromCameraImage(
    CameraImage image,
    CameraDescription description,
  ) async {
    if (_streamDetector == null) return null;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final inputImageFormat =
          ml_kit.InputImageFormatValue.fromRawValue(image.format.raw) ??
          ml_kit.InputImageFormat.nv21;
      final rotation =
          ml_kit.InputImageRotationValue.fromRawValue(
            description.sensorOrientation,
          ) ??
          ml_kit.InputImageRotation.rotation0deg;

      final inputImageData = ml_kit.InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = ml_kit.InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );

      final poses = await _streamDetector!.processImage(inputImage);
      if (poses.isEmpty) return null;

      double width = image.width.toDouble();
      double height = image.height.toDouble();

      if (width > height) {
        final temp = width;
        width = height;
        height = temp;
      }

      final isFrontCamera =
          description.lensDirection == CameraLensDirection.front;

      final mappedLandmarks = _mapMlKitToMediaPipe(
        poses.first,
        width,
        height,
        isFrontCamera,
      );

      return PoseFrame(landmarks: mappedLandmarks);
    } catch (e) {
      debugPrint('Error detecting pose from camera: $e');
      return null;
    }
  }

  bool checkPoseVisibility(PoseFrame frame) {
    if (frame.landmarks.isEmpty) return false;
    const requiredIndices = [11, 12, 23, 24, 25, 26, 27, 28];
    int visibleCount = 0;
    for (var idx in requiredIndices) {
      if (idx < frame.landmarks.length) {
        final p = frame.landmarks[idx];
        if (p.x != 0 && p.y != 0) {
          visibleCount++;
        }
      }
    }
    return visibleCount >= 6;
  }

  List<PoseLandmark> _mapMlKitToMediaPipe(
    ml_kit.Pose pose,
    double width,
    double height,
    bool isFrontCamera,
  ) {
    final landmarks = <PoseLandmark>[];
    final mlKitLandmarks = pose.landmarks;

    PoseLandmark? getLandmark(ml_kit.PoseLandmarkType type) {
      final mlKitLandmark = mlKitLandmarks[type];
      if (mlKitLandmark != null) {
        double normalizedX = mlKitLandmark.x / width;
        double normalizedY = mlKitLandmark.y / height;
        double normalizedZ = mlKitLandmark.z / width;

        return PoseLandmark(
          x: normalizedX,
          y: normalizedY,
          z: normalizedZ,
        );
      }
      return null;
    }

    //0: nose
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.nose) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //1-3: left eye
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftEyeInner) ??
          getLandmark(ml_kit.PoseLandmarkType.leftEye) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftEye) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftEyeOuter) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //4-6: right eye
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightEyeInner) ??
          getLandmark(ml_kit.PoseLandmarkType.rightEye) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightEye) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightEyeOuter) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //7-8: ears
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftEar) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightEar) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftMouth) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightMouth) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //11-12: shoulders
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftShoulder) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightShoulder) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //13-14: elbows
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftElbow) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightElbow) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //15-16: wrists
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftWrist) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightWrist) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //17-18: pinky
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftPinky) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightPinky) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //19-20: index
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftIndex) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightIndex) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //21-22: thumb
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftThumb) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightThumb) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //23-24: hips
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftHip) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightHip) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //25-26: knees
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftKnee) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightKnee) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //27-28: ankles
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftAnkle) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightAnkle) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //29-30: heels
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftHeel) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightHeel) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    //31-32: foot index
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.leftFootIndex) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );
    landmarks.add(
      getLandmark(ml_kit.PoseLandmarkType.rightFootIndex) ??
          PoseLandmark(x: 0, y: 0, z: 0),
    );

    return landmarks;
  }

  Future<void> dispose() async {
    await _streamDetector?.close();
    await _singleDetector?.close();
    _streamDetector = null;
    _singleDetector = null;
    _isInitialized = false;
  }
}
