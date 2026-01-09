// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the currently selected trend period (F08).

@ProviderFor(SelectedTrendPeriod)
const selectedTrendPeriodProvider = SelectedTrendPeriodProvider._();

/// Provider for the currently selected trend period (F08).
final class SelectedTrendPeriodProvider
    extends $NotifierProvider<SelectedTrendPeriod, TrendPeriod> {
  /// Provider for the currently selected trend period (F08).
  const SelectedTrendPeriodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTrendPeriodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTrendPeriodHash();

  @$internal
  @override
  SelectedTrendPeriod create() => SelectedTrendPeriod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrendPeriod value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrendPeriod>(value),
    );
  }
}

String _$selectedTrendPeriodHash() =>
    r'7a90ff588fb37de548220a021b532b8e1cac2f69';

/// Provider for the currently selected trend period (F08).

abstract class _$SelectedTrendPeriod extends $Notifier<TrendPeriod> {
  TrendPeriod build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<TrendPeriod, TrendPeriod>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrendPeriod, TrendPeriod>,
              TrendPeriod,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for trend chart data based on metric type and selected period.
/// Uses real data from Drift database.

@ProviderFor(trendData)
const trendDataProvider = TrendDataFamily._();

/// Provider for trend chart data based on metric type and selected period.
/// Uses real data from Drift database.

final class TrendDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrendChartData>,
          TrendChartData,
          FutureOr<TrendChartData>
        >
    with $FutureModifier<TrendChartData>, $FutureProvider<TrendChartData> {
  /// Provider for trend chart data based on metric type and selected period.
  /// Uses real data from Drift database.
  const TrendDataProvider._({
    required TrendDataFamily super.from,
    required TrendMetricType super.argument,
  }) : super(
         retry: null,
         name: r'trendDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trendDataHash();

  @override
  String toString() {
    return r'trendDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrendChartData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrendChartData> create(Ref ref) {
    final argument = this.argument as TrendMetricType;
    return trendData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trendDataHash() => r'acc5552d4cdbc9aec4b3a2d0aca3470609161d52';

/// Provider for trend chart data based on metric type and selected period.
/// Uses real data from Drift database.

final class TrendDataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TrendChartData>, TrendMetricType> {
  const TrendDataFamily._()
    : super(
        retry: null,
        name: r'trendDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for trend chart data based on metric type and selected period.
  /// Uses real data from Drift database.

  TrendDataProvider call(TrendMetricType metricType) =>
      TrendDataProvider._(argument: metricType, from: this);

  @override
  String toString() => r'trendDataProvider';
}

/// Provider for dashboard statistics summary.
/// Fetches real data from Drift database.

@ProviderFor(dashboardStats)
const dashboardStatsProvider = DashboardStatsProvider._();

/// Provider for dashboard statistics summary.
/// Fetches real data from Drift database.

final class DashboardStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardStats>,
          DashboardStats,
          FutureOr<DashboardStats>
        >
    with $FutureModifier<DashboardStats>, $FutureProvider<DashboardStats> {
  /// Provider for dashboard statistics summary.
  /// Fetches real data from Drift database.
  const DashboardStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardStatsHash();

  @$internal
  @override
  $FutureProviderElement<DashboardStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardStats> create(Ref ref) {
    return dashboardStats(ref);
  }
}

String _$dashboardStatsHash() => r'a538a8599bec7b78b3c93b5ddf6aca057eaae48c';

/// Provider for mini trend data used in stat cards.
/// Uses real data from Drift database.

@ProviderFor(miniTrendData)
const miniTrendDataProvider = MiniTrendDataFamily._();

/// Provider for mini trend data used in stat cards.
/// Uses real data from Drift database.

final class MiniTrendDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<double>>,
          List<double>,
          FutureOr<List<double>>
        >
    with $FutureModifier<List<double>>, $FutureProvider<List<double>> {
  /// Provider for mini trend data used in stat cards.
  /// Uses real data from Drift database.
  const MiniTrendDataProvider._({
    required MiniTrendDataFamily super.from,
    required TrendMetricType super.argument,
  }) : super(
         retry: null,
         name: r'miniTrendDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$miniTrendDataHash();

  @override
  String toString() {
    return r'miniTrendDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<double>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<double>> create(Ref ref) {
    final argument = this.argument as TrendMetricType;
    return miniTrendData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MiniTrendDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$miniTrendDataHash() => r'175f033a7a530f11863b1b8b754cdc6cc1431562';

/// Provider for mini trend data used in stat cards.
/// Uses real data from Drift database.

final class MiniTrendDataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<double>>, TrendMetricType> {
  const MiniTrendDataFamily._()
    : super(
        retry: null,
        name: r'miniTrendDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for mini trend data used in stat cards.
  /// Uses real data from Drift database.

  MiniTrendDataProvider call(TrendMetricType metricType) =>
      MiniTrendDataProvider._(argument: metricType, from: this);

  @override
  String toString() => r'miniTrendDataProvider';
}
