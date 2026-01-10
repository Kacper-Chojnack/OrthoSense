import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/database/repositories/exercise_results_repository.dart';
import 'package:orthosense/core/services/report_export_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'activity_log_screen.g.dart';

/// Filter type for Activity Log
enum ActivityFilter { all, thisWeek, thisMonth, pendingSync }

@riverpod
class ActivityFilterNotifier extends _$ActivityFilterNotifier {
  @override
  ActivityFilter build() => ActivityFilter.all;

  /// Sets the current filter for activity log
  void setFilter(ActivityFilter filter) {
    state = filter;
  }
}

/// Provider that watches exercise results stream from database
final exerciseResultsStreamProvider =
    StreamProvider.autoDispose<List<ExerciseResult>>(
      (ref) {
        final repository = ref.watch(exerciseResultsRepositoryProvider);
        return repository.watchAll();
      },
    );

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
          Consumer(
            builder: (context, ref, _) {
              final currentFilter = ref.watch(activityFilterProvider);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: currentFilter == ActivityFilter.all,
                      onSelected: (_) => ref
                          .read(activityFilterProvider.notifier)
                          .setFilter(ActivityFilter.all),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('This Week'),
                      selected: currentFilter == ActivityFilter.thisWeek,
                      onSelected: (_) => ref
                          .read(activityFilterProvider.notifier)
                          .setFilter(ActivityFilter.thisWeek),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('This Month'),
                      selected: currentFilter == ActivityFilter.thisMonth,
                      onSelected: (_) => ref
                          .read(activityFilterProvider.notifier)
                          .setFilter(ActivityFilter.thisMonth),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Pending Sync'),
                      selected: currentFilter == ActivityFilter.pendingSync,
                      onSelected: (_) => ref
                          .read(activityFilterProvider.notifier)
                          .setFilter(ActivityFilter.pendingSync),
                      avatar: Icon(
                        Icons.sync_problem_rounded,
                        size: 18,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Session list from database (SSOT)
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final AsyncValue<List<ExerciseResult>> resultsAsync = ref.watch(
                  exerciseResultsStreamProvider,
                );
                final filter = ref.watch(activityFilterProvider);

                return resultsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (Object error, StackTrace stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load sessions',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(exerciseResultsStreamProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (List<ExerciseResult> results) {
                    // Apply filter
                    final filteredResults = _applyFilter(results, filter);

                    if (filteredResults.isEmpty) {
                      return _buildEmptyState(colorScheme, results.isEmpty);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredResults.length,
                      itemBuilder: (context, index) => _SessionCard(
                        result: filteredResults[index],
                        colorScheme: colorScheme,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool noDataAtAll) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noDataAtAll ? Icons.fitness_center_outlined : Icons.filter_list_off,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            noDataAtAll
                ? 'No exercise sessions yet'
                : 'No sessions match this filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          if (noDataAtAll) ...[
            const SizedBox(height: 8),
            Text(
              'Complete an exercise to see your activity history',
              style: TextStyle(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  List<ExerciseResult> _applyFilter(
    List<ExerciseResult> results,
    ActivityFilter filter,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case ActivityFilter.all:
        return results;
      case ActivityFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return results.where((r) => r.performedAt.isAfter(weekStart)).toList();
      case ActivityFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month);
        return results.where((r) => r.performedAt.isAfter(monthStart)).toList();
      case ActivityFilter.pendingSync:
        return results.where((r) => r.syncStatus == 'pending').toList();
    }
  }

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    final exportService = ref.read(reportExportServiceProvider);

    // Get current results from stream
    final AsyncValue<List<ExerciseResult>> resultsAsync = ref.read(
      exerciseResultsStreamProvider,
    );
    final List<ExerciseResult>? results = resultsAsync.value;

    if (results == null || results.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No sessions to export. Complete some exercises first!',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Convert to SessionReportData
    final List<SessionReportData> sessions = results.map((ExerciseResult r) {
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
        case 'share':
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Preparing report to share...')),
            );
          }
          final pdfFile = await exportService.generateActivityLogPdf(
            sessions: sessions,
            startDate: sessions.last.date,
            endDate: sessions.first.date,
          );
          await exportService.sharePdf(
            pdfFile,
            subject: 'OrthoSense Activity Report - Share with Doctor',
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

class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.result,
    required this.colorScheme,
  });

  final ExerciseResult result;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = result.score ?? 0;
    final isPending = result.syncStatus == 'pending';
    final durationMinutes = (result.durationSeconds / 60).ceil();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSessionDetails(context, ref),
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
                          result.exerciseName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(result.performedAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                    value: '$durationMinutes min',
                  ),
                  _StatItem(
                    icon: Icons.check_circle_outline,
                    label: 'Form',
                    value: (result.isCorrect ?? false) ? 'Good' : 'Needs Work',
                  ),
                  _StatItem(
                    icon: Icons.trending_up,
                    label: 'Score',
                    value: '$score%',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sessionDate = DateTime(date.year, date.month, date.day);

    final timeFormat = DateFormat('h:mm a');
    final time = timeFormat.format(date);

    if (sessionDate == today) {
      return 'Today • $time';
    } else if (sessionDate == yesterday) {
      return 'Yesterday • $time';
    } else {
      final diff = today.difference(sessionDate).inDays;
      if (diff < 7) {
        return '$diff days ago • $time';
      }
      return DateFormat('MMM d').format(date);
    }
  }

  void _showSessionDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _SessionDetailsSheet(
          result: result,
          scrollController: scrollController,
          ref: ref,
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
  const _SessionDetailsSheet({
    required this.result,
    required this.scrollController,
    required this.ref,
  });

  final ExerciseResult result;
  final ScrollController scrollController;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat("EEEE 'at' h:mm a");
    final feedback = ExerciseResultsRepository.parseFeedback(
      result.feedbackJson,
    );
    final score = result.score ?? 0;
    final scoreColor = _getScoreColor(score);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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
                        dateFormat.format(result.performedAt),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _shareSession(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Exercise details
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                result.exerciseName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scoreColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$score%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _DetailChip(
                              icon: Icons.timer_outlined,
                              label:
                                  '${(result.durationSeconds / 60).ceil()} min',
                            ),
                            const SizedBox(width: 8),
                            _DetailChip(
                              icon: (result.isCorrect ?? false)
                                  ? Icons.check_circle
                                  : Icons.warning,
                              label: (result.isCorrect ?? false)
                                  ? 'Correct Form'
                                  : 'Needs Work',
                            ),
                          ],
                        ),
                        if (result.textReport != null &&
                            result.textReport!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            result.textReport!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        if (feedback.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Feedback',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          ...feedback.entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(
                                    child: Text(
                                      '${e.key}: ${e.value}',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Future<void> _shareSession(BuildContext context) async {
    final exportService = ref.read(reportExportServiceProvider);
    final feedback = ExerciseResultsRepository.parseFeedback(
      result.feedbackJson,
    );

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      final sessions = [
        SessionReportData(
          date: result.performedAt,
          exerciseName: result.exerciseName,
          durationSeconds: result.durationSeconds,
          score: result.score ?? 0,
          isCorrect: result.isCorrect ?? false,
          feedback: feedback,
          textReport: result.textReport,
        ),
      ];

      final pdfFile = await exportService.generateActivityLogPdf(
        sessions: sessions,
        startDate: result.performedAt,
        endDate: result.performedAt,
      );

      await exportService.sharePdf(
        pdfFile,
        subject: 'OrthoSense Session Report - ${result.exerciseName}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
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
