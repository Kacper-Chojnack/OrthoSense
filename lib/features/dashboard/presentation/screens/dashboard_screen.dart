import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/auth/domain/models/user_model.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/auth/presentation/screens/profile_screen.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';
import 'package:orthosense/features/dashboard/presentation/providers/trend_provider.dart';
import 'package:orthosense/features/dashboard/presentation/screens/activity_log_screen.dart';
import 'package:orthosense/features/dashboard/presentation/widgets/progress_trend_chart.dart';
import 'package:orthosense/features/dashboard/presentation/widgets/weekly_activity_chart.dart';
import 'package:orthosense/features/exercise/presentation/screens/exercise_catalog_screen.dart';
import 'package:orthosense/features/exercise/presentation/screens/gallery_analysis_screen.dart';
import 'package:orthosense/features/exercise/presentation/screens/live_analysis_screen.dart';

/// Main dashboard screen with analytics overview and quick actions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OrthoSense'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          tooltip: 'Profile',
          onPressed: () => _openProfile(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Exercise Catalog',
            onPressed: () => _openExerciseCatalog(context),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Activity Log',
            onPressed: () => _openActivityLog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentExerciseResultsProvider);
          // Invalidate chart providers to refresh charts
          ref.invalidate(weeklyActivityDataProvider);
          ref.invalidate(trendDataProvider(TrendMetricType.sessionScore));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _WelcomeHeader(user: user),
              const SizedBox(height: 24),

              // Stats Overview
              const _SectionHeader(
                title: 'Your Progress',
              ),
              const SizedBox(height: 12),
              const _StatsGrid(),
              const SizedBox(height: 24),

              // Weekly Activity (Consistency)
              const WeeklyActivityChart(),
              const SizedBox(height: 16),

              // Session Score Trend Chart (F08)
              const ProgressTrendChart(
                metricType: TrendMetricType.sessionScore,
              ),
              const SizedBox(height: 24),

              // Recent Sessions
              _SectionHeader(
                title: 'Recent Sessions',
                action: TextButton(
                  onPressed: () => _openActivityLog(context),
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(height: 12),
              const _RecentSessionsList(),
              const SizedBox(height: 80), // FAB clearance
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startSession(context),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start Session'),
      ),
    );
  }

  void _startSession(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Analysis Method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Gallery Analysis - Primary option
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GalleryAnalysisScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.video_library),
                label: const Text('Analyze from Gallery'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LiveAnalysisScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Live Camera Analysis'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openExerciseCatalog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExerciseCatalogScreen()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  void _openActivityLog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ActivityLogScreen()),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.email.split('@').first ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          displayName,
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
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _StatCard(
            label: 'Sessions',
            value: stats.totalSessions.toString(),
            trend: stats.sessionsThisWeek > 0
                ? '+${stats.sessionsThisWeek} this week'
                : 'No sessions yet',
            color: Colors.blue,
            icon: Icons.fitness_center_rounded,
          ),
          _StatCard(
            label: 'Avg Score',
            value: stats.totalSessions > 0
                ? '${stats.averageScore.toStringAsFixed(0)}%'
                : '--',
            trend: stats.scoreChange != 0
                ? '${stats.scoreChange >= 0 ? '+' : ''}${stats.scoreChange.toStringAsFixed(1)} vs last week'
                : 'Complete a session',
            color: Colors.green,
            icon: Icons.trending_up_rounded,
          ),
          _StatCard(
            label: 'Active Streak',
            value: stats.activeStreakDays.toString(),
            trend: 'days',
            color: Colors.orange,
            icon: Icons.local_fire_department_rounded,
          ),
          _StatCard(
            label: 'Total Time',
            value: _formatDuration(stats.totalTimeThisMonth),
            trend: 'this month',
            color: Colors.purple,
            icon: Icons.timer_outlined,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes == 0) return '0m';
    if (duration.inHours == 0) return '${duration.inMinutes}m';
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String trend;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Flexible(
              child: Text(
                trend,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionsList extends ConsumerWidget {
  const _RecentSessionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(recentExerciseResultsProvider);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error loading sessions: $error'),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return _buildEmptyState(context);
        }
        return Column(
          children: results
              .take(5)
              .map(
                (result) => _RecentSessionTile(
                  title: result.exerciseName,
                  subtitle: _formatDate(result.performedAt),
                  score: result.score ?? 0,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No sessions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start your first exercise session to see your progress here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _RecentSessionTile extends StatelessWidget {
  const _RecentSessionTile({
    required this.title,
    required this.subtitle,
    required this.score,
  });

  final String title;
  final String subtitle;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getScoreColor(score).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getScoreColor(score),
              ),
            ),
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.directions_run,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ActivityLogScreen(),
            ),
          );
        },
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
