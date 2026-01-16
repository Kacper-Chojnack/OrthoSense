import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/providers/database_provider.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trend_provider.g.dart';

/// Provider for the currently selected trend period (F08).
@riverpod
class SelectedTrendPeriod extends _$SelectedTrendPeriod {
  @override
  TrendPeriod build() => TrendPeriod.days7;

  void setPeriod(TrendPeriod period) {
    state = period;
  }
}

/// Provider for trend chart data based on metric type and selected period.
/// Uses real data from Drift database.
@riverpod
Future<TrendChartData> trendData(
  Ref ref,
  TrendMetricType metricType,
) async {
  final period = ref.watch(selectedTrendPeriodProvider);
  final db = ref.watch(appDatabaseProvider);

  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: period.days));

  // Query exercise results for the selected period
  final results =
      await (db.select(db.exerciseResults)
            ..where((t) => t.performedAt.isBiggerOrEqualValue(startDate))
            ..orderBy([(t) => OrderingTerm.asc(t.performedAt)]))
          .get();

  return _generateTrendDataFromResults(results, period, metricType);
}

/// Provider for dashboard statistics summary.
/// Fetches real data from Drift database.
@riverpod
Future<DashboardStats> dashboardStats(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final stats = await db.getExerciseStats();

  // Get all results to calculate total time and streak
  final allResults = await db.select(db.exerciseResults).get();

  // Calculate total time in minutes
  final totalSeconds = allResults.fold<int>(
    0,
    (sum, r) => sum + r.durationSeconds,
  );
  final totalTimeMinutes = totalSeconds ~/ 60;

  // Calculate active streak days
  final activeStreak = _calculateActiveStreak(allResults);

  // Calculate score change (difference between this week and previous week)
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  final twoWeeksAgo = now.subtract(const Duration(days: 14));

  final thisWeekResults = allResults.where(
    (r) => r.performedAt.isAfter(weekAgo),
  );
  final prevWeekResults = allResults.where(
    (r) =>
        r.performedAt.isAfter(twoWeeksAgo) && r.performedAt.isBefore(weekAgo),
  );

  final thisWeekAvg = thisWeekResults.isEmpty
      ? 0.0
      : thisWeekResults
                .where((r) => r.score != null)
                .map((r) => r.score!)
                .fold<int>(0, (a, b) => a + b) /
            thisWeekResults.length;
  final prevWeekAvg = prevWeekResults.isEmpty
      ? 0.0
      : prevWeekResults
                .where((r) => r.score != null)
                .map((r) => r.score!)
                .fold<int>(0, (a, b) => a + b) /
            prevWeekResults.length;
  final scoreChange = thisWeekAvg - prevWeekAvg;

  return DashboardStats(
    totalSessions: stats.totalSessions,
    sessionsThisWeek: stats.thisWeekSessions,
    averageScore: stats.averageScore.toDouble(),
    scoreChange: scoreChange,
    activeStreakDays: activeStreak,
    totalTimeThisMonth: Duration(minutes: totalTimeMinutes),
    completionRate: stats.correctPercentage.toDouble(),
  );
}

/// Calculate consecutive days with at least one session.
int _calculateActiveStreak(List<ExerciseResult> results) {
  if (results.isEmpty) return 0;

  // Group by date
  final sessionDates =
      results
          .map(
            (r) => DateTime(
              r.performedAt.year,
              r.performedAt.month,
              r.performedAt.day,
            ),
          )
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // newest first

  if (sessionDates.isEmpty) return 0;

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final yesterday = todayDate.subtract(const Duration(days: 1));

  // Check if streak is current (today or yesterday)
  if (sessionDates.first != todayDate && sessionDates.first != yesterday) {
    return 0; // Streak broken
  }

  int streak = 1;
  for (int i = 0; i < sessionDates.length - 1; i++) {
    final diff = sessionDates[i].difference(sessionDates[i + 1]).inDays;
    if (diff == 1) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}

/// Stream provider for recent exercise results (reactive updates).
/// Uses standard Riverpod syntax for Drift compatibility.
final recentExerciseResultsProvider = StreamProvider<List<ExerciseResult>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.exerciseResults)
        ..orderBy([(t) => OrderingTerm.desc(t.performedAt)])
        ..limit(10))
      .watch();
});

