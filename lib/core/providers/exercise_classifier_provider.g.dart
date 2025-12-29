// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_classifier_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides singleton instance of [ExerciseClassifierService].
///
/// keepAlive ensures the service persists across the app lifecycle.

@ProviderFor(exerciseClassifierService)
const exerciseClassifierServiceProvider = ExerciseClassifierServiceProvider._();

/// Provides singleton instance of [ExerciseClassifierService].
///
/// keepAlive ensures the service persists across the app lifecycle.

final class ExerciseClassifierServiceProvider
    extends
        $FunctionalProvider<
          ExerciseClassifierService,
          ExerciseClassifierService,
          ExerciseClassifierService
        >
    with $Provider<ExerciseClassifierService> {
  /// Provides singleton instance of [ExerciseClassifierService].
  ///
  /// keepAlive ensures the service persists across the app lifecycle.
  const ExerciseClassifierServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseClassifierServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseClassifierServiceHash();

  @$internal
  @override
  $ProviderElement<ExerciseClassifierService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExerciseClassifierService create(Ref ref) {
    return exerciseClassifierService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseClassifierService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseClassifierService>(value),
    );
  }
}

String _$exerciseClassifierServiceHash() =>
    r'3c09f55b37c29e96f185839c769779479a6cb85d';
