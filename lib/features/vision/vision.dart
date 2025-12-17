/// Vision feature barrel file.
/// Exports all public APIs for the vision/AR module.
library;

// Domain
export 'domain/models/models.dart';
export 'domain/services/pose_estimator.dart';

// Data
export 'data/services/mock_pose_estimator.dart';

// Presentation
export 'presentation/painters/skeleton_painter.dart';
export 'presentation/providers/pose_detection_provider.dart';
export 'presentation/widgets/ar_overlay_widget.dart';
