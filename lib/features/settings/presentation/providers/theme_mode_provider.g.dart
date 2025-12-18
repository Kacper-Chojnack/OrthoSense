// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentThemeModeHash() => r'cc2a2ee41de7a3a0fb907963d699d6fafc88e85a';

/// Synchronous theme mode for MaterialApp.
/// Returns system as default while loading.
///
/// Copied from [currentThemeMode].
@ProviderFor(currentThemeMode)
final currentThemeModeProvider = AutoDisposeProvider<ThemeMode>.internal(
  currentThemeMode,
  name: r'currentThemeModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentThemeModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentThemeModeRef = AutoDisposeProviderRef<ThemeMode>;
String _$themeModeNotifierHash() => r'42f30771468e57154cc4d1348e06a71690c0fa3b';

/// Manages theme mode state with persistence.
///
/// Copied from [ThemeModeNotifier].
@ProviderFor(ThemeModeNotifier)
final themeModeNotifierProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>.internal(
      ThemeModeNotifier.new,
      name: r'themeModeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeModeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ThemeModeNotifier = AsyncNotifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
