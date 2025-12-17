import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/measurements/presentation/providers/measurement_stream_providers.dart';
import 'package:orthosense/features/measurements/presentation/providers/sync_controller.dart';

/// Displays global sync status (Syncing..., Online/Offline) in AppBar.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncControllerProvider);
    final pendingCountAsync = ref.watch(pendingMeasurementsCountProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(syncStatus.state, context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(syncStatus.state, context),
          const SizedBox(width: 8),
          _buildText(syncStatus, pendingCountAsync, context),
        ],
      ),
    );
  }

  Widget _buildIcon(SyncState state, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (state) {
      SyncState.idle => Icon(
          Icons.cloud_done,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      SyncState.syncing => SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      SyncState.success => Icon(
          Icons.check_circle,
          size: 16,
          color: colorScheme.primary,
        ),
      SyncState.error => Icon(
          Icons.error_outline,
          size: 16,
          color: colorScheme.error,
        ),
    };
  }

  Widget _buildText(
    SyncStatusInfo status,
    AsyncValue<int> pendingCount,
    BuildContext context,
  ) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _getTextColor(status.state, context),
        );

    if (status.state == SyncState.syncing) {
      return Text('Syncing...', style: textStyle);
    }

    if (status.state == SyncState.error) {
      return Text('Error', style: textStyle);
    }

    return pendingCount.when(
      data: (count) => Text(
        count > 0 ? '$count pending' : 'Synced',
        style: textStyle,
      ),
      loading: () => Text('...', style: textStyle),
      error: (_, __) => Text('Error', style: textStyle),
    );
  }

  Color _getBackgroundColor(SyncState state, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (state) {
      SyncState.idle => colorScheme.surfaceContainerHighest,
      SyncState.syncing => colorScheme.primaryContainer,
      SyncState.success => colorScheme.primaryContainer,
      SyncState.error => colorScheme.errorContainer,
    };
  }

  Color _getTextColor(SyncState state, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (state) {
      SyncState.idle => colorScheme.onSurfaceVariant,
      SyncState.syncing => colorScheme.onPrimaryContainer,
      SyncState.success => colorScheme.onPrimaryContainer,
      SyncState.error => colorScheme.onErrorContainer,
    };
  }
}
