// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for list of patients assigned to therapist.

@ProviderFor(patientsList)
const patientsListProvider = PatientsListProvider._();

/// Provider for list of patients assigned to therapist.

final class PatientsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PatientModel>>,
          List<PatientModel>,
          FutureOr<List<PatientModel>>
        >
    with
        $FutureModifier<List<PatientModel>>,
        $FutureProvider<List<PatientModel>> {
  /// Provider for list of patients assigned to therapist.
  const PatientsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientsListHash();

  @$internal
  @override
  $FutureProviderElement<List<PatientModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PatientModel>> create(Ref ref) {
    return patientsList(ref);
  }
}

String _$patientsListHash() => r'bdc63132b49ab4a48f4fdbb0a089e421b8f83e51';

/// Provider for a single patient's data.

@ProviderFor(patient)
const patientProvider = PatientFamily._();

/// Provider for a single patient's data.

final class PatientProvider
    extends
        $FunctionalProvider<
          AsyncValue<PatientModel>,
          PatientModel,
          FutureOr<PatientModel>
        >
    with $FutureModifier<PatientModel>, $FutureProvider<PatientModel> {
  /// Provider for a single patient's data.
  const PatientProvider._({
    required PatientFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientHash();

  @override
  String toString() {
    return r'patientProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PatientModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PatientModel> create(Ref ref) {
    final argument = this.argument as String;
    return patient(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientHash() => r'db32133e7be42319950cf32fcfe7bd20751920e4';

/// Provider for a single patient's data.

final class PatientFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PatientModel>, String> {
  const PatientFamily._()
    : super(
        retry: null,
        name: r'patientProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for a single patient's data.

  PatientProvider call(String patientId) =>
      PatientProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientProvider';
}

/// Provider for patient's treatment plans.

@ProviderFor(patientPlans)
const patientPlansProvider = PatientPlansFamily._();

/// Provider for patient's treatment plans.

final class PatientPlansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TreatmentPlanDetails>>,
          List<TreatmentPlanDetails>,
          FutureOr<List<TreatmentPlanDetails>>
        >
    with
        $FutureModifier<List<TreatmentPlanDetails>>,
        $FutureProvider<List<TreatmentPlanDetails>> {
  /// Provider for patient's treatment plans.
  const PatientPlansProvider._({
    required PatientPlansFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientPlansProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientPlansHash();

  @override
  String toString() {
    return r'patientPlansProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TreatmentPlanDetails>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TreatmentPlanDetails>> create(Ref ref) {
    final argument = this.argument as String;
    return patientPlans(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientPlansProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientPlansHash() => r'87519b3e55d4f3b95409ac456f5487c2fe124099';

/// Provider for patient's treatment plans.

final class PatientPlansFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TreatmentPlanDetails>>,
          String
        > {
  const PatientPlansFamily._()
    : super(
        retry: null,
        name: r'patientPlansProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for patient's treatment plans.

  PatientPlansProvider call(String patientId) =>
      PatientPlansProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientPlansProvider';
}

/// Provider for patient statistics.

@ProviderFor(patientStats)
const patientStatsProvider = PatientStatsFamily._();

/// Provider for patient statistics.

final class PatientStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PatientStats>,
          PatientStats,
          FutureOr<PatientStats>
        >
    with $FutureModifier<PatientStats>, $FutureProvider<PatientStats> {
  /// Provider for patient statistics.
  const PatientStatsProvider._({
    required PatientStatsFamily super.from,
    required (String, {String? planId}) super.argument,
  }) : super(
         retry: null,
         name: r'patientStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientStatsHash();

  @override
  String toString() {
    return r'patientStatsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<PatientStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PatientStats> create(Ref ref) {
    final argument = this.argument as (String, {String? planId});
    return patientStats(ref, argument.$1, planId: argument.planId);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientStatsHash() => r'2b5b91cfe486708423747162197e3c618b292362';

/// Provider for patient statistics.

final class PatientStatsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<PatientStats>,
          (String, {String? planId})
        > {
  const PatientStatsFamily._()
    : super(
        retry: null,
        name: r'patientStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for patient statistics.

  PatientStatsProvider call(String patientId, {String? planId}) =>
      PatientStatsProvider._(argument: (patientId, planId: planId), from: this);

  @override
  String toString() => r'patientStatsProvider';
}

/// Provider for patient's recent sessions (for remote monitoring).

@ProviderFor(patientSessions)
const patientSessionsProvider = PatientSessionsFamily._();

/// Provider for patient's recent sessions (for remote monitoring).

final class PatientSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSummary>>,
          List<SessionSummary>,
          FutureOr<List<SessionSummary>>
        >
    with
        $FutureModifier<List<SessionSummary>>,
        $FutureProvider<List<SessionSummary>> {
  /// Provider for patient's recent sessions (for remote monitoring).
  const PatientSessionsProvider._({
    required PatientSessionsFamily super.from,
    required (String, {String? planId, int limit}) super.argument,
  }) : super(
         retry: null,
         name: r'patientSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientSessionsHash();

  @override
  String toString() {
    return r'patientSessionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<SessionSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SessionSummary>> create(Ref ref) {
    final argument = this.argument as (String, {String? planId, int limit});
    return patientSessions(
      ref,
      argument.$1,
      planId: argument.planId,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PatientSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientSessionsHash() => r'1618125835ffe47bec2233f0f68620b9bed4993a';

/// Provider for patient's recent sessions (for remote monitoring).

final class PatientSessionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SessionSummary>>,
          (String, {String? planId, int limit})
        > {
  const PatientSessionsFamily._()
    : super(
        retry: null,
        name: r'patientSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for patient's recent sessions (for remote monitoring).

  PatientSessionsProvider call(
    String patientId, {
    String? planId,
    int limit = 20,
  }) => PatientSessionsProvider._(
    argument: (patientId, planId: planId, limit: limit),
    from: this,
  );

  @override
  String toString() => r'patientSessionsProvider';
}
