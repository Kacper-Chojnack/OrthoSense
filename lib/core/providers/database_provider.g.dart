// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'96b544ff7ce456f0fc1edbdafdf332306a9affed';

/// Provides singleton [AppDatabase] instance.
/// Database is NOT autoDispose - lives for app lifecycle.
///
/// Copied from [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
String _$measurementsDaoHash() => r'88004bc4a51fddc78907b42d37ebad0cba555a22';

/// Provides [MeasurementsDao] for repository layer.
///
/// Copied from [measurementsDao].
@ProviderFor(measurementsDao)
final measurementsDaoProvider = Provider<MeasurementsDao>.internal(
  measurementsDao,
  name: r'measurementsDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$measurementsDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MeasurementsDaoRef = ProviderRef<MeasurementsDao>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
