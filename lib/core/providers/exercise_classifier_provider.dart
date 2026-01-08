import 'package:orthosense/core/services/exercise_classifier_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_classifier_provider.g.dart';

@Riverpod(keepAlive: true)
ExerciseClassifierService exerciseClassifierService(Ref ref) {
  final service = ExerciseClassifierService();
  ref.onDispose(service.dispose);
  return service;
}
