import 'dart:math' as math;
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart';

class DiagnosticsResult {
  const DiagnosticsResult({
    required this.isCorrect,
    required this.feedback,
  });

  final bool isCorrect;
  final Map<String, dynamic> feedback;
}

class MovementDiagnosticsService {
  static const int _nose = 0;
  static const int _leftShoulder = 11;
  static const int _rightShoulder = 12;
  static const int _leftElbow = 13;
  static const int _rightElbow = 14;
  static const int _leftWrist = 15;
  static const int _rightWrist = 16;
  static const int _leftHip = 23;
  static const int _rightHip = 24;
  static const int _leftKnee = 25;
  static const int _rightKnee = 26;
  static const int _leftAnkle = 27;
  static const int _rightAnkle = 28;
  static const int _leftHeel = 29;
  static const int _rightHeel = 30;
  static const int _leftFootIndex = 31;
  static const int _rightFootIndex = 32;

  DiagnosticsResult diagnose(String exerciseName, PoseLandmarks landmarks) {
    if (landmarks.isEmpty) {
      return const DiagnosticsResult(
        isCorrect: false,
        feedback: {'System': 'No data provided'},
      );
    }

    final skeletonData = landmarks.frames
        .map((frame) => frame.landmarks.map((lm) => [lm.x, lm.y, lm.z]).toList())
        .toList();

    switch (exerciseName) {
      case 'Deep Squat':
        return _analyzeSquat(skeletonData);
      case 'Hurdle Step':
        return _analyzeHurdleStep(skeletonData);
      case 'Standing Shoulder Abduction':
        return _analyzeShoulderAbduction(skeletonData);
      default:
        return const DiagnosticsResult(
          isCorrect: true,
          feedback: {'System': 'No specific analysis available for this exercise'},
        );
    }
  }

  DiagnosticsResult _analyzeSquat(List<List<List<double>>> skeletonData) {
    final errors = <String, dynamic>{};

    double maxHipY = double.negativeInfinity;
    List<List<double>>? deepestFrame;

    for (final frame in skeletonData) {
      final hipY = (frame[_leftHip][1] + frame[_rightHip][1]) / 2;
      if (hipY > maxHipY) {
        maxHipY = hipY;
        deepestFrame = frame;
      }
    }

    if (deepestFrame == null) {
      return const DiagnosticsResult(
        isCorrect: false,
        feedback: {'System': 'No movement detected'},
      );
    }

    final hipL = deepestFrame[_leftHip];
    final hipR = deepestFrame[_rightHip];
    final kneeL = deepestFrame[_leftKnee];
    final kneeR = deepestFrame[_rightKnee];
    final ankleL = deepestFrame[_leftAnkle];
    final ankleR = deepestFrame[_rightAnkle];
    final heelL = deepestFrame[_leftHeel];
    final heelR = deepestFrame[_rightHeel];
    final footL = deepestFrame[_leftFootIndex];
    final footR = deepestFrame[_rightFootIndex];
    final shL = deepestFrame[_leftShoulder];
    final shR = deepestFrame[_rightShoulder];

    final hipsYAvg = (hipL[1] + hipR[1]) / 2;
    final kneesYAvg = (kneeL[1] + kneeR[1]) / 2;
    if (hipsYAvg < kneesYAvg) {
      errors['Squat too shallow'] = 'Hips did not descend below knees';
    }

    final kneeWidth = (kneeL[0] - kneeR[0]).abs();
    final ankleWidth = (ankleL[0] - ankleR[0]).abs();
    if (kneeWidth < (ankleWidth * 0.9)) {
      errors['Knee Valgus (Collapse)'] = true;
    }

    final heelsUp = <String>[];
    if (heelL[1] < (footL[1] - 0.03)) heelsUp.add('L');
    if (heelR[1] < (footR[1] - 0.03)) heelsUp.add('R');
    if (heelsUp.isNotEmpty) {
      errors['Heels rising'] = heelsUp.join(', ');
    }

    final shoulderMidX = (shL[0] + shR[0]) / 2;
    final hipMidX = (hipL[0] + hipR[0]) / 2;
    final shift = (shoulderMidX - hipMidX).abs();
    if (shift > 0.06) {
      final direction = shoulderMidX > hipMidX ? 'Right' : 'Left';
      errors['Asymmetrical Shift'] = direction;
    }

    final angleFootL = _getFootAngle(heelL, footL);
    final angleFootR = _getFootAngle(heelR, footR);
    final duckFeetMsgs = <String>[];
    if (angleFootL > 35) duckFeetMsgs.add('Left: ${angleFootL.toInt()}°');
    if (angleFootR > 35) duckFeetMsgs.add('Right: ${angleFootR.toInt()}°');
    if (duckFeetMsgs.isNotEmpty) {
      errors['Excessive Foot Turn-Out (Limit ~30°)'] = duckFeetMsgs.join(', ');
    }

    final torsoVerticalLen = (hipL[1] + hipR[1]) / 2 - (shL[1] + shR[1]) / 2;
    final shinLen = _calculateDistance(kneeL, ankleL);
    if (shinLen > 0 && torsoVerticalLen < (shinLen * 0.6)) {
      errors['Excessive Forward Lean'] = true;
    }

    if (errors.isEmpty) {
      return const DiagnosticsResult(
        isCorrect: true,
        feedback: {'System': 'Movement correct.'},
      );
    }

    return DiagnosticsResult(isCorrect: false, feedback: errors);
  }

