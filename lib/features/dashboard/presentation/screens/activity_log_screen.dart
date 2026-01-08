import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/database/repositories/exercise_results_repository.dart';
import 'package:orthosense/core/services/report_export_service.dart';

/// Screen showing history of exercise sessions (Activity Log).
/// Data flows from Drift database (SSOT) via Riverpod providers.
class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Export Options',
            onSelected: (value) => _handleExport(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Export as PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart_outlined),
                  title: Text('Export as CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Share with Doctor'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: true,
                  onSelected: (_) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('This Week'),
                  onSelected: (_) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('This Month'),
                  onSelected: (_) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending Sync'),
                  onSelected: (_) {},
                  avatar: Icon(
                    Icons.sync_problem_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Session list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 8, // Mock count - will be replaced with Drift stream
              itemBuilder: (context, index) =>
                  _SessionCard(index: index, colorScheme: colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    final exportService = ref.read(reportExportServiceProvider);
    final repository = ref.read(exerciseResultsRepositoryProvider);

    // Get sessions from database
    final results = await repository.getRecent(limit: 100);

    if (results.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sessions to export')),
        );
      }
      return;
    }

    // Convert to SessionReportData
    final sessions = results.map((r) {
      return SessionReportData(
        date: r.performedAt,
        exerciseName: r.exerciseName,
        durationSeconds: r.durationSeconds,
        score: r.score ?? 0,
        isCorrect: r.isCorrect ?? false,
        feedback: ExerciseResultsRepository.parseFeedback(r.feedbackJson),
        textReport: r.textReport,
      );
    }).toList();

    try {
      switch (type) {
        case 'pdf':
        case 'share':
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generating PDF...')),
            );
          }
          final pdfFile = await exportService.generateActivityLogPdf(
            sessions: sessions,
            startDate: sessions.last.date,
            endDate: sessions.first.date,
          );
          await exportService.sharePdf(
            pdfFile,
            subject: 'OrthoSense Activity Report',
          );
        case 'csv':
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generating CSV...')),
            );
          }
          final csvFile = await exportService.generateActivityLogCsv(
            sessions: sessions,
          );
          await exportService.shareCsv(csvFile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.index,
    required this.colorScheme,
  });

  final int index;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // Mock data - will be replaced with real Session model
    final isPending = index == 0;
    final score = 85 + (index * 2) % 15;
    final daysAgo = index;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSessionDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Score indicator
                  Container(
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(score),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Session info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Knee Rehabilitation',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDateString(daysAgo),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Sync status
                  if (isPending)
                    Tooltip(
                      message: 'Pending sync',
                      child: Icon(
                        Icons.cloud_off,
                        color: colorScheme.error,
                        size: 20,
                      ),
                    )
                  else
                    Icon(
                      Icons.cloud_done,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: '${20 + index * 2} min',
                  ),
                  _StatItem(
                    icon: Icons.repeat,
                    label: 'Exercises',
                    value: '${4 + index % 3}',
                  ),
                  _StatItem(
                    icon: Icons.trending_up,
                    label: 'ROM',
                    value: '${110 + index * 5}°',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getDateString(int daysAgo) {
    if (daysAgo == 0) return 'Today • 10:30 AM';
    if (daysAgo == 1) return 'Yesterday • 09:15 AM';
    return '$daysAgo days ago • 11:00 AM';
  }

  void _showSessionDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _SessionDetailsSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SessionDetailsSheet extends StatelessWidget {
  const _SessionDetailsSheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Today at 10:30 AM',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Exercise list
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: const [
                _ExerciseResultTile(
                  name: 'Knee Flexion',
                  score: 92,
                  reps: '3x10',
                  rom: '125°',
                  feedback: 'Excellent form! Range of motion improved.',
                ),
                _ExerciseResultTile(
                  name: 'Quad Stretch',
                  score: 88,
                  reps: '3x30s',
                  rom: '110°',
                  feedback: 'Good progress. Keep the hold steady.',
                ),
                _ExerciseResultTile(
                  name: 'Heel Slides',
                  score: 85,
                  reps: '2x15',
                  rom: '115°',
                  feedback: 'Smooth movement. Try to extend a bit more.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseResultTile extends StatelessWidget {
  const _ExerciseResultTile({
    required this.name,
    required this.score,
    required this.reps,
    required this.rom,
    required this.feedback,
  });

  final String name;
  final int score;
  final String reps;
  final String rom;
  final String feedback;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$score%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _DetailChip(icon: Icons.repeat, label: reps),
                const SizedBox(width: 8),
                _DetailChip(icon: Icons.straighten, label: rom),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              feedback,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
