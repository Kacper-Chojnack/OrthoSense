import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/therapist_dashboard/data/therapist_repository.dart';
import 'package:orthosense/features/therapist_dashboard/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercises_provider.g.dart';

/// Provider for list of exercises.
@riverpod
Future<List<ExerciseModel>> exercisesList(
  Ref ref, {
  ExerciseCategory? category,
  BodyPart? bodyPart,
}) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getExercises(category: category, bodyPart: bodyPart);
}

/// Provider for a single exercise.
@riverpod
Future<ExerciseModel> exercise(Ref ref, String exerciseId) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getExercise(exerciseId);
}

/// Notifier for exercise management.
@riverpod
class ExercisesNotifier extends _$ExercisesNotifier {
  @override
  FutureOr<void> build() {}

  Future<ExerciseModel> createExercise({
    required String name,
    String description = '',
    String instructions = '',
    ExerciseCategory category = ExerciseCategory.mobility,
    BodyPart bodyPart = BodyPart.knee,
    int difficultyLevel = 1,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    Map<String, dynamic> sensorConfig = const {},
    Map<String, dynamic> metricsConfig = const {},
  }) async {
    final repo = ref.read(therapistRepositoryProvider);
    final exercise = await repo.createExercise(
      name: name,
      description: description,
      instructions: instructions,
      category: category,
      bodyPart: bodyPart,
      difficultyLevel: difficultyLevel,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      sensorConfig: sensorConfig,
      metricsConfig: metricsConfig,
    );
    ref.invalidate(exercisesListProvider);
    return exercise;
  }
}
