// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(voiceList)
const voiceListProvider = VoiceListProvider._();

final class VoiceListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, String>>>,
          List<Map<String, String>>,
          FutureOr<List<Map<String, String>>>
        >
    with
        $FutureModifier<List<Map<String, String>>>,
        $FutureProvider<List<Map<String, String>>> {
  const VoiceListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceListHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, String>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, String>>> create(Ref ref) {
    return voiceList(ref);
  }
}

String _$voiceListHash() => r'f0d30167a877dfc5fdb94359944fab6c5bf539fc';
