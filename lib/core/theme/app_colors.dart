import 'package:flutter/material.dart';

/// Semantic colors for OrthoSense exercise analysis features.
/// These extend the base Material 3 theme with domain-specific colors.
abstract final class AppColors {
  // Semantic Colors for Feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFB00020);

  // Confidence Score Gradients
  static const Color highConfidence = Color(0xFF00C853);
  static const Color mediumConfidence = Color(0xFFFFD600);
  static const Color lowConfidence = Color(0xFFFF3D00);

  // Video Overlay Colors
  static final Color videoOverlay = Colors.black.withValues(alpha: 0.4);
  static final Color videoControlsBg = Colors.black.withValues(alpha: 0.6);

  /// Returns appropriate color based on confidence score (0.0 - 1.0).
  static Color getConfidenceColor(double score) {
    if (score >= 0.8) return highConfidence;
    if (score >= 0.5) return mediumConfidence;
    return lowConfidence;
  }

  /// Returns appropriate color for correctness indicator.
  static Color getCorrectnessColor({required bool isCorrect}) {
    return isCorrect ? success : warning;
  }
}
