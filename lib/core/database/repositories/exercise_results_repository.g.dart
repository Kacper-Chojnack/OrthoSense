// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_results_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exerciseResultsRepository)
const exerciseResultsRepositoryProvider = ExerciseResultsRepositoryProvider._();

final class ExerciseResultsRepositoryProvider
    extends
        $FunctionalProvider<
          ExerciseResultsRepository,
          ExerciseResultsRepository,
          ExerciseResultsRepository
        >
    with $Provider<ExerciseResultsRepository> {
  const ExerciseResultsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseResultsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseResultsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExerciseResultsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExerciseResultsRepository create(Ref ref) {
    return exerciseResultsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseResultsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseResultsRepository>(value),
    );
  }
}

String _$exerciseResultsRepositoryHash() =>
    r'28c010e7062605b17584974e02bebb8e7a24b30d';
