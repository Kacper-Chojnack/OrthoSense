/// Unit tests for AppColors theme configuration.
///
/// Test coverage:
/// 1. Semantic color values
/// 2. Confidence color logic
/// 3. Correctness color mapping
/// 4. Video overlay colors
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/theme/app_colors.dart';

void main() {
  group('Semantic Colors', () {
    test('success color is defined', () {
      expect(AppColors.success, isA<Color>());
      expect(AppColors.success, equals(const Color(0xFF4CAF50)));
    });

    test('warning color is defined', () {
      expect(AppColors.warning, isA<Color>());
      expect(AppColors.warning, equals(const Color(0xFFFFC107)));
    });

    test('error color is defined', () {
      expect(AppColors.error, isA<Color>());
      expect(AppColors.error, equals(const Color(0xFFB00020)));
    });

    test('success color is green-ish', () {
      // Green channel should be prominent
      expect(AppColors.success.green, greaterThan(AppColors.success.red));
      expect(AppColors.success.green, greaterThan(AppColors.success.blue));
    });

    test('warning color is yellow/amber', () {
      // Yellow has high red and green, low blue
      expect(AppColors.warning.red, greaterThan(200));
      expect(AppColors.warning.green, greaterThan(150));
    });

    test('error color is red-ish', () {
      expect(AppColors.error.red, greaterThan(AppColors.error.green));
      expect(AppColors.error.red, greaterThan(AppColors.error.blue));
    });
  });

  group('Confidence Colors', () {
    test('highConfidence color is defined', () {
      expect(AppColors.highConfidence, isA<Color>());
      expect(AppColors.highConfidence, equals(const Color(0xFF00C853)));
    });

    test('mediumConfidence color is defined', () {
      expect(AppColors.mediumConfidence, isA<Color>());
      expect(AppColors.mediumConfidence, equals(const Color(0xFFFFD600)));
    });

    test('lowConfidence color is defined', () {
      expect(AppColors.lowConfidence, isA<Color>());
      expect(AppColors.lowConfidence, equals(const Color(0xFFFF3D00)));
    });

    test('confidence colors are distinct', () {
      expect(
        AppColors.highConfidence,
        isNot(equals(AppColors.mediumConfidence)),
      );
      expect(
        AppColors.mediumConfidence,
        isNot(equals(AppColors.lowConfidence)),
      );
      expect(AppColors.highConfidence, isNot(equals(AppColors.lowConfidence)));
    });
  });

  group('getConfidenceColor', () {
    test('returns highConfidence for score >= 0.8', () {
      expect(
        AppColors.getConfidenceColor(1.0),
        equals(AppColors.highConfidence),
      );
      expect(
        AppColors.getConfidenceColor(0.95),
        equals(AppColors.highConfidence),
      );
      expect(
        AppColors.getConfidenceColor(0.85),
        equals(AppColors.highConfidence),
      );
      expect(
        AppColors.getConfidenceColor(0.8),
        equals(AppColors.highConfidence),
      );
    });

    test('returns mediumConfidence for score >= 0.5 and < 0.8', () {
      expect(
        AppColors.getConfidenceColor(0.79),
        equals(AppColors.mediumConfidence),
      );
      expect(
        AppColors.getConfidenceColor(0.7),
        equals(AppColors.mediumConfidence),
      );
      expect(
        AppColors.getConfidenceColor(0.6),
        equals(AppColors.mediumConfidence),
      );
      expect(
        AppColors.getConfidenceColor(0.5),
        equals(AppColors.mediumConfidence),
      );
    });

    test('returns lowConfidence for score < 0.5', () {
      expect(
        AppColors.getConfidenceColor(0.49),
        equals(AppColors.lowConfidence),
      );
      expect(
        AppColors.getConfidenceColor(0.3),
        equals(AppColors.lowConfidence),
      );
      expect(
        AppColors.getConfidenceColor(0.1),
        equals(AppColors.lowConfidence),
      );
      expect(
        AppColors.getConfidenceColor(0.0),
        equals(AppColors.lowConfidence),
      );
    });

    test('boundary at 0.8 returns high confidence', () {
      final color = AppColors.getConfidenceColor(0.8);
      expect(color, equals(AppColors.highConfidence));
    });

    test('just below 0.8 returns medium confidence', () {
      final color = AppColors.getConfidenceColor(0.79);
      expect(color, equals(AppColors.mediumConfidence));
    });

    test('boundary at 0.5 returns medium confidence', () {
      final color = AppColors.getConfidenceColor(0.5);
      expect(color, equals(AppColors.mediumConfidence));
    });

    test('just below 0.5 returns low confidence', () {
      final color = AppColors.getConfidenceColor(0.49);
      expect(color, equals(AppColors.lowConfidence));
    });
  });

  group('getCorrectnessColor', () {
    test('returns success for correct movement', () {
      final color = AppColors.getCorrectnessColor(isCorrect: true);
      expect(color, equals(AppColors.success));
    });

    test('returns warning for incorrect movement', () {
      final color = AppColors.getCorrectnessColor(isCorrect: false);
      expect(color, equals(AppColors.warning));
    });
  });

  group('Video Overlay Colors', () {
    test('videoOverlay has transparency', () {
      expect(AppColors.videoOverlay.a, lessThan(1.0));
    });

    test('videoControlsBg has transparency', () {
      expect(AppColors.videoControlsBg.a, lessThan(1.0));
    });

    test('videoControlsBg is more opaque than videoOverlay', () {
      expect(
        AppColors.videoControlsBg.a,
        greaterThan(AppColors.videoOverlay.a),
      );
    });

    test('overlay colors are based on black', () {
      // Video overlays should be dark (based on black)
      expect(AppColors.videoOverlay.red, lessThan(10));
      expect(AppColors.videoOverlay.green, lessThan(10));
      expect(AppColors.videoOverlay.blue, lessThan(10));
    });
  });

  group('Color Consistency', () {
    test('semantic colors are distinct from each other', () {
      expect(AppColors.success, isNot(equals(AppColors.warning)));
      expect(AppColors.warning, isNot(equals(AppColors.error)));
      expect(AppColors.success, isNot(equals(AppColors.error)));
    });

    test('all colors are non-null', () {
      expect(AppColors.success, isNotNull);
      expect(AppColors.warning, isNotNull);
      expect(AppColors.error, isNotNull);
      expect(AppColors.highConfidence, isNotNull);
      expect(AppColors.mediumConfidence, isNotNull);
      expect(AppColors.lowConfidence, isNotNull);
      expect(AppColors.videoOverlay, isNotNull);
      expect(AppColors.videoControlsBg, isNotNull);
    });
  });
}
