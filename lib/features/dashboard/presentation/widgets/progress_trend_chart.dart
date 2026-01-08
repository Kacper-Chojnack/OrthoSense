import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';
import 'package:orthosense/features/dashboard/presentation/providers/trend_provider.dart';

/// Advanced trend chart widget for progress visualization (F08).
/// Supports 7, 30, and 90-day period selection with interactive features.
class ProgressTrendChart extends ConsumerWidget {
  const ProgressTrendChart({
    required this.metricType,
    this.height = 220,
    super.key,
  });

  final TrendMetricType metricType;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedTrendPeriodProvider);
    final trendData = ref.watch(trendDataProvider(metricType));

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and period selector
            _ChartHeader(
              title: metricType.displayName,
              selectedPeriod: selectedPeriod,
              onPeriodChanged: (period) => ref
                  .read(selectedTrendPeriodProvider.notifier)
                  .setPeriod(period),
            ),
            const SizedBox(height: 16),

            // Chart content
            trendData.when(
              data: (data) => _ChartContent(
                data: data,
                height: height,
              ),
              loading: () => SizedBox(
                height: height,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SizedBox(
                height: height,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load trend data',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({
    required this.title,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final String title;
  final TrendPeriod selectedPeriod;
  final ValueChanged<TrendPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              selectedPeriod.longLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        _PeriodSelector(
          selectedPeriod: selectedPeriod,
          onPeriodChanged: onPeriodChanged,
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final TrendPeriod selectedPeriod;
  final ValueChanged<TrendPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TrendPeriod>(
      segments: TrendPeriod.values
          .map(
            (period) => ButtonSegment<TrendPeriod>(
              value: period,
              label: Text(
                period.shortLabel,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
          .toList(),
      selected: {selectedPeriod},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onPeriodChanged(selection.first);
        }
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

class _ChartContent extends StatelessWidget {
  const _ChartContent({
    required this.data,
    required this.height,
  });

  final TrendChartData data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.dataPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No data available for this period',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete some sessions to see your progress',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Stats summary row
        _StatsSummaryRow(data: data),
        const SizedBox(height: 16),

        // Line chart
        SizedBox(
          height: height - 50,
          child: _LineChart(data: data),
        ),
      ],
    );
  }
}

class _StatsSummaryRow extends StatelessWidget {
  const _StatsSummaryRow({required this.data});

  final TrendChartData data;

  @override
  Widget build(BuildContext context) {
    final change = data.changePercent ?? 0;
    final isPositive = change >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _MiniStat(
          label: 'Average',
          value:
              '${data.averageValue?.toStringAsFixed(1) ?? '-'}${data.metricType.unit}',
        ),
        _MiniStat(
          label: 'Change',
          value:
              '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}${data.metricType.unit}',
          valueColor: changeColor,
          icon: isPositive ? Icons.trending_up : Icons.trending_down,
          iconColor: changeColor,
        ),
        _MiniStat(
          label: 'Sessions',
          value: '${data.dataPoints.length}',
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 2),
            ],
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.data});

  final TrendChartData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spots = data.dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    // Calculate y-axis bounds with padding
    final values = data.dataPoints.map((p) => p.value).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) * 0.9).floorToDouble();
    final maxY = (values.reduce((a, b) => a > b ? a : b) * 1.1).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        titlesData: _buildTitlesData(context, minY, maxY),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.dataPoints.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: _buildTouchData(context),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isHighlighted = data.dataPoints[index].isHighlighted;
                return FlDotCirclePainter(
                  radius: isHighlighted ? 6 : 4,
                  color: isHighlighted
                      ? colorScheme.tertiary
                      : colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.3),
                  colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  FlTitlesData _buildTitlesData(
    BuildContext context,
    double minY,
    double maxY,
  ) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: (maxY - minY) / 4,
          getTitlesWidget: (value, meta) {
            return Text(
              '${value.toInt()}${data.metricType.unit}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: _calculateInterval(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < data.dataPoints.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  data.dataPoints[index].label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
    );
  }

  double _calculateInterval() {
    final count = data.dataPoints.length;
    if (count <= 7) return 1;
    if (count <= 30) return 5;
    return 10;
  }

  LineTouchData _buildTouchData(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => colorScheme.inverseSurface,
        tooltipRoundedRadius: 8,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final index = spot.x.toInt();
            final point = data.dataPoints[index];
            final dateFormat = DateFormat('MMM d');

            return LineTooltipItem(
              '${dateFormat.format(point.date)}\n',
              TextStyle(
                color: colorScheme.onInverseSurface,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                  text:
                      '${point.value.toStringAsFixed(1)}${data.metricType.unit}',
                  style: TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
      touchCallback: (event, response) {
        // Can be used to handle tap events
      },
    );
  }
}

/// Compact trend mini-chart for stats cards.
class TrendMiniChart extends StatelessWidget {
  const TrendMiniChart({
    required this.dataPoints,
    this.color,
    this.height = 40,
    this.width = 80,
    super.key,
  });

  final List<double> dataPoints;
  final Color? color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty || dataPoints.length < 2) {
      return SizedBox(height: height, width: width);
    }

    final chartColor = color ?? Theme.of(context).colorScheme.primary;
    final spots = dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final minY = dataPoints.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY = dataPoints.reduce((a, b) => a > b ? a : b) * 1.1;

    return SizedBox(
      height: height,
      width: width,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: chartColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: chartColor.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
