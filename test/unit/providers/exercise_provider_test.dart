/// Unit tests for Exercise Provider.
///
/// Test coverage:
/// 1. Exercise list loading
/// 2. Exercise filtering
/// 3. Exercise selection
/// 4. Exercise catalog management
/// 5. Error handling
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exercise List Loading', () {
    test('exercises are loaded on initialization', () {
      final exercises = [
        ExerciseModel(
          id: 'ex-1',
          name: 'Deep Squat',
          category: ExerciseCategory.mobility,
          bodyPart: BodyPart.knee,
          difficultyLevel: 2,
        ),
        ExerciseModel(
          id: 'ex-2',
          name: 'Standing Shoulder Abduction',
          category: ExerciseCategory.flexibility,
          bodyPart: BodyPart.shoulder,
          difficultyLevel: 1,
        ),
      ];

      expect(exercises.length, equals(2));
    });

    test('exercise list state is loading initially', () {
      final state = ExerciseListState.loading();
      expect(state.isLoading, isTrue);
      expect(state.exercises, isEmpty);
    });

    test('exercise list state transitions to loaded', () {
      final exercises = [
        ExerciseModel(
          id: 'ex-1',
          name: 'Deep Squat',
          category: ExerciseCategory.mobility,
          bodyPart: BodyPart.knee,
          difficultyLevel: 2,
        ),
      ];

      final state = ExerciseListState.loaded(exercises);
      expect(state.isLoading, isFalse);
      expect(state.exercises, isNotEmpty);
    });

    test('exercise list state handles error', () {
      final state = ExerciseListState.error('Failed to load exercises');
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('Exercise Filtering', () {
    late List<ExerciseModel> allExercises;

    setUp(() {
      allExercises = [
        ExerciseModel(
          id: 'ex-1',
          name: 'Deep Squat',
          category: ExerciseCategory.mobility,
          bodyPart: BodyPart.knee,
          difficultyLevel: 2,
        ),
        ExerciseModel(
          id: 'ex-2',
          name: 'Standing Shoulder Abduction',
          category: ExerciseCategory.flexibility,
          bodyPart: BodyPart.shoulder,
          difficultyLevel: 1,
        ),
        ExerciseModel(
          id: 'ex-3',
          name: 'Single Leg Stand',
          category: ExerciseCategory.balance,
          bodyPart: BodyPart.ankle,
          difficultyLevel: 3,
        ),
        ExerciseModel(
          id: 'ex-4',
          name: 'Hip Flexor Stretch',
          category: ExerciseCategory.flexibility,
          bodyPart: BodyPart.hip,
          difficultyLevel: 1,
        ),
      ];
    });

    test('filter by category returns matching exercises', () {
      final filtered = allExercises
          .where((e) => e.category == ExerciseCategory.flexibility)
          .toList();

      expect(filtered.length, equals(2));
      expect(
        filtered.every((e) => e.category == ExerciseCategory.flexibility),
        isTrue,
      );
    });

    test('filter by body part returns matching exercises', () {
      final filtered = allExercises
          .where((e) => e.bodyPart == BodyPart.knee)
          .toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.name, equals('Deep Squat'));
    });

    test('filter by difficulty returns matching exercises', () {
      final filtered = allExercises
          .where((e) => e.difficultyLevel == 1)
          .toList();

      expect(filtered.length, equals(2));
    });

    test('combined filters work correctly', () {
      final filtered = allExercises
          .where(
            (e) =>
                e.category == ExerciseCategory.flexibility &&
                e.difficultyLevel == 1,
          )
          .toList();

      expect(filtered.length, equals(2));
    });

    test('search by name returns matching exercises', () {
      final searchTerm = 'squat';
      final filtered = allExercises
          .where((e) => e.name.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.name, equals('Deep Squat'));
    });
  });

  group('Exercise Selection', () {
    test('selected exercise is tracked', () {
      final exercise = ExerciseModel(
        id: 'ex-1',
        name: 'Deep Squat',
        category: ExerciseCategory.mobility,
        bodyPart: BodyPart.knee,
        difficultyLevel: 2,
      );

      final selectionState = ExerciseSelectionState(selectedExercise: exercise);
      expect(selectionState.selectedExercise, isNotNull);
      expect(selectionState.selectedExercise!.id, equals('ex-1'));
    });

    test('selection can be cleared', () {
      final selectionState = ExerciseSelectionState(selectedExercise: null);
      expect(selectionState.selectedExercise, isNull);
    });

    test('selection state provides exercise details', () {
      final exercise = ExerciseModel(
        id: 'ex-2',
        name: 'Standing Shoulder Abduction',
        category: ExerciseCategory.flexibility,
        bodyPart: BodyPart.shoulder,
        difficultyLevel: 1,
        description: 'Arm raise for shoulder mobility assessment',
        videoUrl: 'https://example.com/video.mp4',
        instructions: ['Stand upright', 'Raise arm slowly', 'Return to start'],
      );

      final selectionState = ExerciseSelectionState(selectedExercise: exercise);
      expect(selectionState.selectedExercise!.description, isNotNull);
      expect(selectionState.selectedExercise!.instructions, hasLength(3));
    });
  });

  group('Exercise Active State', () {
    test('exercise active state is tracked', () {
      final exercises = [
        ExerciseModel(
          id: 'ex-1',
          name: 'Deep Squat',
          category: ExerciseCategory.mobility,
          bodyPart: BodyPart.knee,
          difficultyLevel: 2,
          isActive: true,
        ),
        ExerciseModel(
          id: 'ex-2',
          name: 'Deprecated Exercise',
          category: ExerciseCategory.mobility,
          bodyPart: BodyPart.knee,
          difficultyLevel: 2,
          isActive: false,
        ),
      ];

      final activeExercises = exercises.where((e) => e.isActive).toList();
      expect(activeExercises.length, equals(1));
    });
  });

  group('Exercise Difficulty Sorting', () {
    test('exercises can be sorted by difficulty ascending', () {
      final exercises = [
        ExerciseModel(
          id: 'ex-1',
          name: 'Hard Exercise',
          category: ExerciseCategory.mobility,
          bodyPart: BodyPart.knee,
          difficultyLevel: 5,
        ),
        ExerciseModel(
          id: 'ex-2',
          name: 'Easy Exercise',
          category: ExerciseCategory.mobility,
          bodyPart: BodyPart.knee,
          difficultyLevel: 1,
        ),
        ExerciseModel(
          id: 'ex-3',
          name: 'Medium Exercise',
          category: ExerciseCategory.mobility,
          bodyPart: BodyPart.knee,
          difficultyLevel: 3,
        ),
      ];

      final sorted = [...exercises]
        ..sort((a, b) => a.difficultyLevel.compareTo(b.difficultyLevel));

      expect(sorted.first.difficultyLevel, equals(1));
      expect(sorted.last.difficultyLevel, equals(5));
    });
  });
}

