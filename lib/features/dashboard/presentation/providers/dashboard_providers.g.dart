// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardMeasurementsHash() =>
    r'6f23a59f2b6c85bc6b8fd690204591e6c56ec049';

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

/// Provides measurements with their sync status for dashboard display.
/// Uses Drift stream as Single Source of Truth (SSOT).
///
/// Copied from [dashboardMeasurements].
@ProviderFor(dashboardMeasurements)
const dashboardMeasurementsProvider = DashboardMeasurementsFamily();

/// Provides measurements with their sync status for dashboard display.
/// Uses Drift stream as Single Source of Truth (SSOT).
///
/// Copied from [dashboardMeasurements].
class DashboardMeasurementsFamily
    extends Family<AsyncValue<List<MeasurementWithStatus>>> {
  /// Provides measurements with their sync status for dashboard display.
  /// Uses Drift stream as Single Source of Truth (SSOT).
  ///
  /// Copied from [dashboardMeasurements].
  const DashboardMeasurementsFamily();

  /// Provides measurements with their sync status for dashboard display.
  /// Uses Drift stream as Single Source of Truth (SSOT).
  ///
  /// Copied from [dashboardMeasurements].
  DashboardMeasurementsProvider call(
    String userId,
  ) {
    return DashboardMeasurementsProvider(
      userId,
    );
  }

  @override
  DashboardMeasurementsProvider getProviderOverride(
    covariant DashboardMeasurementsProvider provider,
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
  String? get name => r'dashboardMeasurementsProvider';
}

/// Provides measurements with their sync status for dashboard display.
/// Uses Drift stream as Single Source of Truth (SSOT).
///
/// Copied from [dashboardMeasurements].
class DashboardMeasurementsProvider
    extends AutoDisposeStreamProvider<List<MeasurementWithStatus>> {
  /// Provides measurements with their sync status for dashboard display.
  /// Uses Drift stream as Single Source of Truth (SSOT).
  ///
  /// Copied from [dashboardMeasurements].
  DashboardMeasurementsProvider(
    String userId,
  ) : this._internal(
          (ref) => dashboardMeasurements(
            ref as DashboardMeasurementsRef,
            userId,
          ),
          from: dashboardMeasurementsProvider,
          name: r'dashboardMeasurementsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dashboardMeasurementsHash,
          dependencies: DashboardMeasurementsFamily._dependencies,
          allTransitiveDependencies:
              DashboardMeasurementsFamily._allTransitiveDependencies,
          userId: userId,
        );

  DashboardMeasurementsProvider._internal(
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
    Stream<List<MeasurementWithStatus>> Function(
            DashboardMeasurementsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DashboardMeasurementsProvider._internal(
        (ref) => create(ref as DashboardMeasurementsRef),
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
  AutoDisposeStreamProviderElement<List<MeasurementWithStatus>>
      createElement() {
    return _DashboardMeasurementsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DashboardMeasurementsProvider && other.userId == userId;
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
mixin DashboardMeasurementsRef
    on AutoDisposeStreamProviderRef<List<MeasurementWithStatus>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _DashboardMeasurementsProviderElement
    extends AutoDisposeStreamProviderElement<List<MeasurementWithStatus>>
    with DashboardMeasurementsRef {
  _DashboardMeasurementsProviderElement(super.provider);

  @override
  String get userId => (origin as DashboardMeasurementsProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
