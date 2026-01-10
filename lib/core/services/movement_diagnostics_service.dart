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

  DiagnosticsResult diagnose(
    String exerciseName,
    PoseLandmarks landmarks, {
    String? forcedVariant,
  }) {
    if (landmarks.isEmpty) {
      return const DiagnosticsResult(
        isCorrect: false,
        feedback: {'No active exercise detected': true},
      );
    }

    final skeletonData = landmarks.frames
        .map(
          (frame) => frame.landmarks.map((lm) => [lm.x, lm.y, lm.z]).toList(),
        )
        .toList();

    String? variant = forcedVariant;
    if (variant == null &&
        (exerciseName == 'Standing Shoulder Abduction' ||
            exerciseName == 'Hurdle Step')) {
      variant = detectVariant(exerciseName, skeletonData);
    }

    switch (exerciseName) {
      case 'Deep Squat':
        return _analyzeSquat(skeletonData);
      case 'Hurdle Step':
        return _analyzeHurdleStep(skeletonData, variant: variant);
      case 'Standing Shoulder Abduction':
        return _analyzeShoulderAbduction(skeletonData, variant: variant);
      default:
        return const DiagnosticsResult(
          isCorrect: true,
          feedback: {'Analysis not available for this exercise': true},
        );
    }
  }

  String detectVariant(
    String exerciseName,
    List<List<List<double>>> bufferData,
  ) {
    if (bufferData.isEmpty) {
      return 'BOTH';
    }

    if (exerciseName == 'Standing Shoulder Abduction') {
      double minL = double.infinity;
      double minR = double.infinity;
      double refL = double.infinity;
      double refR = double.infinity;

      for (final frame in bufferData) {
        final ly = frame[_leftWrist][1];
        final ry = frame[_rightWrist][1];
        final ls = frame[_leftShoulder][1];
        final rs = frame[_rightShoulder][1];

        if (ly < minL) minL = ly;
        if (ry < minR) minR = ry;
        if (ls < refL) refL = ls;
        if (rs < refR) refR = rs;
      }

      final lActive = minL < refL;
      final rActive = minR < refR;

      if (lActive && rActive) return 'BOTH';
      if (lActive) return 'LEFT';
      if (rActive) return 'RIGHT';
      return 'BOTH';
    } else if (exerciseName == 'Hurdle Step') {
      double minLKnee = double.infinity;
      double minRKnee = double.infinity;

      for (final frame in bufferData) {
        final ly = frame[_leftKnee][1];
        final ry = frame[_rightKnee][1];
        if (ly < minLKnee) minLKnee = ly;
        if (ry < minRKnee) minRKnee = ry;
      }

      if (minLKnee < minRKnee) return 'LEFT';
      return 'RIGHT';
    }

    return 'BOTH';
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
        feedback: {'No active exercise detected': true},
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
      errors['Squat too shallow'] = true;
    }

    final kneeWidth = (kneeL[0] - kneeR[0]).abs();
    final ankleWidth = (ankleL[0] - ankleR[0]).abs();
    if (kneeWidth < (ankleWidth * 0.9)) {
      errors['Knee Valgus (Collapse)'] = true;
    }

    final heelsUp = <String>[];
    if (heelL[1] < (footL[1] - 0.03)) heelsUp.add('Left');
    if (heelR[1] < (footR[1] - 0.03)) heelsUp.add('Right');

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
      errors['Excessive Foot Turn-Out'] = duckFeetMsgs.join(', ');
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

  DiagnosticsResult _analyzeHurdleStep(
    List<List<List<double>>> skeletonData, {
    String? variant,
  }) {
    final errors = <String, dynamic>{};

    final activeVariant = variant ?? _detectHurdleVariant(skeletonData);

    double minKneeY = double.infinity;
    List<List<double>>? peakFrame;

    if (activeVariant == 'LEFT') {
      for (final frame in skeletonData) {
        final kneeY = frame[_leftKnee][1];
        if (kneeY < minKneeY) {
          minKneeY = kneeY;
          peakFrame = frame;
        }
      }
    } else {
      for (final frame in skeletonData) {
        final kneeY = frame[_rightKnee][1];
        if (kneeY < minKneeY) {
          minKneeY = kneeY;
          peakFrame = frame;
        }
      }
    }

    if (peakFrame == null) {
      return const DiagnosticsResult(
        isCorrect: false,
        feedback: {'No active exercise detected': true},
      );
    }

    final movingKneeIdx = activeVariant == 'LEFT' ? _leftKnee : _rightKnee;
    final movingHipIdx = activeVariant == 'LEFT' ? _leftHip : _rightHip;
    final movingAnkleIdx = activeVariant == 'LEFT' ? _leftAnkle : _rightAnkle;
    final movingFootIdx = activeVariant == 'LEFT'
        ? _leftFootIndex
        : _rightFootIndex;

    final stanceKneeIdx = activeVariant == 'LEFT' ? _rightKnee : _leftKnee;
    final stanceHipIdx = activeVariant == 'LEFT' ? _rightHip : _leftHip;
    final stanceAnkleIdx = activeVariant == 'LEFT' ? _rightAnkle : _leftAnkle;

    final sHip = peakFrame[stanceHipIdx];
    final sKnee = peakFrame[stanceKneeIdx];
    final sAnkle = peakFrame[stanceAnkleIdx];

    final mHip = peakFrame[movingHipIdx];
    final mKnee = peakFrame[movingKneeIdx];
    final mAnkle = peakFrame[movingAnkleIdx];
    final mFoot = peakFrame[movingFootIdx];

    final shL = peakFrame[_leftShoulder];
    final shR = peakFrame[_rightShoulder];
    final shMid = [
      (shL[0] + shR[0]) / 2,
      (shL[1] + shR[1]) / 2,
      (shL[2] + shR[2]) / 2,
    ];
    final hipMid = [
      (sHip[0] + mHip[0]) / 2,
      (sHip[1] + mHip[1]) / 2,
      (sHip[2] + mHip[2]) / 2,
    ];

    //Pelvic stability
    final pelvisVec = [mHip[0] - sHip[0], mHip[1] - sHip[1], mHip[2] - sHip[2]];
    final pelvisWidth = (pelvisVec[0]).abs();
    if (pelvisWidth > 0) {
      final tiltRatio = (sHip[1] - mHip[1]) / pelvisWidth;
      if (tiltRatio > 0.15) {
        errors['Pelvic Hike (Compensation)'] = true;
      } else if (tiltRatio < -0.15) {
        errors['Pelvic Drop (Instability)'] = true;
      }
    }

    //Knee valgus (stance leg)
    final ankleHipDiff = (sAnkle[1] - sHip[1]).abs();
    if (ankleHipDiff > 0) {
      final ratioY = (sKnee[1] - sHip[1]) / (sAnkle[1] - sHip[1]);
      final expectedKneeX = sHip[0] + ratioY * (sAnkle[0] - sHip[0]);

      final diff = sKnee[0] - expectedKneeX;
      double valgusDev = 0.0;

      if (activeVariant == 'LEFT') {
        if (diff < -0.03) valgusDev = diff.abs();
      } else {
        if (diff > 0.03) valgusDev = diff.abs();
      }

      if (valgusDev > 0) {
        errors['Knee Valgus'] = true;
      }
    }

    //Torso lean
    final spineVec = [
      shMid[0] - hipMid[0],
      shMid[1] - hipMid[1],
      shMid[2] - hipMid[2],
    ];
    final spineVec2D = [spineVec[0], spineVec[1]];
    final normSpine = _vectorNorm2D(spineVec2D);
    if (normSpine > 0) {
      final vertical = [0.0, -1.0];
      final dot = spineVec2D[0] * vertical[0] + spineVec2D[1] * vertical[1];
      final cosine = (dot / normSpine).clamp(-1.0, 1.0);
      final angleTrunk = math.acos(cosine) * 180 / math.pi;
      if (angleTrunk > 10) {
        errors['Torso Instability'] = '${angleTrunk.toInt()}°';
      }
    }

    //Clearance check
    if (mAnkle[1] > (sKnee[1] + 0.02)) {
      errors['Step too low'] = true;
    }

    //Foot alignment
    if (activeVariant == 'LEFT') {
      if (mAnkle[0] > (mKnee[0] + 0.04)) {
        errors['Foot External Rotation'] = true;
      }
    } else {
      if (mAnkle[0] < (mKnee[0] - 0.04)) {
        errors['Foot External Rotation'] = true;
      }
    }

    //Dorsiflexion check
    if (mFoot[1] > (mAnkle[1] + 0.02)) {
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

  String _detectHurdleVariant(List<List<List<double>>> skeletonData) {
    double minLKnee = double.infinity;
    double minRKnee = double.infinity;

    for (final frame in skeletonData) {
      final ly = frame[_leftKnee][1];
      final ry = frame[_rightKnee][1];
      if (ly < minLKnee) minLKnee = ly;
      if (ry < minRKnee) minRKnee = ry;
    }

    if (minLKnee < minRKnee) return 'LEFT';
    return 'RIGHT';
  }

  DiagnosticsResult _analyzeShoulderAbduction(
    List<List<List<double>>> skeletonData, {
    String? variant,
  }) {
    final errors = <String, dynamic>{};

    final activeVariant = variant ?? 'BOTH';

    final checkLeft = activeVariant == 'LEFT' || activeVariant == 'BOTH';
    final checkRight = activeVariant == 'RIGHT' || activeVariant == 'BOTH';

    double maxAngleL = 0;
    double maxAngleR = 0;
    double maxTrunkAngle = 0;
    final errorCounts = <String, int>{};

    int framesAnalyzed = 0;

    for (final frame in skeletonData) {
      final wristLY = frame[_leftWrist][1];
      final elbowLY = frame[_leftElbow][1];
      final wristRY = frame[_rightWrist][1];
      final elbowRY = frame[_rightElbow][1];

      bool isActive = false;
      if (activeVariant == 'LEFT') {
        if (wristLY < elbowLY) isActive = true;
      } else if (activeVariant == 'RIGHT') {
        if (wristRY < elbowRY) isActive = true;
      } else if (activeVariant == 'BOTH') {
        if (wristLY < elbowLY && wristRY < elbowRY) isActive = true;
      }

      if (!isActive) continue;

      framesAnalyzed++;

      final nose = frame[_nose];
      final shL = frame[_leftShoulder];
      final shR = frame[_rightShoulder];
      final hipMid = [
        (frame[_leftHip][0] + frame[_rightHip][0]) / 2,
        (frame[_leftHip][1] + frame[_rightHip][1]) / 2,
        (frame[_leftHip][2] + frame[_rightHip][2]) / 2,
      ];
      final shMid = [
        (shL[0] + shR[0]) / 2,
        (shL[1] + shR[1]) / 2,
        (shL[2] + shR[2]) / 2,
      ];
      final shoulderWidth = _calculateDistance(shL, shR);

      //Shrugging
      if (shoulderWidth > 0) {
        final distRatioLeft = _calculateDistance(nose, shL) / shoulderWidth;
        final distRatioRight = _calculateDistance(nose, shR) / shoulderWidth;
        if (checkLeft && distRatioLeft < 0.40) {
          errorCounts['Shoulder elevation (Shrugging)'] =
              (errorCounts['Shoulder elevation (Shrugging)'] ?? 0) + 1;
        }
        if (checkRight && distRatioRight < 0.40) {
          errorCounts['Shoulder elevation (Shrugging)'] =
              (errorCounts['Shoulder elevation (Shrugging)'] ?? 0) + 1;
        }
      }

      //Trunk lean
      final spineVec = [
        shMid[0] - hipMid[0],
        shMid[1] - hipMid[1],
        shMid[2] - hipMid[2],
      ];
      final spineVec2D = [spineVec[0], spineVec[1]];
      final normSpine = _vectorNorm2D(spineVec2D);
      if (normSpine > 0) {
        final vertical = [0.0, -1.0];
        final dot = spineVec2D[0] * vertical[0] + spineVec2D[1] * vertical[1];
        final cosine = (dot / normSpine).clamp(-1.0, 1.0);
        final angleTrunk = math.acos(cosine) * 180 / math.pi;

        if (angleTrunk > maxTrunkAngle) {
          maxTrunkAngle = angleTrunk;
        }

        if (angleTrunk > 15) {
          errorCounts['Excessive trunk lean'] =
              (errorCounts['Excessive trunk lean'] ?? 0) + 1;
        }
      }

      //Non-working arm movement
      if (activeVariant == 'LEFT' && wristRY < elbowRY) {
        errorCounts['Unstable non-working arm'] =
            (errorCounts['Unstable non-working arm'] ?? 0) + 1;
      } else if (activeVariant == 'RIGHT' && wristLY < elbowLY) {
        errorCounts['Unstable non-working arm'] =
            (errorCounts['Unstable non-working arm'] ?? 0) + 1;
      }

      //Arm asymmetry
      if (activeVariant == 'BOTH') {
        final wrL = frame[_leftWrist];
        final wrR = frame[_rightWrist];
        if ((wrL[1] - wrR[1]).abs() > 0.15) {
          errorCounts['Arm asymmetry'] =
              (errorCounts['Arm asymmetry'] ?? 0) + 1;
        }
      }

      //Range of motion safety check
      final verticalDown = [0.0, 1.0];

      if (checkLeft) {
        final armVecL = [
          frame[_leftElbow][0] - shL[0],
          frame[_leftElbow][1] - shL[1],
          frame[_leftElbow][2] - shL[2],
        ];
        final normL = _vectorNorm2D([armVecL[0], armVecL[1]]);
        if (normL > 0) {
          final cosL =
              (armVecL[0] * verticalDown[0] + armVecL[1] * verticalDown[1]) /
              normL;
          final angleL = math.acos(cosL.clamp(-1.0, 1.0)) * 180 / math.pi;

          if (angleL > maxAngleL) {
            maxAngleL = angleL;
          }

          if (angleL > 100) {
            errorCounts['Arm raised too high (>100°)'] =
                (errorCounts['Arm raised too high (>100°)'] ?? 0) + 1;
          }
        }
      }

      if (checkRight) {
        final armVecR = [
          frame[_rightElbow][0] - shR[0],
          frame[_rightElbow][1] - shR[1],
          frame[_rightElbow][2] - shR[2],
        ];
        final normR = _vectorNorm2D([armVecR[0], armVecR[1]]);
        if (normR > 0) {
          final cosR =
              (armVecR[0] * verticalDown[0] + armVecR[1] * verticalDown[1]) /
              normR;
          final angleR = math.acos(cosR.clamp(-1.0, 1.0)) * 180 / math.pi;

          if (angleR > maxAngleR) {
            maxAngleR = angleR;
          }

          if (angleR > 100) {
            errorCounts['Arm raised too high (>100°)'] =
                (errorCounts['Arm raised too high (>100°)'] ?? 0) + 1;
          }
        }
      }
    }

    if (framesAnalyzed == 0) {
      return const DiagnosticsResult(
        isCorrect: false,
        feedback: {'No active exercise detected': true},
      );
    }

    final threshold = framesAnalyzed * 0.3;

    if ((errorCounts['Shoulder elevation (Shrugging)'] ?? 0) > threshold) {
      errors['Shoulder elevation (Shrugging)'] = true;
    }

    if ((errorCounts['Excessive trunk lean'] ?? 0) > threshold) {
      errors['Excessive trunk lean'] = '${maxTrunkAngle.toInt()}°';
    }

    if ((errorCounts['Unstable non-working arm'] ?? 0) > threshold) {
      errors['Unstable non-working arm'] = true;
    }

    if ((errorCounts['Arm asymmetry'] ?? 0) > threshold) {
      errors['Arm asymmetry'] = true;
    }

    if ((errorCounts['Arm raised too high (>100°)'] ?? 0) > threshold) {
      final vals = <String>[];
      if (checkLeft) vals.add('L:${maxAngleL.toInt()}°');
      if (checkRight) vals.add('R:${maxAngleR.toInt()}°');
      errors['Arm raised too high (>100°)'] = vals.join(', ');
    }

    bool romTooShallow = false;
    final valsShallow = <String>[];
    if (activeVariant == 'LEFT' && maxAngleL < 80) {
      romTooShallow = true;
      valsShallow.add('L:${maxAngleL.toInt()}°');
    } else if (activeVariant == 'RIGHT' && maxAngleR < 80) {
      romTooShallow = true;
      valsShallow.add('R:${maxAngleR.toInt()}°');
    } else if (activeVariant == 'BOTH') {
      if (maxAngleL < 80) {
        romTooShallow = true;
        valsShallow.add('L:${maxAngleL.toInt()}°');
      }
      if (maxAngleR < 80) {
        romTooShallow = true;
        valsShallow.add('R:${maxAngleR.toInt()}°');
      }
    }

    if (romTooShallow) {
      errors['Movement too shallow (<80°)'] = valsShallow.join(', ');
    }

    if (errors.isEmpty) {
      return const DiagnosticsResult(
        isCorrect: true,
        feedback: {'System': 'Movement correct.'},
      );
    }

    return DiagnosticsResult(isCorrect: false, feedback: errors);
  }

  static final Map<String, String> _adviceMap = {
    //Deep Squat
    'Squat too shallow':
        'Try to lower your hips further until your thighs are at least parallel to the floor.',
    'Knee Valgus (Collapse)':
        'Focus on pushing your knees outward to align with your toes. Do not let them cave in.',
    'Heels rising':
        'Keep your heels firmly planted on the ground throughout the movement. Work on ankle mobility.',
    'Asymmetrical Shift':
        'Ensure you are distributing your weight evenly on both legs. Avoid shifting to one side.',
    'Excessive Foot Turn-Out':
        'Try to point your feet more forward (ideal limit is ~30°). Excessive rotation can strain your knees.',
    'Excessive Forward Lean':
        'Keep your chest up and your back straight. Engage your core to stay more upright.',

    //Hurdle Step
    'Pelvic Hike (Compensation)':
        'Keep your hips level. Don\'t hike your hip up to lift the leg; use your hip flexors.',
    'Pelvic Drop (Instability)':
        'Engage your core and glutes on the standing leg to keep your pelvis stable and level.',
    'Knee Valgus':
        'Keep your standing knee stable and aligned with your foot. Don\'t let it collapse inward.',
    'Torso Instability':
        'Keep your torso upright and tall. Avoid swaying side-to-side to maintain balance.',
    'Step too low':
        'Try to raise your knee higher. Imagine stepping over a real hurdle.',
    'Foot External Rotation':
        'Keep your moving foot pointing forward as you step over, avoiding outward rotation.',
    'Lack of Dorsiflexion (Toes down)':
        'Pull your toes up towards your shin (flex your foot) as you lift your leg.',

    //Standing Shoulder Abduction
    'Shoulder elevation (Shrugging)':
        'Keep your shoulders down and relaxed. Avoid shrugging them up towards your ears.',
    'Excessive trunk lean':
        'Stand tall with a neutral spine. Avoid leaning your body to the side to help lift the arm.',
    'Unstable non-working arm':
        'Keep your resting arm still and relaxed by your side.',
    'Arm asymmetry': 'Focus on moving both arms at the same speed and height.',
    'Arm raised too high (>100°)':
        'Stop the movement when your arms are parallel to the floor or slightly above (approx. 90°).',
    'Movement too shallow (<80°)':
        'Try to raise your arms a bit higher to reach the full target range of motion.',
  };

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

    final filteredFeedback = Map<String, dynamic>.from(result.feedback);
    filteredFeedback.remove('No active exercise detected');

    if (result.isCorrect || filteredFeedback.isEmpty) {
      buffer.writeln('Status: Movement correct.');
      buffer.writeln('Conclusion: Excellent form! Keep it up.');
    } else {
      buffer.writeln('Status: Technique needs improvement.');

      buffer.writeln('\nDetected Issues:');
      for (final entry in filteredFeedback.entries) {
        if (entry.value == true) {
          buffer.writeln('• ${entry.key}');
        } else {
          buffer.writeln('• ${entry.key}: ${entry.value}');
        }
      }

      final adviceList = <String>[];

      for (final key in filteredFeedback.keys) {
        if (_adviceMap.containsKey(key)) {
          adviceList.add(_adviceMap[key]!);
        } else {
          adviceList.add('Focus on correcting: $key.');
        }
      }
      if (adviceList.isNotEmpty) {
        buffer.writeln('\nRecommendations:');
        for (final advice in adviceList) {
          buffer.writeln('• $advice');
        }
      }
    }

    return buffer.toString();
  }
}
