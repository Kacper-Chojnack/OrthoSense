// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocols_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for list of protocols.

@ProviderFor(protocolsList)
const protocolsListProvider = ProtocolsListFamily._();

/// Provider for list of protocols.

final class ProtocolsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProtocolModel>>,
          List<ProtocolModel>,
          FutureOr<List<ProtocolModel>>
        >
    with
        $FutureModifier<List<ProtocolModel>>,
        $FutureProvider<List<ProtocolModel>> {
  /// Provider for list of protocols.
  const ProtocolsListProvider._({
    required ProtocolsListFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'protocolsListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$protocolsListHash();

  @override
  String toString() {
    return r'protocolsListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProtocolModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProtocolModel>> create(Ref ref) {
    final argument = this.argument as bool;
    return protocolsList(ref, onlyMine: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProtocolsListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$protocolsListHash() => r'66ea94164d29cab027df0d60683e51fec9f0e5d2';

/// Provider for list of protocols.

final class ProtocolsListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProtocolModel>>, bool> {
  const ProtocolsListFamily._()
    : super(
        retry: null,
        name: r'protocolsListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for list of protocols.

  ProtocolsListProvider call({bool onlyMine = false}) =>
      ProtocolsListProvider._(argument: onlyMine, from: this);

  @override
  String toString() => r'protocolsListProvider';
}

/// Provider for a single protocol with exercises.

@ProviderFor(protocol)
const protocolProvider = ProtocolFamily._();

/// Provider for a single protocol with exercises.

final class ProtocolProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProtocolWithExercises>,
          ProtocolWithExercises,
          FutureOr<ProtocolWithExercises>
        >
    with
        $FutureModifier<ProtocolWithExercises>,
        $FutureProvider<ProtocolWithExercises> {
  /// Provider for a single protocol with exercises.
  const ProtocolProvider._({
    required ProtocolFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'protocolProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$protocolHash();

  @override
  String toString() {
    return r'protocolProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProtocolWithExercises> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProtocolWithExercises> create(Ref ref) {
    final argument = this.argument as String;
    return protocol(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProtocolProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$protocolHash() => r'cfaf54204d27083da19c449b6979581b04009d67';

/// Provider for a single protocol with exercises.

final class ProtocolFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProtocolWithExercises>, String> {
  const ProtocolFamily._()
    : super(
        retry: null,
        name: r'protocolProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for a single protocol with exercises.

  ProtocolProvider call(String protocolId) =>
      ProtocolProvider._(argument: protocolId, from: this);

  @override
  String toString() => r'protocolProvider';
}

/// Notifier for protocol management actions.

@ProviderFor(ProtocolsNotifier)
const protocolsProvider = ProtocolsNotifierProvider._();

/// Notifier for protocol management actions.
final class ProtocolsNotifierProvider
    extends $AsyncNotifierProvider<ProtocolsNotifier, void> {
  /// Notifier for protocol management actions.
  const ProtocolsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'protocolsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$protocolsNotifierHash();

  @$internal
  @override
  ProtocolsNotifier create() => ProtocolsNotifier();
}

String _$protocolsNotifierHash() => r'f2f68fc39425112f15eba42d17c6f34b98b1947e';

/// Notifier for protocol management actions.

abstract class _$ProtocolsNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
