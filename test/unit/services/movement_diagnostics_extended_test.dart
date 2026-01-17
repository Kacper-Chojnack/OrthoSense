/// Extended unit tests for MovementDiagnosticsService.
///
/// Additional test coverage for:
/// 1. More edge cases in squat analysis
/// 2. All error detection paths in hurdle step
/// 3. All error detection paths in shoulder abduction
/// 4. Report generation with various feedback types
/// 5. Helper functions
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/movement_diagnostics_service.dart';
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart';

void main() {
  late MovementDiagnosticsService service;

  setUp(() {
    service = MovementDiagnosticsService();
  });

  group('Deep Squat - Additional Edge Cases', () {
    test('detects asymmetrical shift to right', () {
      final landmarks = _createAsymmetricalShiftSquatLandmarks('right');
      final result = service.diagnose('Deep Squat', landmarks);

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Asymmetrical Shift'), isTrue);
    });

    test('detects asymmetrical shift to left', () {
      final landmarks = _createAsymmetricalShiftSquatLandmarks('left');
      final result = service.diagnose('Deep Squat', landmarks);

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Asymmetrical Shift'), isTrue);
    });

    test('detects excessive foot turn-out (duck feet)', () {
      final landmarks = _createDuckFeetSquatLandmarks();
      final result = service.diagnose('Deep Squat', landmarks);

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Excessive Foot Turn-Out'), isTrue);
    });

    test('detects excessive forward lean', () {
      final landmarks = _createForwardLeanSquatLandmarks();
      final result = service.diagnose('Deep Squat', landmarks);

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Excessive Forward Lean'), isTrue);
    });

    test('detects left heel rising only', () {
      final landmarks = _createLeftHeelRiseSquatLandmarks();
      final result = service.diagnose('Deep Squat', landmarks);

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Heels rising'), isTrue);
      expect(result.feedback['Heels rising'].toString(), contains('Left'));
    });

    test('detects right heel rising only', () {
      final landmarks = _createRightHeelRiseSquatLandmarks();
      final result = service.diagnose('Deep Squat', landmarks);

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Heels rising'), isTrue);
      expect(result.feedback['Heels rising'].toString(), contains('Right'));
    });

    test('detects multiple errors simultaneously', () {
      final landmarks = _createMultipleErrorSquatLandmarks();
      final result = service.diagnose('Deep Squat', landmarks);

      expect(result.isCorrect, isFalse);
      // Should detect at least 2 errors
      final errorCount =
          result.feedback.keys.where((k) => k != 'System').length;
      expect(errorCount, greaterThanOrEqualTo(2));
    });
  });

  group('Hurdle Step - Additional Edge Cases', () {
    test('detects pelvic hike compensation', () {
      final landmarks = _createPelvicHikeHurdleLandmarks();
      final result = service.diagnose(
        'Hurdle Step',
        landmarks,
        forcedVariant: 'LEFT',
      );

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Pelvic Hike (Compensation)'), isTrue);
    });

    test('detects pelvic drop instability', () {
      final landmarks = _createPelvicDropHurdleLandmarks();
      final result = service.diagnose(
        'Hurdle Step',
        landmarks,
        forcedVariant: 'LEFT',
      );

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Pelvic Drop (Instability)'), isTrue);
    });

    test('detects knee valgus on stance leg', () {
      final landmarks = _createKneeValgusHurdleLandmarks();
      final result = service.diagnose(
        'Hurdle Step',
        landmarks,
        forcedVariant: 'LEFT',
      );

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Knee Valgus'), isTrue);
    });

    test('detects foot external rotation', () {
      final landmarks = _createFootExternalRotationHurdleLandmarks();
      final result = service.diagnose(
        'Hurdle Step',
        landmarks,
        forcedVariant: 'LEFT',
      );

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Foot External Rotation'), isTrue);
    });

    test('detects lack of dorsiflexion (toes down)', () {
      final landmarks = _createToesDownHurdleLandmarks();
      final result = service.diagnose(
        'Hurdle Step',
        landmarks,
        forcedVariant: 'LEFT',
      );

      expect(result.isCorrect, isFalse);
      expect(
        result.feedback.containsKey('Lack of Dorsiflexion (Toes down)'),
        isTrue,
      );
    });

    test('auto-detects variant without forcedVariant', () {
      final landmarks = _createCorrectHurdleStepLandmarks('LEFT');
      final result = service.diagnose('Hurdle Step', landmarks);

      // Should still analyze without error
      expect(result, isNotNull);
    });
  });

  group('Shoulder Abduction - Additional Edge Cases', () {
    test('detects unstable non-working arm for LEFT variant', () {
      final landmarks = _createUnstableNonWorkingArmLandmarks('LEFT');
      final result = service.diagnose(
        'Standing Shoulder Abduction',
        landmarks,
        forcedVariant: 'LEFT',
      );

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Unstable non-working arm'), isTrue);
    });

    test('detects unstable non-working arm for RIGHT variant', () {
      final landmarks = _createUnstableNonWorkingArmLandmarks('RIGHT');
      final result = service.diagnose(
        'Standing Shoulder Abduction',
        landmarks,
        forcedVariant: 'RIGHT',
      );

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Unstable non-working arm'), isTrue);
    });

    test('detects arm asymmetry for BOTH variant', () {
      final landmarks = _createArmAsymmetryLandmarks();
      final result = service.diagnose(
        'Standing Shoulder Abduction',
        landmarks,
        forcedVariant: 'BOTH',
      );

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Arm asymmetry'), isTrue);
    });

    test('detects arm raised too high (>100°)', () {
      final landmarks = _createArmTooHighLandmarks();
      final result = service.diagnose(
        'Standing Shoulder Abduction',
        landmarks,
        forcedVariant: 'BOTH',
      );

      expect(result.isCorrect, isFalse);
      expect(result.feedback.containsKey('Arm raised too high (>100°)'), isTrue);
    });

    test('detects movement too shallow (<80°)', () {
      final landmarks = _createShallowAbductionLandmarks();
      final result = service.diagnose(
        'Standing Shoulder Abduction',
        landmarks,
        forcedVariant: 'BOTH',
      );

      expect(result.isCorrect, isFalse);
      expect(
        result.feedback.containsKey('Movement too shallow (<80°)'),
        isTrue,
      );
    });

    test('returns no active exercise when arms not raised', () {
      final landmarks = _createNeutralLandmarks();
      final result = service.diagnose(
        'Standing Shoulder Abduction',
        landmarks,
        forcedVariant: 'BOTH',
      );

      expect(result.isCorrect, isFalse);
      expect(
        result.feedback.containsKey('No active exercise detected'),
        isTrue,
      );
    });
  });

  group('Report Generation - Extended Tests', () {
    test('generates report for movement with multiple errors', () {
      final result = DiagnosticsResult(
        isCorrect: false,
        feedback: {
          'Squat too shallow': true,
          'Knee Valgus (Collapse)': true,
          'Heels rising': 'Left, Right',
        },
      );

      final report = service.generateReport(result, 'Deep Squat');

      expect(report, contains('Exercise Analysis: Deep Squat'));
      expect(report, contains('Status: Technique needs improvement'));
      expect(report, contains('Squat too shallow'));
      expect(report, contains('Knee Valgus'));
      expect(report, contains('Heels rising'));
      expect(report, contains('Recommendations'));
    });

    test('generates report with specific error values', () {
      final result = DiagnosticsResult(
        isCorrect: false,
        feedback: {
          'Torso Instability': '15°',
          'Asymmetrical Shift': 'Right',
        },
      );

      final report = service.generateReport(result, 'Hurdle Step');

      expect(report, contains('Torso Instability: 15°'));
      expect(report, contains('Asymmetrical Shift: Right'));
    });

    test('generates report for correct hurdle step', () {
      const result = DiagnosticsResult(
        isCorrect: true,
        feedback: {'System': 'Movement correct.'},
      );

      final report = service.generateReport(result, 'Hurdle Step');

      expect(report, contains('Exercise Analysis: Hurdle Step'));
      expect(report, contains('Status: Movement correct.'));
      expect(report, contains('Excellent form'));
    });

    test('generates report for correct shoulder abduction', () {
      const result = DiagnosticsResult(
        isCorrect: true,
        feedback: {'System': 'Movement correct.'},
      );

      final report = service.generateReport(result, 'Standing Shoulder Abduction');

      expect(report, contains('Standing Shoulder Abduction'));
      expect(report, contains('Excellent form'));
    });

    test('generates report with unknown error key', () {
      final result = DiagnosticsResult(
        isCorrect: false,
        feedback: {
          'Unknown Error Type': true,
        },
      );

      final report = service.generateReport(result, 'Deep Squat');

      expect(report, contains('Unknown Error Type'));
      expect(report, contains('Focus on correcting'));
    });

    test('handles empty feedback map correctly', () {
      final result = DiagnosticsResult(
        isCorrect: false,
        feedback: {'No active exercise detected': true},
      );

      final report = service.generateReport(result, 'Deep Squat');

      // Should show excellent form when only 'No active exercise' is present
      expect(report, contains('Excellent form'));
    });

    test('generates report with all hurdle step errors', () {
      final result = DiagnosticsResult(
        isCorrect: false,
        feedback: {
          'Pelvic Hike (Compensation)': true,
          'Knee Valgus': true,
          'Torso Instability': '12°',
          'Step too low': true,
          'Foot External Rotation': true,
          'Lack of Dorsiflexion (Toes down)': true,
        },
      );

      final report = service.generateReport(result, 'Hurdle Step');

      expect(report, contains('Pelvic Hike'));
      expect(report, contains('Knee Valgus'));
      expect(report, contains('Torso Instability'));
      expect(report, contains('Step too low'));
      expect(report, contains('Foot External Rotation'));
      expect(report, contains('Dorsiflexion'));
    });

    test('generates report with all shoulder abduction errors', () {
      final result = DiagnosticsResult(
        isCorrect: false,
        feedback: {
          'Shoulder elevation (Shrugging)': true,
          'Excessive trunk lean': '18°',
          'Unstable non-working arm': true,
          'Arm asymmetry': true,
          'Arm raised too high (>100°)': 'L:105°, R:110°',
          'Movement too shallow (<80°)': 'L:70°',
        },
      );

      final report =
          service.generateReport(result, 'Standing Shoulder Abduction');

      expect(report, contains('Shrugging'));
      expect(report, contains('trunk lean'));
      expect(report, contains('non-working arm'));
      expect(report, contains('asymmetry'));
      expect(report, contains('too high'));
      expect(report, contains('too shallow'));
    });
  });

  group('Variant Detection - Edge Cases', () {
    test('detectVariant with single frame', () {
      final skeletonData = [_createNeutralFrame()];

      final variant = service.detectVariant(
        'Standing Shoulder Abduction',
        skeletonData,
      );

      expect(variant, isA<String>());
    });

    test('detectVariant handles frames with equal values', () {
      final frames = List.generate(20, (_) {
        final frame = _createNeutralFrame();
        // Both wrists at same position
        frame[15] = [0.35, 0.25, 0.0];
        frame[16] = [0.65, 0.25, 0.0];
        return frame;
      });

      final variant = service.detectVariant(
        'Standing Shoulder Abduction',
        frames,
      );

      expect(variant, equals('BOTH'));
    });
  });
}