  DiagnosticsResult _analyzeHurdleStep(List<List<List<double>>> skeletonData) {
    final errors = <String, dynamic>{};

    double maxKneeY = double.negativeInfinity;
    List<List<double>>? highestFrame;

    for (final frame in skeletonData) {
      final kneeY = math.max(frame[_leftKnee][1], frame[_rightKnee][1]);
      if (kneeY > maxKneeY) {
        maxKneeY = kneeY;
        highestFrame = frame;
      }
    }

    if (highestFrame == null) {
      return const DiagnosticsResult(
        isCorrect: false,
        feedback: {'System': 'No movement detected'},
      );
    }

    final hipL = highestFrame[_leftHip];
    final hipR = highestFrame[_rightHip];
    final kneeL = highestFrame[_leftKnee];
    final kneeR = highestFrame[_rightKnee];
    final ankleL = highestFrame[_leftAnkle];
    final ankleR = highestFrame[_rightAnkle];

    final leftKneeHigher = kneeL[1] > kneeR[1];
    final liftedHip = leftKneeHigher ? hipL : hipR;
    final supportHip = leftKneeHigher ? hipR : hipL;
    final liftedKnee = leftKneeHigher ? kneeL : kneeR;
    final supportAnkle = leftKneeHigher ? ankleR : ankleL;

    final hipHeightDiff = (liftedHip[1] - supportHip[1]).abs();
    if (hipHeightDiff > 0.05) {
      errors['Pelvic Hike (Compensation)'] = true;
    }

    final supportHeel = leftKneeHigher ? highestFrame[_rightHeel] : highestFrame[_leftHeel];
    final supportFoot = leftKneeHigher ? highestFrame[_rightFootIndex] : highestFrame[_leftFootIndex];
    final footAngle = _getFootAngle(supportHeel, supportFoot);
    if (footAngle > 30) {
      errors['Foot External Rotation'] = true;
    }

    final ankleKneeAngle = _calculateAngle(supportAnkle, supportHip, liftedKnee);
    if (ankleKneeAngle < 80) {
      errors['Lack of Dorsiflexion (Toes down)'] = true;
    }

    if (errors.isEmpty) {
      return const DiagnosticsResult(
        isCorrect: true,
        feedback: {'System': 'Movement correct.'},
      );
    }

    return DiagnosticsResult(isCorrect: false, feedback: errors);
  }

