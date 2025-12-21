// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnboardingController)
const onboardingControllerProvider = OnboardingControllerProvider._();

final class OnboardingControllerProvider
    extends $NotifierProvider<OnboardingController, OnboardingStatus> {
  const OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  OnboardingController create() => OnboardingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingStatus>(value),
    );
  }
}

String _$onboardingControllerHash() =>
    r'f036133c58963e23860bb3e7365e6f7ddbb05b82';

abstract class _$OnboardingController extends $Notifier<OnboardingStatus> {
  OnboardingStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<OnboardingStatus, OnboardingStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingStatus, OnboardingStatus>,
              OnboardingStatus,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
