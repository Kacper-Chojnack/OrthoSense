import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/services/movement_diagnostics_service.dart';

final movementDiagnosticsServiceProvider = Provider<MovementDiagnosticsService>(
  (ref) {
    return MovementDiagnosticsService();
  },
);
