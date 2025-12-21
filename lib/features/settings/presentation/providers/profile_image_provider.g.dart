// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_image_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages profile image state with persistence.

@ProviderFor(ProfileImageNotifier)
const profileImageProvider = ProfileImageNotifierProvider._();

/// Manages profile image state with persistence.
final class ProfileImageNotifierProvider
    extends $AsyncNotifierProvider<ProfileImageNotifier, String?> {
  /// Manages profile image state with persistence.
  const ProfileImageNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileImageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileImageNotifierHash();

  @$internal
  @override
  ProfileImageNotifier create() => ProfileImageNotifier();
}

String _$profileImageNotifierHash() =>
    r'bc5bcef46e5d8d5a1925305272783937e19f38da';

/// Manages profile image state with persistence.

abstract class _$ProfileImageNotifier extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
