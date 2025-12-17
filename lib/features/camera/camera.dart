/// Camera feature barrel file.
/// Exports all public APIs for the camera module.
library;

// Domain
export 'domain/models/camera_frame.dart';
export 'domain/repositories/camera_repository.dart';

// Data
export 'data/repositories/mock_camera_repository.dart';
export 'data/repositories/real_camera_repository.dart';

// Providers
export 'presentation/providers/camera_controller.dart';
export 'presentation/providers/camera_providers.dart';
export 'presentation/providers/camera_state.dart';

// Screens
export 'presentation/screens/camera_screen.dart';
