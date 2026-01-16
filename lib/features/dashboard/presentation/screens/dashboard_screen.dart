import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/dashboard_stats_provider.dart';
import 'package:orthosense/features/dashboard/presentation/providers/trend_provider.dart';
import 'package:orthosense/features/dashboard/presentation/screens/activity_log_screen.dart';
import 'package:orthosense/features/dashboard/presentation/widgets/progress_trend_chart.dart';
import 'package:orthosense/features/dashboard/presentation/widgets/weekly_activity_chart.dart';
import 'package:orthosense/features/exercise/presentation/screens/live_analysis_screen.dart';
import 'package:orthosense/widgets/offline_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(dashboardStatsProvider)
            ..invalidate(trendDataProvider)
            ..invalidate(weeklyActivityProvider);
          await Future.wait([
            ref.read(dashboardStatsProvider.future),
            ref.read(trendDataProvider.future),
            ref.read(weeklyActivityProvider.future),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: OfflineBanner()),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 16),
                  _QuickActions(),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Your Statistics'),
                  const SizedBox(height: 16),
                  const _StatsGrid(),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Progress Trend',
                    action: _TrendPeriodSelector(),
                  ),
                  const SizedBox(height: 16),
                  const ProgressTrendChart(),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Weekly Activity'),
                  const SizedBox(height: 16),
                  const WeeklyActivityChart(),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Recent Sessions',
                    action: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ActivityLogScreen(),
                        ),
                      ),
                      child: const Text('See All'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _RecentSessionsList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const LiveAnalysisScreen(),
              ),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Session'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ActivityLogScreen(),
              ),
            ),
            icon: const Icon(Icons.history),
            label: const Text('View History'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendPeriodSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(trendPeriodProvider);

    return SegmentedButton<TrendPeriod>(
      segments: const [
        ButtonSegment(
          value: TrendPeriod.week,
          label: Text('Week'),
        ),
        ButtonSegment(
          value: TrendPeriod.month,
          label: Text('Month'),
        ),
        ButtonSegment(
          value: TrendPeriod.year,
          label: Text('Year'),
        ),
      ],
      selected: {period},
      onSelectionChanged: (Set<TrendPeriod> selection) {
        ref.read(trendPeriodProvider.notifier).state = selection.first;
      },
      style: ButtonStyle(
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _RecentSessionsList extends ConsumerWidget {
  const _RecentSessionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (stats) {
        if (stats.recentSessions.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No recent sessions',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return Column(
          children: stats.recentSessions
              .take(5)
              .map(
                (session) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        _getExerciseIcon(session.exerciseName),
                      ),
                    ),
                    title: Text(session.exerciseName),
                    subtitle: Text(
                      _formatDate(session.date),
                    ),
                    trailing: _SessionScore(score: session.score),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    return Icons.fitness_center;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SessionScore extends StatelessWidget {
  const _SessionScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$score',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.action,
  });

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (stats) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _StatCard(
            title: 'Total Sessions',
            value: '${stats.totalSessions}',
            icon: Icons.fitness_center,
            color: Colors.blue,
          ),
          _StatCard(
            title: 'Avg Score',
            value: '${stats.averageScore.round()}',
            icon: Icons.star,
            color: Colors.amber,
          ),
          _StatCard(
            title: 'Best Streak',
            value: '${stats.bestStreak} days',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
          _StatCard(
            title: 'Total Time',
            value: '${(stats.totalDuration / 60).round()}m',
            icon: Icons.timer,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
