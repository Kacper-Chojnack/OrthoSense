// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_stream_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userMeasurementsHash() => r'fd24aebc31fac4c79e1b7908f866776a1b7107b6';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provides reactive stream of measurements for a user.
/// UI should watch this provider for SSOT pattern.
///
/// Copied from [userMeasurements].
@ProviderFor(userMeasurements)
const userMeasurementsProvider = UserMeasurementsFamily();

/// Provides reactive stream of measurements for a user.
/// UI should watch this provider for SSOT pattern.
///
/// Copied from [userMeasurements].
class UserMeasurementsFamily
    extends Family<AsyncValue<List<MeasurementModel>>> {
  /// Provides reactive stream of measurements for a user.
  /// UI should watch this provider for SSOT pattern.
  ///
  /// Copied from [userMeasurements].
  const UserMeasurementsFamily();

  /// Provides reactive stream of measurements for a user.
  /// UI should watch this provider for SSOT pattern.
  ///
  /// Copied from [userMeasurements].
  UserMeasurementsProvider call(
    String userId,
  ) {
    return UserMeasurementsProvider(
      userId,
    );
  }

  @override
  UserMeasurementsProvider getProviderOverride(
    covariant UserMeasurementsProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userMeasurementsProvider';
}

/// Provides reactive stream of measurements for a user.
/// UI should watch this provider for SSOT pattern.
///
/// Copied from [userMeasurements].
class UserMeasurementsProvider
    extends AutoDisposeStreamProvider<List<MeasurementModel>> {
  /// Provides reactive stream of measurements for a user.
  /// UI should watch this provider for SSOT pattern.
  ///
  /// Copied from [userMeasurements].
  UserMeasurementsProvider(
    String userId,
  ) : this._internal(
          (ref) => userMeasurements(
            ref as UserMeasurementsRef,
            userId,
          ),
          from: userMeasurementsProvider,
          name: r'userMeasurementsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userMeasurementsHash,
          dependencies: UserMeasurementsFamily._dependencies,
          allTransitiveDependencies:
              UserMeasurementsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserMeasurementsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<List<MeasurementModel>> Function(UserMeasurementsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserMeasurementsProvider._internal(
        (ref) => create(ref as UserMeasurementsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MeasurementModel>> createElement() {
    return _UserMeasurementsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserMeasurementsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserMeasurementsRef
    on AutoDisposeStreamProviderRef<List<MeasurementModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserMeasurementsProviderElement
    extends AutoDisposeStreamProviderElement<List<MeasurementModel>>
    with UserMeasurementsRef {
  _UserMeasurementsProviderElement(super.provider);

  @override
  String get userId => (origin as UserMeasurementsProvider).userId;
}

String _$pendingMeasurementsCountHash() =>
    r'de8f566f81f6b938bcfb85fb2895676f441c6f42';

/// Provides count of pending measurements for sync indicator.
///
/// Copied from [pendingMeasurementsCount].
@ProviderFor(pendingMeasurementsCount)
final pendingMeasurementsCountProvider =
    AutoDisposeStreamProvider<int>.internal(
  pendingMeasurementsCount,
  name: r'pendingMeasurementsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingMeasurementsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingMeasurementsCountRef = AutoDisposeStreamProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
