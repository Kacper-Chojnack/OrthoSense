// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plans_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for list of treatment plans.

@ProviderFor(plansList)
const plansListProvider = PlansListFamily._();

/// Provider for list of treatment plans.

final class PlansListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TreatmentPlanModel>>,
          List<TreatmentPlanModel>,
          FutureOr<List<TreatmentPlanModel>>
        >
    with
        $FutureModifier<List<TreatmentPlanModel>>,
        $FutureProvider<List<TreatmentPlanModel>> {
  /// Provider for list of treatment plans.
  const PlansListProvider._({
    required PlansListFamily super.from,
    required PlanStatus? super.argument,
  }) : super(
         retry: null,
         name: r'plansListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plansListHash();

  @override
  String toString() {
    return r'plansListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TreatmentPlanModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TreatmentPlanModel>> create(Ref ref) {
    final argument = this.argument as PlanStatus?;
    return plansList(ref, status: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlansListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plansListHash() => r'93850b9e349dadc0aeab678c6e05fafe06bcca5c';

/// Provider for list of treatment plans.

final class PlansListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TreatmentPlanModel>>,
          PlanStatus?
        > {
  const PlansListFamily._()
    : super(
        retry: null,
        name: r'plansListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for list of treatment plans.

  PlansListProvider call({PlanStatus? status}) =>
      PlansListProvider._(argument: status, from: this);

  @override
  String toString() => r'plansListProvider';
}

/// Provider for a single treatment plan.

@ProviderFor(plan)
const planProvider = PlanFamily._();

/// Provider for a single treatment plan.

final class PlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<TreatmentPlanDetails>,
          TreatmentPlanDetails,
          FutureOr<TreatmentPlanDetails>
        >
    with
        $FutureModifier<TreatmentPlanDetails>,
        $FutureProvider<TreatmentPlanDetails> {
  /// Provider for a single treatment plan.
  const PlanProvider._({
    required PlanFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planHash();

  @override
  String toString() {
    return r'planProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TreatmentPlanDetails> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TreatmentPlanDetails> create(Ref ref) {
    final argument = this.argument as String;
    return plan(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planHash() => r'c55fd730a0d0713dad5388a5fdc13527c8c1247a';

/// Provider for a single treatment plan.

final class PlanFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TreatmentPlanDetails>, String> {
  const PlanFamily._()
    : super(
        retry: null,
        name: r'planProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for a single treatment plan.

  PlanProvider call(String planId) =>
      PlanProvider._(argument: planId, from: this);

  @override
  String toString() => r'planProvider';
}

/// Notifier for treatment plan management.

@ProviderFor(PlansNotifier)
const plansProvider = PlansNotifierProvider._();

/// Notifier for treatment plan management.
final class PlansNotifierProvider
    extends $AsyncNotifierProvider<PlansNotifier, void> {
  /// Notifier for treatment plan management.
  const PlansNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plansNotifierHash();

  @$internal
  @override
  PlansNotifier create() => PlansNotifier();
}

String _$plansNotifierHash() => r'b7c2e2a5ce170633cc60468938416d809be3dfd6';

/// Notifier for treatment plan management.

abstract class _$PlansNotifier extends $AsyncNotifier<void> {
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
