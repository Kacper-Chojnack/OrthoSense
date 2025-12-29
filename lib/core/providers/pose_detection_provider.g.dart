// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pose_detection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(poseDetectionService)
const poseDetectionServiceProvider = PoseDetectionServiceProvider._();

final class PoseDetectionServiceProvider
    extends
        $FunctionalProvider<
          PoseDetectionService,
          PoseDetectionService,
          PoseDetectionService
        >
    with $Provider<PoseDetectionService> {
  const PoseDetectionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'poseDetectionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$poseDetectionServiceHash();

  @$internal
  @override
  $ProviderElement<PoseDetectionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PoseDetectionService create(Ref ref) {
    return poseDetectionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PoseDetectionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PoseDetectionService>(value),
    );
  }
}

String _$poseDetectionServiceHash() =>
    r'8b39988493b2d0a18c85bf49dee08c98e206de00';