/// Provider for mini trend data used in stat cards.
/// Uses real data from Drift database.
@riverpod
Future<List<double>> miniTrendData(
  Ref ref,
  TrendMetricType metricType,
) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final startDate = now.subtract(const Duration(days: 7));

  // Query last 7 days of results
  final results =
      await (db.select(db.exerciseResults)
            ..where((t) => t.performedAt.isBiggerOrEqualValue(startDate))
            ..orderBy([(t) => OrderingTerm.asc(t.performedAt)]))
          .get();

  if (results.isEmpty) {
    return <double>[];
  }

  // Group by date and calculate metric per day
  final dailyData = <DateTime, List<double>>{};
  for (final result in results) {
    final date = DateTime(
      result.performedAt.year,
      result.performedAt.month,
      result.performedAt.day,
    );
    dailyData.putIfAbsent(date, () => []);
    final value = _extractMetricValue(result, metricType);
    if (value != null) {
      dailyData[date]!.add(value);
    }
  }

  // Calculate daily averages
  final sortedDates = dailyData.keys.toList()..sort();
  return sortedDates.map((date) {
    final values = dailyData[date]!;
    return values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
  }).toList();
}

// --- Private Helpers ---

/// Generate trend data from real exercise results.
TrendChartData _generateTrendDataFromResults(
  List<ExerciseResult> results,
  TrendPeriod period,
  TrendMetricType metricType,
) {
  if (results.isEmpty) {
    return TrendChartData(
      dataPoints: [],
      period: period,
      metricType: metricType,
      minValue: _getMinValue(metricType),
      maxValue: _getMaxValue(metricType),
      averageValue: 0,
      changePercent: 0,
    );
  }

  // Group results by date
  final dailyData = <DateTime, List<double>>{};
  for (final result in results) {
    final date = DateTime(
      result.performedAt.year,
      result.performedAt.month,
      result.performedAt.day,
    );
    dailyData.putIfAbsent(date, () => []);
    final value = _extractMetricValue(result, metricType);
    if (value != null) {
      dailyData[date]!.add(value);
    }
  }

  // Convert to data points (daily averages)
  final sortedDates = dailyData.keys.toList()..sort();
  final dataPoints = <TrendDataPoint>[];

  for (var i = 0; i < sortedDates.length; i++) {
    final date = sortedDates[i];
    final values = dailyData[date]!;
    if (values.isEmpty) continue;

    final avgValue = values.reduce((a, b) => a + b) / values.length;

    dataPoints.add(
      TrendDataPoint(
        date: date,
        value: avgValue.clamp(
          _getMinValue(metricType),
          _getMaxValue(metricType),
        ),
        label: _formatDateLabel(date, period),
        isHighlighted: i == sortedDates.length - 1, // Highlight most recent
      ),
    );
  }

  // Calculate statistics
  final values = dataPoints.map((p) => p.value).toList();
  final average = values.isNotEmpty
      ? values.reduce((a, b) => a + b) / values.length
      : 0.0;

  final firstHalf = values.take(values.length ~/ 2).toList();
  final secondHalf = values.skip(values.length ~/ 2).toList();
  final firstAvg = firstHalf.isNotEmpty
      ? firstHalf.reduce((a, b) => a + b) / firstHalf.length
      : 0.0;
  final secondAvg = secondHalf.isNotEmpty
      ? secondHalf.reduce((a, b) => a + b) / secondHalf.length
      : 0.0;
  final change = secondAvg - firstAvg;

  return TrendChartData(
    dataPoints: dataPoints,
    period: period,
    metricType: metricType,
    minValue: _getMinValue(metricType),
    maxValue: _getMaxValue(metricType),
    averageValue: average,
    changePercent: change,
  );
}

