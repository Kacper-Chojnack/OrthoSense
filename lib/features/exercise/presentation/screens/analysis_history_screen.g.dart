// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_history_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for fetching analysis history from Drift database (SSOT).
/// Returns a Stream for reactive updates.

@ProviderFor(analysisHistoryStream)
const analysisHistoryStreamProvider = AnalysisHistoryStreamProvider._();

/// Provider for fetching analysis history from Drift database (SSOT).
/// Returns a Stream for reactive updates.

final class AnalysisHistoryStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AnalysisHistoryItem>>,
          List<AnalysisHistoryItem>,
          Stream<List<AnalysisHistoryItem>>
        >
    with
        $FutureModifier<List<AnalysisHistoryItem>>,
        $StreamProvider<List<AnalysisHistoryItem>> {
  /// Provider for fetching analysis history from Drift database (SSOT).
  /// Returns a Stream for reactive updates.
  const AnalysisHistoryStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisHistoryStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisHistoryStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<AnalysisHistoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AnalysisHistoryItem>> create(Ref ref) {
    return analysisHistoryStream(ref);
  }
}

String _$analysisHistoryStreamHash() =>
    r'26df17035c370ec79264422d8e2bbfac662eefb0';

/// Provider for fetching analysis history (async, for initial load).

@ProviderFor(analysisHistory)
const analysisHistoryProvider = AnalysisHistoryProvider._();

/// Provider for fetching analysis history (async, for initial load).

final class AnalysisHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AnalysisHistoryItem>>,
          List<AnalysisHistoryItem>,
          FutureOr<List<AnalysisHistoryItem>>
        >
    with
        $FutureModifier<List<AnalysisHistoryItem>>,
        $FutureProvider<List<AnalysisHistoryItem>> {
  /// Provider for fetching analysis history (async, for initial load).
  const AnalysisHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<AnalysisHistoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AnalysisHistoryItem>> create(Ref ref) {
    return analysisHistory(ref);
  }
}

String _$analysisHistoryHash() => r'722e909f9c6cc919caec1f61ad58cda2ce72d83e';
