import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/dashboard/presentation/providers/trend_provider.dart';

/// Bar chart showing last 7 days activity (consistency).
/// Displays either number of sessions or minutes spent exercising.
class WeeklyActivityChart extends ConsumerWidget {
  const WeeklyActivityChart({
    this.height = 220,
    super.key,
  });

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(selectedWeeklyActivityMetricProvider);
    final dataAsync = ref.watch(weeklyActivityDataProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(metric: metric),
            const SizedBox(height: 16),
            dataAsync.when(
              loading: () => SizedBox(
                height: height,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SizedBox(
                height: height,
                child: Center(
                  child: Text(
                    'Failed to load activity data: $error',
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (days) {
                final totalValue =
                    days.fold<double>(0, (sum, d) => sum + d.value);
                if (totalValue <= 0) {
                  return SizedBox(
                    height: height,
                    child: Center(
                      child: Text(
                        'No activity in the last 7 days',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                final maxValue =
                    days.map((d) => d.value).fold<double>(0, math.max);
                final maxY = _maxY(maxValue);
                final interval = _yInterval(maxY);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(metric: metric, days: days),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: height - 36,
                      child: BarChart(
                        BarChartData(
                          minY: 0,
                          maxY: maxY,
                          alignment: BarChartAlignment.spaceAround,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: interval,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color:
                                  theme.colorScheme.outlineVariant.withOpacity(
                                0.35,
                              ),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 34,
                                interval: interval,
                                getTitlesWidget: (value, meta) => Text(
                                  value.toInt().toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= days.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final isToday = days[idx].isToday;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      days[idx].label,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: isToday
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isToday
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final day = days[group.x.toInt()];
                                final suffix =
                                    metric == WeeklyActivityMetric.sessions
                                        ? ' sessions'
                                        : ' min';
                                final value =
                                    metric == WeeklyActivityMetric.sessions
                                        ? day.value.toInt().toString()
                                        : day.value.toStringAsFixed(0);
                                return BarTooltipItem(
                                  '${day.label}: $value$suffix',
                                  TextStyle(
                                    color: theme.colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                          barGroups: List.generate(days.length, (i) {
                            final day = days[i];
                            final color = day.isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: day.value,
                                  width: 14,
                                  borderRadius: BorderRadius.circular(4),
                                  color: color,
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _maxY(double maxValue) {
    if (maxValue <= 0) return 10;
    return (maxValue * 1.2).ceilToDouble().clamp(1, double.infinity);
  }

  double _yInterval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 20) return 5;
    if (maxY <= 60) return 10;
    return 20;
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.metric});

  final WeeklyActivityMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Activity',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Last 7 days',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SegmentedButton<WeeklyActivityMetric>(
          segments: const [
            ButtonSegment(
              value: WeeklyActivityMetric.sessions,
              label: Text('Sessions'),
            ),
            ButtonSegment(
              value: WeeklyActivityMetric.minutes,
              label: Text('Minutes'),
            ),
          ],
          selected: {metric},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            ref
                .read(selectedWeeklyActivityMetricProvider.notifier)
                .setMetric(selection.first);
          },
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.metric, required this.days});

  final WeeklyActivityMetric metric;
  final List<WeeklyActivityDay> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = days.fold<double>(0, (sum, d) => sum + d.value);

    final label = metric == WeeklyActivityMetric.sessions
        ? 'Total sessions (7 days)'
        : 'Total minutes (7 days)';
    final value = metric == WeeklyActivityMetric.sessions
        ? total.toInt().toString()
        : total.toStringAsFixed(0);

    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}


