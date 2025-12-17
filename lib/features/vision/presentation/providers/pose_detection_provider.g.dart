// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pose_detection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$poseEstimatorHash() => r'3514106c91be6d92d3794a5d92edb7ee0d164ba0';

/// Provides [PoseEstimator] implementation.
/// Override in tests to inject mock.
///
/// Copied from [poseEstimator].
@ProviderFor(poseEstimator)
final poseEstimatorProvider = Provider<PoseEstimator>.internal(
  poseEstimator,
  name: r'poseEstimatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$poseEstimatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PoseEstimatorRef = ProviderRef<PoseEstimator>;
String _$poseDetectionHash() => r'6eb267c30ae686704a7f7999017b57f3a1a2c8cc';

/// Provides stream of pose detection results.
/// Automatically starts when camera is ready.
///
/// Copied from [poseDetection].
@ProviderFor(poseDetection)
final poseDetectionProvider = AutoDisposeStreamProvider<PoseResult>.internal(
  poseDetection,
  name: r'poseDetectionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$poseDetectionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PoseDetectionRef = AutoDisposeStreamProviderRef<PoseResult>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