// Helper functions to create test landmarks

List<List<double>> _createNeutralFrame() {
  // Create a 33-landmark frame in neutral standing position
  return List.generate(33, (i) {
    switch (i) {
      case 0: // nose
        return [0.5, 0.2, 0.0];
      case 11: // left shoulder
        return [0.4, 0.3, 0.0];
      case 12: // right shoulder
        return [0.6, 0.3, 0.0];
      case 13: // left elbow
        return [0.35, 0.45, 0.0];
      case 14: // right elbow
        return [0.65, 0.45, 0.0];
      case 15: // left wrist
        return [0.35, 0.55, 0.0];
      case 16: // right wrist
        return [0.65, 0.55, 0.0];
      case 23: // left hip
        return [0.45, 0.55, 0.0];
      case 24: // right hip
        return [0.55, 0.55, 0.0];
      case 25: // left knee
        return [0.45, 0.75, 0.0];
      case 26: // right knee
        return [0.55, 0.75, 0.0];
      case 27: // left ankle
        return [0.45, 0.95, 0.0];
      case 28: // right ankle
        return [0.55, 0.95, 0.0];
      case 29: // left heel
        return [0.43, 0.97, 0.0];
      case 30: // right heel
        return [0.57, 0.97, 0.0];
      case 31: // left foot index
        return [0.47, 0.99, 0.0];
      case 32: // right foot index
        return [0.53, 0.99, 0.0];
      default:
        return [0.5, 0.5, 0.0];
    }
  });
}

