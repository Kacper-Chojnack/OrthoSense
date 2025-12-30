import 'package:json_annotation/json_annotation.dart';

part 'pose_landmarks.g.dart';

@JsonSerializable()
class PoseLandmark {
  const PoseLandmark({
    required this.x,
    required this.y,
    required this.z,
    this.visibility = 1.0,
  });

  final double x;

  final double y;

  final double z;

  final double visibility;

  List<double> toList({bool includeVisibility = true}) => 
      includeVisibility ? [x, y, z, visibility] : [x, y, z];

  factory PoseLandmark.fromList(List<double> coords) {
    return PoseLandmark(
      x: coords[0],
      y: coords[1],
      z: coords.length > 2 ? coords[2] : 0.0,
    );
  }

  factory PoseLandmark.fromJson(Map<String, dynamic> json) =>
      _$PoseLandmarkFromJson(json);

  Map<String, dynamic> toJson() => _$PoseLandmarkToJson(this);
}

@JsonSerializable()
class PoseFrame {
  const PoseFrame({required this.landmarks});

  final List<PoseLandmark> landmarks;

  List<List<double>> toBackendFormat({bool includeVisibility = true}) {
    return landmarks.map((lm) => lm.toList(includeVisibility: includeVisibility)).toList();
  }

  factory PoseFrame.fromBackendFormat(List<List<double>> data) {
    return PoseFrame(
      landmarks: data.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  }

  factory PoseFrame.fromJson(Map<String, dynamic> json) =>
      _$PoseFrameFromJson(json);

  Map<String, dynamic> toJson() => _$PoseFrameToJson(this);
}

@JsonSerializable()
class PoseLandmarks {
  const PoseLandmarks({
    required this.frames,
    this.fps = 30.0,
  });

  final List<PoseFrame> frames;

  final double fps;

  List<List<List<double>>> toBackendFormat() {
    return frames.map((frame) => frame.toBackendFormat()).toList();
  }

  factory PoseLandmarks.fromBackendFormat(
    List<List<List<double>>> data, {
    double fps = 30.0,
  }) {
    return PoseLandmarks(
      frames: data.map((frame) => PoseFrame.fromBackendFormat(frame)).toList(),
      fps: fps,
    );
  }

  int get frameCount => frames.length;

  bool get isEmpty => frames.isEmpty;

  bool get isNotEmpty => frames.isNotEmpty;

  factory PoseLandmarks.fromJson(Map<String, dynamic> json) =>
      _$PoseLandmarksFromJson(json);

  Map<String, dynamic> toJson() => _$PoseLandmarksToJson(this);
}