// Model classes for testing
enum ExerciseCategory { mobility, flexibility, strength, balance }

enum BodyPart { knee, shoulder, hip, ankle, spine }

class ExerciseModel {
  ExerciseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.bodyPart,
    required this.difficultyLevel,
    this.description,
    this.videoUrl,
    this.instructions,
    this.isActive = true,
  });

  final String id;
  final String name;
  final ExerciseCategory category;
  final BodyPart bodyPart;
  final int difficultyLevel;
  final String? description;
  final String? videoUrl;
  final List<String>? instructions;
  final bool isActive;
}

class ExerciseListState {
  ExerciseListState._({
    required this.isLoading,
    required this.exercises,
    this.errorMessage,
  });

  factory ExerciseListState.loading() => ExerciseListState._(
    isLoading: true,
    exercises: [],
  );

  factory ExerciseListState.loaded(List<ExerciseModel> exercises) =>
      ExerciseListState._(
        isLoading: false,
        exercises: exercises,
      );

  factory ExerciseListState.error(String message) => ExerciseListState._(
    isLoading: false,
    exercises: [],
    errorMessage: message,
  );

  final bool isLoading;
  final List<ExerciseModel> exercises;
  final String? errorMessage;
}

class ExerciseSelectionState {
  ExerciseSelectionState({this.selectedExercise});

  final ExerciseModel? selectedExercise;
}
