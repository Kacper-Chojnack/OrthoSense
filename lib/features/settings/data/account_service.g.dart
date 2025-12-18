// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountService)
const accountServiceProvider = AccountServiceProvider._();

final class AccountServiceProvider
    extends $FunctionalProvider<AccountService, AccountService, AccountService>
    with $Provider<AccountService> {
  const AccountServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountServiceHash();

  @$internal
  @override
  $ProviderElement<AccountService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountService create(Ref ref) {
    return accountService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountService>(value),
    );
  }
}

String _$accountServiceHash() => r'df28de8a949b50c85862be0c3282a524b49b7aaf';

/// Notifier for account operations with loading state.

@ProviderFor(AccountOperationNotifier)
const accountOperationProvider = AccountOperationNotifierProvider._();

/// Notifier for account operations with loading state.
final class AccountOperationNotifierProvider
    extends $NotifierProvider<AccountOperationNotifier, AccountOperationState> {
  /// Notifier for account operations with loading state.
  const AccountOperationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountOperationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountOperationNotifierHash();

  @$internal
  @override
  AccountOperationNotifier create() => AccountOperationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountOperationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountOperationState>(value),
    );
  }
}

String _$accountOperationNotifierHash() =>
    r'68cbfdddc66b278da855648405863a93a96ab1e3';

/// Notifier for account operations with loading state.

abstract class _$AccountOperationNotifier
    extends $Notifier<AccountOperationState> {
  AccountOperationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AccountOperationState, AccountOperationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AccountOperationState, AccountOperationState>,
              AccountOperationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
