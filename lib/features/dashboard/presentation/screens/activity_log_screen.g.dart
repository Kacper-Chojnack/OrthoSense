// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivityFilterNotifier)
const activityFilterProvider = ActivityFilterNotifierProvider._();

final class ActivityFilterNotifierProvider
    extends $NotifierProvider<ActivityFilterNotifier, ActivityFilter> {
  const ActivityFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityFilterNotifierHash();

  @$internal
  @override
  ActivityFilterNotifier create() => ActivityFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityFilter>(value),
    );
  }
}

String _$activityFilterNotifierHash() =>
    r'77c4315bd04363c9c403c12ac403abf63591fbac';

abstract class _$ActivityFilterNotifier extends $Notifier<ActivityFilter> {
  ActivityFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ActivityFilter, ActivityFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActivityFilter, ActivityFilter>,
              ActivityFilter,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