  DiagnosticsResult _analyzeShoulderAbduction(List<List<List<double>>> skeletonData) {
    final errors = <String, dynamic>{};

    double maxWristY = double.negativeInfinity;
    List<List<double>>? highestFrame;

    for (final frame in skeletonData) {
      final wristY = math.min(frame[_leftWrist][1], frame[_rightWrist][1]);
      if (wristY < maxWristY || maxWristY == double.negativeInfinity) {
        maxWristY = wristY;
        highestFrame = frame;
      }
    }

    if (highestFrame == null) {
      return const DiagnosticsResult(
        isCorrect: false,
        feedback: {'System': 'No movement detected'},
      );
    }

    final shL = highestFrame[_leftShoulder];
    final shR = highestFrame[_rightShoulder];
    final elbowL = highestFrame[_leftElbow];
    final elbowR = highestFrame[_rightElbow];
    final wristL = highestFrame[_leftWrist];
    final wristR = highestFrame[_rightWrist];

    final angleL = _calculateAngle(shL, elbowL, wristL);
    final angleR = _calculateAngle(shR, elbowR, wristR);

    final shallowMsgs = <String>[];
    if (angleL < 80) shallowMsgs.add('L:${angleL.toInt()}°');
    if (angleR < 80) shallowMsgs.add('R:${angleR.toInt()}°');

    if (shallowMsgs.isNotEmpty) {
      errors['Movement too shallow (<80°)'] = shallowMsgs.join(', ');
    }

    if (errors.isEmpty) {
      return const DiagnosticsResult(
        isCorrect: true,
        feedback: {'System': 'Movement correct.'},
      );
    }

    return DiagnosticsResult(isCorrect: false, feedback: errors);
  }

  double _calculateAngle(List<double> a, List<double> b, List<double> c) {
    final ba = [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
    final bc = [c[0] - b[0], c[1] - b[1], c[2] - b[2]];

    final denom = _vectorNorm(ba) * _vectorNorm(bc);
    if (denom == 0) return 0.0;

    final dot = ba[0] * bc[0] + ba[1] * bc[1] + ba[2] * bc[2];
    final cosine = (dot / denom).clamp(-1.0, 1.0);
    return math.acos(cosine) * 180 / math.pi;
  }

  double _calculateDistance(List<double> a, List<double> b) {
    final dx = a[0] - b[0];
    final dy = a[1] - b[1];
    final dz = a[2] - b[2];
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  double _vectorNorm(List<double> v) {
    return math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
  }

  double _getFootAngle(List<double> heel, List<double> toe) {
    final vec = [toe[0] - heel[0], toe[1] - heel[1]];
    final vertical = [0.0, 1.0];
    final norm = _vectorNorm2D(vec);
    if (norm == 0) return 0.0;
    final dot = vec[0] * vertical[0] + vec[1] * vertical[1];
    final cosine = (dot / norm).clamp(-1.0, 1.0);
    return math.acos(cosine) * 180 / math.pi;
  }

  double _vectorNorm2D(List<double> v) {
    return math.sqrt(v[0] * v[0] + v[1] * v[1]);
  }

  String generateReport(DiagnosticsResult result, String exerciseName) {
    final buffer = StringBuffer();
    buffer.writeln('Exercise Analysis: $exerciseName');

    if (result.isCorrect) {
      buffer.writeln('Status: Movement correct.');
      buffer.writeln('Conclusion: Excellent form! Keep it up.');
    } else {
      buffer.writeln('Status: Technique needs improvement.');
      buffer.writeln('');
      buffer.writeln('DETECTED ERRORS:');

      for (final entry in result.feedback.entries) {
        if (entry.value == true) {
          buffer.writeln('- ${entry.key}');
        } else {
          buffer.writeln('- ${entry.key}: ${entry.value}');
        }
      }

      buffer.writeln('');
      buffer.writeln('Recommendation: Lower intensity and focus on correcting these specific patterns.');
    }

    return buffer.toString();
  }
}

