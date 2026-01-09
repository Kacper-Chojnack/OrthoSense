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
  // landmark indices
  static const int _nose = 0;
  static const int _lSh = 11;
  static const int _rSh = 12;
  static const int _lElb = 13;
  static const int _rElb = 14;
  static const int _lWr = 15;
  static const int _rWr = 16;
  static const int _lHip = 23;
  static const int _rHip = 24;
  static const int _lKnee = 25;
  static const int _rKnee = 26;
  static const int _lAnk = 27;
  static const int _rAnk = 28;
  static const int _lHeel = 29;
  static const int _rHeel = 30;
  static const int _lFoot = 31;
  static const int _rFoot = 32;

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

    var variant = forcedVariant;
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
    List<List<List<double>>> buf,
  ) {
    if (buf.isEmpty) return 'BOTH';

    if (exerciseName == 'Standing Shoulder Abduction') {
      var minL = double.infinity;
      var minR = double.infinity;
      var refL = double.infinity;
      var refR = double.infinity;

      for (final frame in buf) {
        final ly = frame[_lWr][1];
        final ry = frame[_rWr][1];
        final ls = frame[_lSh][1];
        final rs = frame[_rSh][1];

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
      var minLK = double.infinity;
      var minRK = double.infinity;

      for (final frame in buf) {
        final ly = frame[_lKnee][1];
        final ry = frame[_rKnee][1];
        if (ly < minLK) minLK = ly;
        if (ry < minRK) minRK = ry;
      }

      if (minLK < minRK) return 'LEFT';
      return 'RIGHT';
    }

    return 'BOTH';
  }

  DiagnosticsResult _analyzeSquat(List<List<List<double>>> data) {
    final issues = <String, dynamic>{};

    var maxHipY = double.negativeInfinity;
    List<List<double>>? deepFrame;

    for (final frame in data) {
      final hipY = (frame[_lHip][1] + frame[_rHip][1]) / 2;
      if (hipY > maxHipY) {
        maxHipY = hipY;
        deepFrame = frame;
      }
    }

    if (deepFrame == null) {
      return const DiagnosticsResult(
        isCorrect: false,
        feedback: {'No active exercise detected': true},
      );
    }

    final hipL = deepFrame[_lHip];
    final hipR = deepFrame[_rHip];
    final kneeL = deepFrame[_lKnee];
    final kneeR = deepFrame[_rKnee];
    final ankL = deepFrame[_lAnk];
    final ankR = deepFrame[_rAnk];
    final heelL = deepFrame[_lHeel];
    final heelR = deepFrame[_rHeel];
    final footL = deepFrame[_lFoot];
    final footR = deepFrame[_rFoot];
    final shL = deepFrame[_lSh];
    final shR = deepFrame[_rSh];

    final hipsY = (hipL[1] + hipR[1]) / 2;
    final kneesY = (kneeL[1] + kneeR[1]) / 2;

    if (hipsY < kneesY) {
      issues['Squat too shallow'] = true;
    }

    final kneeW = (kneeL[0] - kneeR[0]).abs();
    final ankW = (ankL[0] - ankR[0]).abs();
    if (kneeW < (ankW * 0.9)) {
      issues['Knee Valgus (Collapse)'] = true;
    }

    final heelsUp = <String>[];
    if (heelL[1] < (footL[1] - 0.03)) heelsUp.add('Left');
    if (heelR[1] < (footR[1] - 0.03)) heelsUp.add('Right');

    if (heelsUp.isNotEmpty) {
      issues['Heels rising'] = heelsUp.join(', ');
    }

    final shMidX = (shL[0] + shR[0]) / 2;
    final hipMidX = (hipL[0] + hipR[0]) / 2;
    final shift = (shMidX - hipMidX).abs();
    if (shift > 0.06) {
      issues['Asymmetrical Shift'] = shMidX > hipMidX ? 'Right' : 'Left';
    }

    final angFootL = _getFootAngle(heelL, footL);
    final angFootR = _getFootAngle(heelR, footR);
    final duckMsgs = <String>[];
    if (angFootL > 35) duckMsgs.add('Left: ${angFootL.toInt()}°');
    if (angFootR > 35) duckMsgs.add('Right: ${angFootR.toInt()}°');

    if (duckMsgs.isNotEmpty) {
      issues['Excessive Foot Turn-Out'] = duckMsgs.join(', ');
    }

    final torsoLen = (hipL[1] + hipR[1]) / 2 - (shL[1] + shR[1]) / 2;
    final shinLen = _calculateDistance(kneeL, ankL);
    if (shinLen > 0 && torsoLen < (shinLen * 0.6)) {
      issues['Excessive Forward Lean'] = true;
    }

    if (issues.isEmpty) {
      return const DiagnosticsResult(
        isCorrect: true,
        feedback: {'System': 'Movement correct.'},
      );
    }

    return DiagnosticsResult(isCorrect: false, feedback: issues);
  }

  DiagnosticsResult _analyzeHurdleStep(
    List<List<List<double>>> data, {
    String? variant,
  }) {
    final issues = <String, dynamic>{};
    final activeVar = variant ?? _detectHurdleVariant(data);

    var minKY = double.infinity;
    List<List<double>>? peakFrame;

    if (activeVar == 'LEFT') {
      for (final frame in data) {
        final ky = frame[_lKnee][1];
        if (ky < minKY) {
          minKY = ky;
          peakFrame = frame;
        }
      }
    } else {
      for (final frame in data) {
        final ky = frame[_rKnee][1];
        if (ky < minKY) {
          minKY = ky;
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

    final mKneeIdx = activeVar == 'LEFT' ? _lKnee : _rKnee;
    final mHipIdx = activeVar == 'LEFT' ? _lHip : _rHip;
    final mAnkIdx = activeVar == 'LEFT' ? _lAnk : _rAnk;
    final mFootIdx = activeVar == 'LEFT' ? _lFoot : _rFoot;

    final sKneeIdx = activeVar == 'LEFT' ? _rKnee : _lKnee;
    final sHipIdx = activeVar == 'LEFT' ? _rHip : _lHip;
    final sAnkIdx = activeVar == 'LEFT' ? _rAnk : _lAnk;

    final sHip = peakFrame[sHipIdx];
    final sKnee = peakFrame[sKneeIdx];
    final sAnk = peakFrame[sAnkIdx];

    final mHip = peakFrame[mHipIdx];
    final mKnee = peakFrame[mKneeIdx];
    final mAnk = peakFrame[mAnkIdx];
    final mFoot = peakFrame[mFootIdx];

    final shL = peakFrame[_lSh];
    final shR = peakFrame[_rSh];
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

    // pelvic stability
    final pelvW = (mHip[0] - sHip[0]).abs();
    if (pelvW > 0) {
      final tiltRatio = (sHip[1] - mHip[1]) / pelvW;
      if (tiltRatio > 0.15) {
        issues['Pelvic Hike (Compensation)'] = true;
      } else if (tiltRatio < -0.15) {
        issues['Pelvic Drop (Instability)'] = true;
      }
    }

    // stance leg valgus
    final ankHipDiff = (sAnk[1] - sHip[1]).abs();
    if (ankHipDiff > 0) {
      final ratioY = (sKnee[1] - sHip[1]) / (sAnk[1] - sHip[1]);
      final expKneeX = sHip[0] + ratioY * (sAnk[0] - sHip[0]);
      final diff = sKnee[0] - expKneeX;

      var valgus = 0.0;
      if (activeVar == 'LEFT') {
        if (diff < -0.03) valgus = diff.abs();
      } else {
        if (diff > 0.03) valgus = diff.abs();
      }
      if (valgus > 0) issues['Knee Valgus'] = true;
    }

    // trunk lean
    final spineVec2D = [shMid[0] - hipMid[0], shMid[1] - hipMid[1]];
    final normSp = _vectorNorm2D(spineVec2D);
    if (normSp > 0) {
      final vertical = [0.0, -1.0];
      final dot = spineVec2D[0] * vertical[0] + spineVec2D[1] * vertical[1];
      final cos = (dot / normSp).clamp(-1.0, 1.0);
      final angTrunk = math.acos(cos) * 180 / math.pi;
      if (angTrunk > 10) issues['Torso Instability'] = '${angTrunk.toInt()}°';
    }

    // clearance
    if (mAnk[1] > (sKnee[1] + 0.02)) issues['Step too low'] = true;

    // foot alignment
    if (activeVar == 'LEFT') {
      if (mAnk[0] > (mKnee[0] + 0.04)) issues['Foot External Rotation'] = true;
    } else {
      if (mAnk[0] < (mKnee[0] - 0.04)) issues['Foot External Rotation'] = true;
    }

    // dorsiflexion
    if (mFoot[1] > (mAnk[1] + 0.02)) {
      issues['Lack of Dorsiflexion (Toes down)'] = true;
    }

    if (issues.isEmpty) {
      return const DiagnosticsResult(
        isCorrect: true,
        feedback: {'System': 'Movement correct.'},
      );
    }

    return DiagnosticsResult(isCorrect: false, feedback: issues);
  }

  String _detectHurdleVariant(List<List<List<double>>> data) {
    var minLK = double.infinity;
    var minRK = double.infinity;

    for (final frame in data) {
      final ly = frame[_lKnee][1];
      final ry = frame[_rKnee][1];
      if (ly < minLK) minLK = ly;
      if (ry < minRK) minRK = ry;
    }

    return minLK < minRK ? 'LEFT' : 'RIGHT';
  }

  DiagnosticsResult _analyzeShoulderAbduction(
    List<List<List<double>>> data, {
    String? variant,
  }) {
    final issues = <String, dynamic>{};
    final activeVar = variant ?? 'BOTH';

    final chkL = activeVar == 'LEFT' || activeVar == 'BOTH';
    final chkR = activeVar == 'RIGHT' || activeVar == 'BOTH';

    double maxAngL = 0;
    double maxAngR = 0;
    double maxTrunkAng = 0;
    final errCnt = <String, int>{};
    var framesDone = 0;

    for (final frame in data) {
      final wrLY = frame[_lWr][1];
      final elbLY = frame[_lElb][1];
      final wrRY = frame[_rWr][1];
      final elbRY = frame[_rElb][1];

      var isActive = false;
      if (activeVar == 'LEFT') {
        if (wrLY < elbLY) isActive = true;
      } else if (activeVar == 'RIGHT') {
        if (wrRY < elbRY) isActive = true;
      } else if (activeVar == 'BOTH') {
        if (wrLY < elbLY && wrRY < elbRY) isActive = true;
      }

      if (!isActive) continue;
      framesDone++;

      final nose = frame[_nose];
      final shL = frame[_lSh];
      final shR = frame[_rSh];
      final hipMid = [
        (frame[_lHip][0] + frame[_rHip][0]) / 2,
        (frame[_lHip][1] + frame[_rHip][1]) / 2,
        (frame[_lHip][2] + frame[_rHip][2]) / 2,
      ];
      final shMid = [
        (shL[0] + shR[0]) / 2,
        (shL[1] + shR[1]) / 2,
        (shL[2] + shR[2]) / 2,
      ];
      final shW = _calculateDistance(shL, shR);

      // shrugging check
      if (shW > 0) {
        final ratioL = _calculateDistance(nose, shL) / shW;
        final ratioR = _calculateDistance(nose, shR) / shW;
        if (chkL && ratioL < 0.40) {
          errCnt['Shoulder elevation (Shrugging)'] =
              (errCnt['Shoulder elevation (Shrugging)'] ?? 0) + 1;
        }
        if (chkR && ratioR < 0.40) {
          errCnt['Shoulder elevation (Shrugging)'] =
              (errCnt['Shoulder elevation (Shrugging)'] ?? 0) + 1;
        }
      }

      // trunk lean
      final spineVec2D = [shMid[0] - hipMid[0], shMid[1] - hipMid[1]];
      final normSp = _vectorNorm2D(spineVec2D);
      if (normSp > 0) {
        final vertical = [0.0, -1.0];
        final dot = spineVec2D[0] * vertical[0] + spineVec2D[1] * vertical[1];
        final cos = (dot / normSp).clamp(-1.0, 1.0);
        final angTrunk = math.acos(cos) * 180 / math.pi;

        if (angTrunk > maxTrunkAng) maxTrunkAng = angTrunk;
        if (angTrunk > 15) {
          errCnt['Excessive trunk lean'] =
              (errCnt['Excessive trunk lean'] ?? 0) + 1;
        }
      }

      // non-working arm
      if (activeVar == 'LEFT' && wrRY < elbRY) {
        errCnt['Unstable non-working arm'] =
            (errCnt['Unstable non-working arm'] ?? 0) + 1;
      } else if (activeVar == 'RIGHT' && wrLY < elbLY) {
        errCnt['Unstable non-working arm'] =
            (errCnt['Unstable non-working arm'] ?? 0) + 1;
      }

      // arm asymmetry
      if (activeVar == 'BOTH') {
        final wrL = frame[_lWr];
        final wrR = frame[_rWr];
        if ((wrL[1] - wrR[1]).abs() > 0.15) {
          errCnt['Arm asymmetry'] = (errCnt['Arm asymmetry'] ?? 0) + 1;
        }
      }

      // ROM check
      final vertDown = [0.0, 1.0];

      if (chkL) {
        final armL = [
          frame[_lElb][0] - shL[0],
          frame[_lElb][1] - shL[1],
          frame[_lElb][2] - shL[2],
        ];
        final normL = _vectorNorm2D([armL[0], armL[1]]);
        if (normL > 0) {
          final cosL = (armL[0] * vertDown[0] + armL[1] * vertDown[1]) / normL;
          final angL = math.acos(cosL.clamp(-1.0, 1.0)) * 180 / math.pi;
          if (angL > maxAngL) maxAngL = angL;
          if (angL > 100) {
            errCnt['Arm raised too high (>100°)'] =
                (errCnt['Arm raised too high (>100°)'] ?? 0) + 1;
          }
        }
      }

      if (chkR) {
        final armR = [
          frame[_rElb][0] - shR[0],
          frame[_rElb][1] - shR[1],
          frame[_rElb][2] - shR[2],
        ];
        final normR = _vectorNorm2D([armR[0], armR[1]]);
        if (normR > 0) {
          final cosR = (armR[0] * vertDown[0] + armR[1] * vertDown[1]) / normR;
          final angR = math.acos(cosR.clamp(-1.0, 1.0)) * 180 / math.pi;
          if (angR > maxAngR) maxAngR = angR;
          if (angR > 100) {
            errCnt['Arm raised too high (>100°)'] =
                (errCnt['Arm raised too high (>100°)'] ?? 0) + 1;
          }
        }
      }
    }

    if (framesDone == 0) {
      return const DiagnosticsResult(
        isCorrect: false,
        feedback: {'No active exercise detected': true},
      );
    }

    final thresh = framesDone * 0.3;

    if ((errCnt['Shoulder elevation (Shrugging)'] ?? 0) > thresh) {
      issues['Shoulder elevation (Shrugging)'] = true;
    }
    if ((errCnt['Excessive trunk lean'] ?? 0) > thresh) {
      issues['Excessive trunk lean'] = '${maxTrunkAng.toInt()}°';
    }
    if ((errCnt['Unstable non-working arm'] ?? 0) > thresh) {
      issues['Unstable non-working arm'] = true;
    }
    if ((errCnt['Arm asymmetry'] ?? 0) > thresh) {
      issues['Arm asymmetry'] = true;
    }
    if ((errCnt['Arm raised too high (>100°)'] ?? 0) > thresh) {
      final vals = <String>[];
      if (chkL) vals.add('L:${maxAngL.toInt()}°');
      if (chkR) vals.add('R:${maxAngR.toInt()}°');
      issues['Arm raised too high (>100°)'] = vals.join(', ');
    }

    // ROM too shallow
    var shallow = false;
    final shallowVals = <String>[];
    if (activeVar == 'LEFT' && maxAngL < 80) {
      shallow = true;
      shallowVals.add('L:${maxAngL.toInt()}°');
    } else if (activeVar == 'RIGHT' && maxAngR < 80) {
      shallow = true;
      shallowVals.add('R:${maxAngR.toInt()}°');
    } else if (activeVar == 'BOTH') {
      if (maxAngL < 80) {
        shallow = true;
        shallowVals.add('L:${maxAngL.toInt()}°');
      }
      if (maxAngR < 80) {
        shallow = true;
        shallowVals.add('R:${maxAngR.toInt()}°');
      }
    }
    if (shallow) issues['Movement too shallow (<80°)'] = shallowVals.join(', ');

    if (issues.isEmpty) {
      return const DiagnosticsResult(
        isCorrect: true,
        feedback: {'System': 'Movement correct.'},
      );
    }

    return DiagnosticsResult(isCorrect: false, feedback: issues);
  }

  static final Map<String, String> _adviceMap = {
    // squat
    'Squat too shallow': 'Lower hips until thighs are parallel to floor.',
    'Knee Valgus (Collapse)': "Push knees out - don't let them cave in.",
    'Heels rising': 'Keep heels planted. Work on ankle mobility.',
    'Asymmetrical Shift': 'Distribute weight evenly on both legs.',
    'Excessive Foot Turn-Out': 'Point feet more forward (limit ~30°).',
    'Excessive Forward Lean': 'Keep chest up, engage core.',

    // hurdle
    'Pelvic Hike (Compensation)': 'Keep hips level - use hip flexors.',
    'Pelvic Drop (Instability)': 'Engage core/glutes on stance leg.',
    'Knee Valgus': 'Keep stance knee aligned with foot.',
    'Torso Instability': 'Stay upright, avoid swaying.',
    'Step too low': 'Raise knee higher.',
    'Foot External Rotation': 'Keep moving foot pointing forward.',
    'Lack of Dorsiflexion (Toes down)': 'Pull toes up as you lift leg.',

    // shoulder
    'Shoulder elevation (Shrugging)': 'Keep shoulders down and relaxed.',
    'Excessive trunk lean': 'Stand tall, avoid side lean.',
    'Unstable non-working arm': 'Keep resting arm still.',
    'Arm asymmetry': 'Move both arms at same speed/height.',
    'Arm raised too high (>100°)': 'Stop around 90° - parallel to floor.',
    'Movement too shallow (<80°)': 'Raise arms a bit higher.',
  };

  double _calculateAngle(List<double> a, List<double> b, List<double> c) {
    final ba = [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
    final bc = [c[0] - b[0], c[1] - b[1], c[2] - b[2]];

    final denom = _vectorNorm(ba) * _vectorNorm(bc);
    if (denom == 0) return 0;

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
    if (norm == 0) return 0;
    final dot = vec[0] * vertical[0] + vec[1] * vertical[1];
    final cosine = (dot / norm).clamp(-1.0, 1.0);
    return math.acos(cosine) * 180 / math.pi;
  }

  double _vectorNorm2D(List<double> v) {
    return math.sqrt(v[0] * v[0] + v[1] * v[1]);
  }

  String generateReport(DiagnosticsResult res, String exerciseName) {
    final buf = StringBuffer()..writeln('Exercise: $exerciseName');

    // filter idle message
    final filtered = Map<String, dynamic>.from(res.feedback)
      ..remove('No active exercise detected');

    if (res.isCorrect || filtered.isEmpty) {
      buf
        ..writeln('Status: Movement correct.')
        ..writeln('Good job!');
    } else {
      buf.writeln('Status: Needs work.\n');
      buf.writeln('Issues:');
      for (final e in filtered.entries) {
        buf.writeln(e.value == true ? '• ${e.key}' : '• ${e.key}: ${e.value}');
      }

      final tips = <String>[];
      for (final k in filtered.keys) {
        tips.add(_adviceMap[k] ?? 'Focus on: $k');
      }
      if (tips.isNotEmpty) {
        buf.writeln('\nTips:');
        for (final t in tips) {
          buf.writeln('• $t');
        }
      }
    }

    return buf.toString();
  }
}
