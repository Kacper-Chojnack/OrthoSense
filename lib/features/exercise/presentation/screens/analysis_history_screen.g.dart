// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_history_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for fetching analysis history.
/// In production, this would watch the Drift database Stream.

@ProviderFor(analysisHistory)
const analysisHistoryProvider = AnalysisHistoryProvider._();

/// Provider for fetching analysis history.
/// In production, this would watch the Drift database Stream.

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
  /// Provider for fetching analysis history.
  /// In production, this would watch the Drift database Stream.
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

String _$analysisHistoryHash() => r'2a7da0bfc959a063534847229e1b79bf687ccd00';
