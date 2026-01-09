import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/sync_providers.dart';
import 'package:orthosense/core/services/sync/sync_state.dart';

/// Widget showing current sync status with icon and optional label.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({
    super.key,
    this.showLabel = true,
    this.size = 20.0,
    this.compact = false,
  });

  /// Whether to show the status label.
  final bool showLabel;

  /// Size of the icon.
  final double size;

  /// Whether to use compact layout.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color, label) = _getStatusDisplay(syncState, colorScheme);

    if (compact) {
      return _buildCompactIndicator(icon, color, syncState);
    }

    if (!showLabel) {
      return _buildIcon(icon, color, syncState.status == SyncStatus.syncing);
    }

    return InkWell(
      onTap: () => _showSyncDetails(context, ref, syncState),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(icon, color, syncState.status == SyncStatus.syncing),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _getStatusDisplay(
    SyncState state,
    ColorScheme colorScheme,
  ) {
    return switch (state.status) {
      SyncStatus.idle when state.hasPendingItems => (
        Icons.cloud_upload_outlined,
        colorScheme.tertiary,
        '${state.pendingCount} pending',
      ),
      SyncStatus.idle => (
        Icons.cloud_done_outlined,
        colorScheme.primary,
        'Synced',
      ),
      SyncStatus.syncing => (
        Icons.sync,
        colorScheme.secondary,
        'Syncing...',
      ),
      SyncStatus.error => (
        Icons.cloud_off_outlined,
        colorScheme.error,
        'Sync error',
      ),
      SyncStatus.offline => (
        Icons.signal_wifi_off_outlined,
        colorScheme.outline,
        'Offline',
      ),
    };
  }

  Widget _buildCompactIndicator(IconData icon, Color color, SyncState state) {
    return Stack(
      children: [
        _buildIcon(icon, color, state.status == SyncStatus.syncing),
        if (state.hasPendingItems)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                '${state.pendingCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIcon(IconData icon, Color color, bool animate) {
    final iconWidget = Icon(icon, color: color, size: size);

    if (animate) {
      return _RotatingIcon(icon: iconWidget);
    }

    return iconWidget;
  }

  void _showSyncDetails(
    BuildContext context,
    WidgetRef ref,
    SyncState state,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _SyncDetailsSheet(state: state),
    );
  }
}

class _RotatingIcon extends StatefulWidget {
  const _RotatingIcon({required this.icon});

  final Widget icon;

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.icon,
    );
  }
}

class _SyncDetailsSheet extends ConsumerWidget {
  const _SyncDetailsSheet({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isOnline
                      ? Icons.wifi_outlined
                      : Icons.wifi_off_outlined,
                  color: state.isOnline
                      ? colorScheme.primary
                      : colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  state.isOnline ? 'Online' : 'Offline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Pending items',
              '${state.pendingCount}',
              Icons.cloud_upload_outlined,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Failed items',
              '${state.failedCount}',
              Icons.error_outline,
            ),
            if (state.lastSyncAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                'Last synced',
                _formatTime(state.lastSyncAt!),
                Icons.schedule_outlined,
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.hasFailedItems
                        ? () {
                            ref.read(syncProvider.notifier).retryFailed();
                            Navigator.pop(context);
                          }
                        : null,
                    icon: const Icon(Icons.replay_outlined),
                    label: const Text('Retry Failed'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.canSync
                        ? () {
                            ref.read(syncProvider.notifier).forceSyncNow();
                            Navigator.pop(context);
                          }
                        : null,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
