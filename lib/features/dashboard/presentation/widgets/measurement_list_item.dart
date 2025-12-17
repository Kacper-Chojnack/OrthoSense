import 'package:flutter/material.dart';
import 'package:orthosense/core/database/sync_status.dart';
import 'package:orthosense/features/measurements/domain/models/measurement_model.dart';

/// Displays a single measurement with its sync status.
/// Sync icons: pending=clock, synced=check, error=alert.
class MeasurementListItem extends StatelessWidget {
  const MeasurementListItem({
    required this.measurement,
    required this.syncStatus,
    super.key,
  });

  final MeasurementModel measurement;
  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildTypeIcon(context),
        title: Text(
          _formatType(measurement.type),
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTimestamp(measurement.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            _buildDataPreview(context),
          ],
        ),
        trailing: _buildSyncStatusIcon(colorScheme),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildTypeIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final iconData = switch (measurement.type) {
      'pose_analysis' => Icons.accessibility_new,
      'rom_measurement' => Icons.straighten,
      'exercise_session' => Icons.fitness_center,
      'balance_test' => Icons.balance,
      _ => Icons.data_object,
    };

    return CircleAvatar(
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(iconData, color: colorScheme.onPrimaryContainer),
    );
  }

  Widget _buildDataPreview(BuildContext context) {
    final theme = Theme.of(context);
    final preview = measurement.data.entries
        .take(2)
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    return Text(
      preview.isEmpty ? 'No data' : preview,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.outline,
        fontStyle: FontStyle.italic,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSyncStatusIcon(ColorScheme colorScheme) {
    return switch (syncStatus) {
      SyncStatus.pending => Tooltip(
          message: 'Pending sync',
          child: Icon(Icons.schedule, color: colorScheme.tertiary),
        ),
      SyncStatus.syncing => Tooltip(
          message: 'Syncing...',
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
        ),
      SyncStatus.synced => Tooltip(
          message: 'Synced',
          child: Icon(Icons.cloud_done, color: colorScheme.primary),
        ),
      SyncStatus.failed => Tooltip(
          message: 'Sync failed - tap to retry',
          child: Icon(Icons.error_outline, color: colorScheme.error),
        ),
    };
  }

  String _formatType(String type) {
    return type
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