List<List<double>> _createNeutralFrameAsList() {
  return List.generate(33, (i) {
    switch (i) {
      case 0:
        return [0.5, 0.2, 0.0];
      case 11:
        return [0.4, 0.3, 0.0];
      case 12:
        return [0.6, 0.3, 0.0];
      case 13:
        return [0.35, 0.45, 0.0];
      case 14:
        return [0.65, 0.45, 0.0];
      case 15:
        return [0.35, 0.55, 0.0];
      case 16:
        return [0.65, 0.55, 0.0];
      case 23:
        return [0.45, 0.55, 0.0];
      case 24:
        return [0.55, 0.55, 0.0];
      case 25:
        return [0.45, 0.75, 0.0];
      case 26:
        return [0.55, 0.75, 0.0];
      case 27:
        return [0.45, 0.95, 0.0];
      case 28:
        return [0.55, 0.95, 0.0];
      case 29:
        return [0.43, 0.97, 0.0];
      case 30:
        return [0.57, 0.97, 0.0];
      case 31:
        return [0.47, 0.99, 0.0];
      case 32:
        return [0.53, 0.99, 0.0];
      default:
        return [0.5, 0.5, 0.0];
    }
  });
}

PoseLandmarks _createNeutralLandmarks() {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createAsymmetricalShiftSquatLandmarks(String direction) {
  final frames = List.generate(30, (frameIndex) {
    final frame = _createNeutralFrameAsList();
    final depth = (frameIndex / 30.0) * 0.4;
    frame[23] = [0.45, 0.55 + depth, 0.0];
    frame[24] = [0.55, 0.55 + depth, 0.0];

    // Shift shoulders significantly to one side
    if (direction == 'right') {
      frame[11] = [0.5, 0.3, 0.0]; // Left shoulder shifted right
      frame[12] = [0.7, 0.3, 0.0]; // Right shoulder shifted right
    } else {
      frame[11] = [0.3, 0.3, 0.0]; // Left shoulder shifted left
      frame[12] = [0.5, 0.3, 0.0]; // Right shoulder shifted left
    }

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createDuckFeetSquatLandmarks() {
  final frames = List.generate(30, (frameIndex) {
    final frame = _createNeutralFrameAsList();
    final depth = (frameIndex / 30.0) * 0.4;
    frame[23] = [0.45, 0.55 + depth, 0.0];
    frame[24] = [0.55, 0.55 + depth, 0.0];

    // Extreme foot turn-out (duck feet)
    frame[29] = [0.35, 0.97, 0.0]; // Left heel
    frame[31] = [0.55, 0.99, 0.0]; // Left foot index way outward
    frame[30] = [0.65, 0.97, 0.0]; // Right heel
    frame[32] = [0.45, 0.99, 0.0]; // Right foot index way outward

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createForwardLeanSquatLandmarks() {
  final frames = List.generate(30, (frameIndex) {
    final frame = _createNeutralFrameAsList();
    final depth = (frameIndex / 30.0) * 0.4;
    frame[23] = [0.45, 0.55 + depth, 0.0]; // Left hip
    frame[24] = [0.55, 0.55 + depth, 0.0]; // Right hip

    // Shoulders significantly forward and down (excessive forward lean)
    // This needs to make torsoVerticalLen < shinLen * 0.6
    // Torso vertical len = hip Y avg - shoulder Y avg
    // For lean: shoulders Y should be closer to hip Y (smaller vertical dist)
    frame[11] = [0.25, 0.50 + depth, 0.0]; // Left shoulder close to hip level
    frame[12] = [0.45, 0.50 + depth, 0.0]; // Right shoulder close to hip level

    // Keep knees and ankles normal to have normal shin length
    frame[25] = [0.45, 0.75, 0.0]; // Left knee
    frame[26] = [0.55, 0.75, 0.0]; // Right knee
    frame[27] = [0.45, 0.95, 0.0]; // Left ankle
    frame[28] = [0.55, 0.95, 0.0]; // Right ankle

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createLeftHeelRiseSquatLandmarks() {
  final frames = List.generate(30, (frameIndex) {
    final frame = _createNeutralFrameAsList();
    final depth = (frameIndex / 30.0) * 0.4;
    frame[23] = [0.45, 0.55 + depth, 0.0];
    frame[24] = [0.55, 0.55 + depth, 0.0];

    // Only left heel rises
    frame[29] = [0.42, 0.90, 0.0]; // Left heel raised
    frame[31] = [0.48, 0.99, 0.0]; // Left foot index stays

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createRightHeelRiseSquatLandmarks() {
  final frames = List.generate(30, (frameIndex) {
    final frame = _createNeutralFrameAsList();
    final depth = (frameIndex / 30.0) * 0.4;
    frame[23] = [0.45, 0.55 + depth, 0.0];
    frame[24] = [0.55, 0.55 + depth, 0.0];

    // Only right heel rises
    frame[30] = [0.58, 0.90, 0.0]; // Right heel raised
    frame[32] = [0.52, 0.99, 0.0]; // Right foot index stays

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createMultipleErrorSquatLandmarks() {
  final frames = List.generate(30, (frameIndex) {
    final frame = _createNeutralFrameAsList();
    // Shallow squat
    final depth = (frameIndex / 30.0) * 0.05;
    frame[23] = [0.45, 0.55 + depth, 0.0];
    frame[24] = [0.55, 0.55 + depth, 0.0];

    // Knee valgus
    frame[25] = [0.48, 0.75, 0.0];
    frame[26] = [0.52, 0.75, 0.0];
    frame[27] = [0.42, 0.95, 0.0];
    frame[28] = [0.58, 0.95, 0.0];

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createPelvicHikeHurdleLandmarks() {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    // Left knee raised
    frame[25] = [0.45, 0.50, 0.0];
    frame[27] = [0.45, 0.60, 0.0];

    // Pelvic hike - moving hip raised above stance hip
    frame[23] = [0.45, 0.45, 0.0]; // Left hip (moving) hiked up
    frame[24] = [0.55, 0.55, 0.0]; // Right hip (stance) stays

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createPelvicDropHurdleLandmarks() {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    // Left knee raised
    frame[25] = [0.45, 0.50, 0.0];
    frame[27] = [0.45, 0.60, 0.0];

    // Pelvic drop - moving hip drops below stance hip
    frame[23] = [0.45, 0.65, 0.0]; // Left hip (moving) dropped
    frame[24] = [0.55, 0.55, 0.0]; // Right hip (stance) stays

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createKneeValgusHurdleLandmarks() {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    // Left knee raised
    frame[25] = [0.45, 0.50, 0.0];
    frame[27] = [0.45, 0.60, 0.0];

    // Stance leg knee valgus (right knee caves in)
    frame[24] = [0.55, 0.55, 0.0]; // Right hip
    frame[26] = [0.48, 0.75, 0.0]; // Right knee caved in
    frame[28] = [0.55, 0.95, 0.0]; // Right ankle stays out

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createFootExternalRotationHurdleLandmarks() {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    // Left knee raised
    frame[25] = [0.45, 0.50, 0.0];

    // Moving foot externally rotated (ankle way outside of knee)
    frame[27] = [0.55, 0.60, 0.0]; // Left ankle rotated out

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createToesDownHurdleLandmarks() {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    // Left knee raised
    frame[25] = [0.45, 0.50, 0.0];
    frame[27] = [0.45, 0.60, 0.0];

    // Toes pointing down (foot index below ankle)
    frame[31] = [0.45, 0.70, 0.0]; // Left foot index way below ankle

    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createCorrectHurdleStepLandmarks(String variant) {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    if (variant == 'LEFT') {
      frame[25] = [0.45, 0.50, 0.0]; // Left knee high
      frame[27] = [0.45, 0.60, 0.0]; // Left ankle high
      frame[31] = [0.45, 0.58, 0.0]; // Left foot dorsiflexed
    } else {
      frame[26] = [0.55, 0.50, 0.0]; // Right knee high
      frame[28] = [0.55, 0.60, 0.0]; // Right ankle high
      frame[32] = [0.55, 0.58, 0.0]; // Right foot dorsiflexed
    }
    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createUnstableNonWorkingArmLandmarks(String activeVariant) {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    if (activeVariant == 'LEFT') {
      // Left arm raised (working arm)
      frame[13] = [0.2, 0.3, 0.0];
      frame[15] = [0.1, 0.25, 0.0];
      // Right arm also raised (should be still) - unstable
      frame[14] = [0.8, 0.3, 0.0];
      frame[16] = [0.9, 0.25, 0.0];
    } else {
      // Right arm raised (working arm)
      frame[14] = [0.8, 0.3, 0.0];
      frame[16] = [0.9, 0.25, 0.0];
      // Left arm also raised (should be still) - unstable
      frame[13] = [0.2, 0.3, 0.0];
      frame[15] = [0.1, 0.25, 0.0];
    }
    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createArmAsymmetryLandmarks() {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    // Both arms raised but at very different heights
    // For BOTH variant to be active: both wrists must be ABOVE elbows
    // (wristY < elbowY in screen coordinates where Y increases downward)
    frame[13] = [0.2, 0.28, 0.0]; // Left elbow
    frame[15] = [0.1, 0.12, 0.0]; // Left wrist high (above elbow)
    frame[14] = [0.8, 0.28, 0.0]; // Right elbow
    frame[16] = [0.9, 0.25, 0.0]; // Right wrist above elbow but much lower than left
    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createArmTooHighLandmarks() {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    // Arms raised way too high (>100°)
    frame[11] = [0.4, 0.3, 0.0]; // Left shoulder
    frame[12] = [0.6, 0.3, 0.0]; // Right shoulder
    frame[13] = [0.3, 0.15, 0.0]; // Left elbow way above shoulder
    frame[14] = [0.7, 0.15, 0.0]; // Right elbow way above shoulder
    frame[15] = [0.2, 0.10, 0.0]; // Left wrist
    frame[16] = [0.8, 0.10, 0.0]; // Right wrist
    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}

PoseLandmarks _createShallowAbductionLandmarks() {
  final frames = List.generate(30, (_) {
    final frame = _createNeutralFrameAsList();
    // Arms barely raised (very shallow, < 80°)
    frame[11] = [0.4, 0.3, 0.0]; // Left shoulder
    frame[12] = [0.6, 0.3, 0.0]; // Right shoulder
    frame[13] = [0.35, 0.38, 0.0]; // Left elbow barely above resting
    frame[14] = [0.65, 0.38, 0.0]; // Right elbow barely above resting
    frame[15] = [0.32, 0.35, 0.0]; // Left wrist above elbow
    frame[16] = [0.68, 0.35, 0.0]; // Right wrist above elbow
    return PoseFrame(
      landmarks: frame.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  });
  return PoseLandmarks(frames: frames);
}