/// Extract metric value from an exercise result.
double? _extractMetricValue(ExerciseResult result, TrendMetricType metricType) {
  switch (metricType) {
    case TrendMetricType.rangeOfMotion:
      // No direct range of motion in schema, use score as proxy
      return result.score?.toDouble();
    case TrendMetricType.sessionScore:
      return result.score?.toDouble();
    case TrendMetricType.exerciseDuration:
      return result.durationSeconds / 60.0; // Convert to minutes
    case TrendMetricType.completionRate:
      // Use isCorrect boolean - 100 if correct, 0 if not
      if (result.isCorrect == null) return null;
      return result.isCorrect! ? 100.0 : 0.0;
    case TrendMetricType.painLevel:
      // Pain level not stored in current schema, return null
      return null;
  }
}

double _getMinValue(TrendMetricType type) {
  switch (type) {
    case TrendMetricType.rangeOfMotion:
      return 0;
    case TrendMetricType.sessionScore:
      return 0;
    case TrendMetricType.exerciseDuration:
      return 0;
    case TrendMetricType.completionRate:
      return 0;
    case TrendMetricType.painLevel:
      return 0;
  }
}

double _getMaxValue(TrendMetricType type) {
  switch (type) {
    case TrendMetricType.rangeOfMotion:
      return 180;
    case TrendMetricType.sessionScore:
      return 100;
    case TrendMetricType.exerciseDuration:
      return 60;
    case TrendMetricType.completionRate:
      return 100;
    case TrendMetricType.painLevel:
      return 10;
  }
}

String _formatDateLabel(DateTime date, TrendPeriod period) {
  switch (period) {
    case TrendPeriod.days7:
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    case TrendPeriod.days30:
      return '${date.day}/${date.month}';
    case TrendPeriod.days90:
      return '${date.day}/${date.month}';
  }
}

enum WeeklyActivityMetric { sessions, minutes }

class WeeklyActivityDay {
  const WeeklyActivityDay({
    required this.date,
    required this.value,
    required this.label,
    required this.isToday,
  });

  final DateTime date;
  final double value;
  final String label;
  final bool isToday;
}

class SelectedWeeklyActivityMetricNotifier
    extends Notifier<WeeklyActivityMetric> {
  @override
  WeeklyActivityMetric build() => WeeklyActivityMetric.sessions;

  void setMetric(WeeklyActivityMetric metric) {
    state = metric;
  }
}

final selectedWeeklyActivityMetricProvider =
    NotifierProvider<
      SelectedWeeklyActivityMetricNotifier,
      WeeklyActivityMetric
    >(
      SelectedWeeklyActivityMetricNotifier.new,
    );

final weeklyActivityDataProvider = FutureProvider<List<WeeklyActivityDay>>((
  ref,
) async {
  final metric = ref.watch(selectedWeeklyActivityMetricProvider);
  final db = ref.watch(appDatabaseProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startDate = today.subtract(const Duration(days: 6));

  final results =
      await (db.select(db.exerciseResults)
            ..where((t) => t.performedAt.isBiggerOrEqualValue(startDate))
            ..orderBy([(t) => OrderingTerm.asc(t.performedAt)]))
          .get();

  final byDay = <DateTime, double>{
    for (var i = 0; i < 7; i++) startDate.add(Duration(days: i)): 0,
  };

  for (final r in results) {
    final day = DateTime(
      r.performedAt.year,
      r.performedAt.month,
      r.performedAt.day,
    );
    if (day.isBefore(startDate) || day.isAfter(today)) continue;

    switch (metric) {
      case WeeklyActivityMetric.sessions:
        byDay[day] = (byDay[day] ?? 0) + 1;
      case WeeklyActivityMetric.minutes:
        byDay[day] = (byDay[day] ?? 0) + (r.durationSeconds / 60.0);
    }
  }

  final sortedDays = byDay.keys.toList()..sort();
  return sortedDays
      .map(
        (d) => WeeklyActivityDay(
          date: d,
          value: byDay[d] ?? 0,
          label: _formatEnglishWeekdayShort(d),
          isToday: d == today,
        ),
      )
      .toList();
});

String _formatEnglishWeekdayShort(DateTime date) {
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return en[date.weekday - 1];
}
