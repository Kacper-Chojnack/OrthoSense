import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/auth/domain/models/user_model.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/auth/presentation/screens/profile_screen.dart';
import 'package:orthosense/features/dashboard/presentation/screens/activity_log_screen.dart';
import 'package:orthosense/features/exercise/presentation/screens/exercise_selection_screen.dart';

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
          icon: Image.asset('assets/images/logo.png', height: 24),
          tooltip: 'Profile',
          onPressed: () => _openProfile(context),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/logo.png', height: 24),
            tooltip: 'Activity Log',
            onPressed: () => _openActivityLog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO(user): Refresh stats from database
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
              _SectionHeader(
                title: 'Your Progress',
                action: TextButton(
                  onPressed: () => _openActivityLog(context),
                  child: const Text('See All'),
                ),
              ),
              const SizedBox(height: 12),
              const _StatsGrid(),
              const SizedBox(height: 24),

              // Weekly Trend Chart Placeholder
              const _SectionHeader(
                title: 'Range of Motion Trend',
                subtitle: 'Last 7 days',
              ),
              const SizedBox(height: 12),
              const _TrendChart(),
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
        icon: Image.asset('assets/images/logo.png', height: 24),
        label: const Text('Start Session'),
      ),
    );
  }

  void _startSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExerciseSelectionScreen()),
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
    final displayName = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName
        : (user?.email.split('@').first ?? 'User');

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        ?action,
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    // Mock data - will be replaced with Drift stream
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          label: 'Sessions',
          value: '12',
          trend: '+3 this week',
          color: Colors.blue,
        ),
        _StatCard(
          label: 'Avg Score',
          value: '87%',
          trend: '+5% vs last week',
          color: Colors.green,
        ),
        _StatCard(
          label: 'Active Streak',
          value: '3',
          trend: 'days',
          color: Colors.orange,
        ),
        _StatCard(
          label: 'Total Time',
          value: '4h 20m',
          trend: 'this month',
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
  });

  final String label;
  final String value;
  final String trend;
  final Color color;

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
            Image.asset('assets/images/logo.png', height: 20, color: color),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              trend,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context) {
    // Mock ROM trend data - will integrate with fl_chart later
    final mockData = [105, 108, 110, 112, 115, 118, 120];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chart area
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(mockData.length, (index) {
                  final value = mockData[index];
                  const maxValue = 130;
                  final height = (value / maxValue) * 100;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$value°',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            // Day labels
            Row(
              children: days
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 20,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  '+15° improvement this week',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList();

  @override
  Widget build(BuildContext context) {
    // Mock data - will be replaced with Drift stream
    return const Column(
      children: [
        _RecentSessionTile(
          title: 'Knee Rehabilitation',
          subtitle: 'Today • 25 mins',
          score: 92,
          isPending: true,
        ),
        _RecentSessionTile(
          title: 'Full Leg Workout',
          subtitle: 'Yesterday • 30 mins',
          score: 88,
          isPending: false,
        ),
        _RecentSessionTile(
          title: 'Knee Rehabilitation',
          subtitle: '2 days ago • 22 mins',
          score: 85,
          isPending: false,
        ),
      ],
    );
  }
}

class _RecentSessionTile extends StatelessWidget {
  const _RecentSessionTile({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.isPending,
  });

  final String title;
  final String subtitle;
  final int score;
  final bool isPending;

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
        trailing: isPending
            ? Tooltip(
                message: 'Pending sync',
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            : Image.asset(
                'assets/images/logo.png',
                height: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        onTap: () {
          // TODO(user): Open session details
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
