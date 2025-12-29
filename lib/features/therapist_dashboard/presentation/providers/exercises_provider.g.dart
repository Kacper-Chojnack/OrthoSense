// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercises_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for list of exercises.

@ProviderFor(exercisesList)
const exercisesListProvider = ExercisesListFamily._();

/// Provider for list of exercises.

final class ExercisesListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ExerciseModel>>,
          List<ExerciseModel>,
          FutureOr<List<ExerciseModel>>
        >
    with
        $FutureModifier<List<ExerciseModel>>,
        $FutureProvider<List<ExerciseModel>> {
  /// Provider for list of exercises.
  const ExercisesListProvider._({
    required ExercisesListFamily super.from,
    required ({ExerciseCategory? category, BodyPart? bodyPart}) super.argument,
  }) : super(
         retry: null,
         name: r'exercisesListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exercisesListHash();

  @override
  String toString() {
    return r'exercisesListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ExerciseModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ExerciseModel>> create(Ref ref) {
    final argument =
        this.argument as ({ExerciseCategory? category, BodyPart? bodyPart});
    return exercisesList(
      ref,
      category: argument.category,
      bodyPart: argument.bodyPart,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExercisesListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exercisesListHash() => r'c9f5271215efcf02d95bfb81a21f22c45d67710d';

/// Provider for list of exercises.

final class ExercisesListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ExerciseModel>>,
          ({ExerciseCategory? category, BodyPart? bodyPart})
        > {
  const ExercisesListFamily._()
    : super(
        retry: null,
        name: r'exercisesListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for list of exercises.

  ExercisesListProvider call({
    ExerciseCategory? category,
    BodyPart? bodyPart,
  }) => ExercisesListProvider._(
    argument: (category: category, bodyPart: bodyPart),
    from: this,
  );

  @override
  String toString() => r'exercisesListProvider';
}

/// Provider for a single exercise.

@ProviderFor(exercise)
const exerciseProvider = ExerciseFamily._();

/// Provider for a single exercise.

final class ExerciseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExerciseModel>,
          ExerciseModel,
          FutureOr<ExerciseModel>
        >
    with $FutureModifier<ExerciseModel>, $FutureProvider<ExerciseModel> {
  /// Provider for a single exercise.
  const ExerciseProvider._({
    required ExerciseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseHash();

  @override
  String toString() {
    return r'exerciseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ExerciseModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExerciseModel> create(Ref ref) {
    final argument = this.argument as String;
    return exercise(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseHash() => r'91a01cd8d1da03b7e78cef2c1264b9b16be9670a';

/// Provider for a single exercise.

final class ExerciseFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ExerciseModel>, String> {
  const ExerciseFamily._()
    : super(
        retry: null,
        name: r'exerciseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for a single exercise.

  ExerciseProvider call(String exerciseId) =>
      ExerciseProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'exerciseProvider';
}

/// Notifier for exercise management.

@ProviderFor(ExercisesNotifier)
const exercisesProvider = ExercisesNotifierProvider._();

/// Notifier for exercise management.
final class ExercisesNotifierProvider
    extends $AsyncNotifierProvider<ExercisesNotifier, void> {
  /// Notifier for exercise management.
  const ExercisesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exercisesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exercisesNotifierHash();

  @$internal
  @override
  ExercisesNotifier create() => ExercisesNotifier();
}

String _$exercisesNotifierHash() => r'441ff75708a470d5cd06a6f440fa90bf22c45065';

/// Notifier for exercise management.

abstract class _$ExercisesNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
