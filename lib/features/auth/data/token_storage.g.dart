// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$flutterSecureStorageHash() =>
    r'652bb25a66699938e1f2cab58111c3834c2f5bc5';

/// See also [flutterSecureStorage].
@ProviderFor(flutterSecureStorage)
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>.internal(
  flutterSecureStorage,
  name: r'flutterSecureStorageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$flutterSecureStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FlutterSecureStorageRef = ProviderRef<FlutterSecureStorage>;
String _$sharedPreferencesHash() => r'1c2dd1a84771b17e16cc7c9461dd6736a2a28921';

/// Provider for SharedPreferences (must be overridden in main.dart).
///
/// Copied from [sharedPreferences].
@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = Provider<SharedPreferences>.internal(
  sharedPreferences,
  name: r'sharedPreferencesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sharedPreferencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SharedPreferencesRef = ProviderRef<SharedPreferences>;
String _$tokenStorageHash() => r'aefc1dc181298649780c6188dc044b0b7358a037';

/// Platform-aware token storage provider.
/// Uses SecureStorage on iOS/Android, SharedPreferences on desktop/web.
///
/// Copied from [tokenStorage].
@ProviderFor(tokenStorage)
final tokenStorageProvider = Provider<TokenStorage>.internal(
  tokenStorage,
  name: r'tokenStorageProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tokenStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TokenStorageRef = ProviderRef<TokenStorage>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
