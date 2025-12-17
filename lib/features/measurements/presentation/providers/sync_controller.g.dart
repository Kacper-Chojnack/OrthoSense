// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncControllerHash() => r'bd1f85ff738662b241a40b0885c0bc362611390d';

/// Controller for sync operations.
/// Exposes manual sync trigger and current sync state.
///
/// Copied from [SyncController].
@ProviderFor(SyncController)
final syncControllerProvider =
    NotifierProvider<SyncController, SyncStatusInfo>.internal(
  SyncController.new,
  name: r'syncControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncController = Notifier<SyncStatusInfo>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
