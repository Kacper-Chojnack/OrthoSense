// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for ConnectivityService.

@ProviderFor(connectivityService)
const connectivityServiceProvider = ConnectivityServiceProvider._();

/// Provider for ConnectivityService.

final class ConnectivityServiceProvider
    extends
        $FunctionalProvider<
          ConnectivityService,
          ConnectivityService,
          ConnectivityService
        >
    with $Provider<ConnectivityService> {
  /// Provider for ConnectivityService.
  const ConnectivityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityServiceHash();

  @$internal
  @override
  $ProviderElement<ConnectivityService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConnectivityService create(Ref ref) {
    return connectivityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectivityService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectivityService>(value),
    );
  }
}

String _$connectivityServiceHash() =>
    r'8aad782a54ee2cf5a02eced6652ee1a3bb1b3acd';

/// Provider for SyncQueue.

@ProviderFor(syncQueue)
const syncQueueProvider = SyncQueueProvider._();

/// Provider for SyncQueue.

final class SyncQueueProvider
    extends $FunctionalProvider<SyncQueue, SyncQueue, SyncQueue>
    with $Provider<SyncQueue> {
  /// Provider for SyncQueue.
  const SyncQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncQueueHash();

  @$internal
  @override
  $ProviderElement<SyncQueue> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncQueue create(Ref ref) {
    return syncQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncQueue>(value),
    );
  }
}

String _$syncQueueHash() => r'725923232831e6c9d616e2174c9a0f509b64b80d';

/// Provider for SyncService.

@ProviderFor(syncService)
const syncServiceProvider = SyncServiceProvider._();

/// Provider for SyncService.

final class SyncServiceProvider
    extends $FunctionalProvider<SyncService, SyncService, SyncService>
    with $Provider<SyncService> {
  /// Provider for SyncService.
  const SyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServiceHash();

  @$internal
  @override
  $ProviderElement<SyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncService create(Ref ref) {
    return syncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncService>(value),
    );
  }
}

String _$syncServiceHash() => r'ca77c73db6b1f706f22c66d542704d4d3352083e';

/// Provider for BackgroundSyncWorker.

@ProviderFor(backgroundSyncWorker)
const backgroundSyncWorkerProvider = BackgroundSyncWorkerProvider._();

/// Provider for BackgroundSyncWorker.

final class BackgroundSyncWorkerProvider
    extends
        $FunctionalProvider<
          BackgroundSyncWorker,
          BackgroundSyncWorker,
          BackgroundSyncWorker
        >
    with $Provider<BackgroundSyncWorker> {
  /// Provider for BackgroundSyncWorker.
  const BackgroundSyncWorkerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundSyncWorkerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundSyncWorkerHash();

  @$internal
  @override
  $ProviderElement<BackgroundSyncWorker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundSyncWorker create(Ref ref) {
    return backgroundSyncWorker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundSyncWorker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundSyncWorker>(value),
    );
  }
}

String _$backgroundSyncWorkerHash() =>
    r'9fecb64f361c727b760b08b0b331c4e907781025';

/// Provider for current sync state as a stream.

@ProviderFor(syncStateStream)
const syncStateStreamProvider = SyncStateStreamProvider._();

/// Provider for current sync state as a stream.

final class SyncStateStreamProvider
    extends
        $FunctionalProvider<AsyncValue<SyncState>, SyncState, Stream<SyncState>>
    with $FutureModifier<SyncState>, $StreamProvider<SyncState> {
  /// Provider for current sync state as a stream.
  const SyncStateStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncStateStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncStateStreamHash();

  @$internal
  @override
  $StreamProviderElement<SyncState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<SyncState> create(Ref ref) {
    return syncStateStream(ref);
  }
}

String _$syncStateStreamHash() => r'c6878c3685884caea56ece5ee4b5cef3ea99f955';

/// Provider for current connectivity status.

@ProviderFor(connectivityStream)
const connectivityStreamProvider = ConnectivityStreamProvider._();

/// Provider for current connectivity status.

final class ConnectivityStreamProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Provider for current connectivity status.
  const ConnectivityStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityStreamHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return connectivityStream(ref);
  }
}

String _$connectivityStreamHash() =>
    r'3de3434fced2121e9f73d698b15ce70452d3e6ee';

/// Notifier for sync operations with UI integration.

@ProviderFor(Sync)
const syncProvider = SyncProvider._();

/// Notifier for sync operations with UI integration.
final class SyncProvider extends $NotifierProvider<Sync, SyncState> {
  /// Notifier for sync operations with UI integration.
  const SyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncHash();

  @$internal
  @override
  Sync create() => Sync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncState>(value),
    );
  }
}

String _$syncHash() => r'8b316f723373bbb8b903bc2eeac8c18879eb4636';

/// Notifier for sync operations with UI integration.

abstract class _$Sync extends $Notifier<SyncState> {
  SyncState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SyncState, SyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncState, SyncState>,
              SyncState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for pending sync count.

@ProviderFor(pendingSyncCount)
const pendingSyncCountProvider = PendingSyncCountProvider._();

/// Provider for pending sync count.

final class PendingSyncCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for pending sync count.
  const PendingSyncCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSyncCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSyncCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return pendingSyncCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$pendingSyncCountHash() => r'0de2db966b4fcaf0f6acb064385cdd274df75805';

/// Provider for failed sync count.

@ProviderFor(failedSyncCount)
const failedSyncCountProvider = FailedSyncCountProvider._();

/// Provider for failed sync count.

final class FailedSyncCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for failed sync count.
  const FailedSyncCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'failedSyncCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$failedSyncCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return failedSyncCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$failedSyncCountHash() => r'b120dffbb04175939c846005321873a1b8bb4f07';

/// Provider for online status.

@ProviderFor(isOnline)
const isOnlineProvider = IsOnlineProvider._();

/// Provider for online status.

final class IsOnlineProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for online status.
  const IsOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnlineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnlineHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isOnline(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isOnlineHash() => r'499a2beb48c054c477b3cabcb81fde780d1fb4b7';
