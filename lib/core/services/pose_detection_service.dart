import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as ml_kit;
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart'
    show PoseLandmark, PoseFrame, PoseLandmarks;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class PoseDetectionService {
  PoseDetectionService() {
    _initializeDetector();
  }

  ml_kit.PoseDetector? _detector;
  bool _isInitialized = false;

  void _initializeDetector() {
    if (_isInitialized) return;

    final options = ml_kit.PoseDetectorOptions(
      model: ml_kit.PoseDetectionModel.base,
    );

    _detector = ml_kit.PoseDetector(options: options);
    _isInitialized = true;
  }

  Future<PoseLandmarks> extractLandmarksFromVideo(
    File videoFile, {
    ValueChanged<double>? onProgress,
  }) async {
    if (!_isInitialized) {
      _initializeDetector();
    }

    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    final duration = controller.value.duration;
    final fps = 30.0; 
    await controller.dispose();

    final frames = <PoseFrame>[];
    
    final frameSkip = duration.inSeconds > 10 ? 3 : 2; 
    final stepMs = ((1000 / 30) * frameSkip).round();
    
    final totalFrames = (duration.inMilliseconds / stepMs).ceil();
    int processedFrames = 0;

    for (int positionMs = 0;
        positionMs < duration.inMilliseconds;
        positionMs += stepMs) {
      try {
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoFile.path,
          imageFormat: ImageFormat.JPEG,
          timeMs: positionMs,
          quality: 50,
          maxWidth: 480, 
        );

        if (thumbnailPath != null) {
          final thumbnailFile = File(thumbnailPath);
          if (await thumbnailFile.exists()) {
            final landmarks = await _detectPoseFromFile(thumbnailFile);
            if (landmarks != null) {
              frames.add(landmarks);
            }
            try {
              await thumbnailFile.delete();
            } catch (e) {
              debugPrint('Error deleting thumbnail: $e');
            }
          }
        }

        processedFrames++;
        final progress = (processedFrames / totalFrames).clamp(0.0, 1.0);
        onProgress?.call(progress);
      } catch (e) {
        debugPrint('Error processing frame at ${positionMs}ms: $e');
      }
    }

    if (frames.isEmpty) {
      throw Exception('No pose detected in video');
    }

    return PoseLandmarks(frames: frames, fps: fps);
  }

  Future<PoseFrame?> _detectPoseFromFile(File imageFile) async {
    if (_detector == null) return null;

    try {
      final inputImage = ml_kit.InputImage.fromFilePath(imageFile.path);
      final poses = await _detector!.processImage(inputImage);
      if (poses.isEmpty) return null;

      final pose = poses.first;
      final mappedLandmarks = _mapMlKitToMediaPipe(pose);

      return PoseFrame(landmarks: mappedLandmarks);
    } catch (e) {
      debugPrint('Error detecting pose: $e');
      return null;
    }
  }

  List<PoseLandmark> _mapMlKitToMediaPipe(ml_kit.Pose pose) {
    final landmarks = <PoseLandmark>[];
    final mlKitLandmarks = pose.landmarks;

    PoseLandmark? getLandmark(ml_kit.PoseLandmarkType type) {
      final mlKitLandmark = mlKitLandmarks[type];
      if (mlKitLandmark != null) {
        return PoseLandmark(
          x: mlKitLandmark.x,
          y: mlKitLandmark.y,
          z: mlKitLandmark.z,
          visibility: mlKitLandmark.likelihood, 
        );
      }
      return null;
    }
    
    //0: nose
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.nose) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //1-3: left eye
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftEyeInner) ??
        getLandmark(ml_kit.PoseLandmarkType.leftEye) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftEye) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftEyeOuter) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //4-6: right eye
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightEyeInner) ??
        getLandmark(ml_kit.PoseLandmarkType.rightEye) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightEye) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightEyeOuter) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //7-8: ears
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftEar) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightEar) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //9-10: mouth 
    final nose = getLandmark(ml_kit.PoseLandmarkType.nose);
    landmarks.add(nose ?? const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(nose ?? const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //11-12: shoulders
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftShoulder) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightShoulder) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //13-14: elbows
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftElbow) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightElbow) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //15-16: wrists
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftWrist) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightWrist) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //17-18: pinky
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftPinky) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightPinky) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //19-20: index
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftIndex) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightIndex) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //21-22: thumb
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftThumb) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightThumb) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //23-24: hips
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftHip) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightHip) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //25-26: knees
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftKnee) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightKnee) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //27-28: ankles
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftAnkle) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightAnkle) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //29-30: heels
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftHeel) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightHeel) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    //31-32: foot index
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.leftFootIndex) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));
    landmarks.add(getLandmark(ml_kit.PoseLandmarkType.rightFootIndex) ??
        const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0));

    assert(landmarks.length == 33, 'Expected 33 landmarks, got ${landmarks.length}');
    return landmarks;
  }

  Future<void> dispose() async {
    await _detector?.close();
    _isInitialized = false;
  }
}