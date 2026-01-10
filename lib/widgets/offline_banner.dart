import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/sync_providers.dart';
import 'package:orthosense/core/services/sync/sync_state.dart';

/// Banner displayed when app is offline or has sync issues.
///
/// Wraps child widget and shows a banner at the top when offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _buildBanner(context, ref, syncState),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildBanner(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
  ) {
    if (syncState.status == SyncStatus.offline) {
      return _OfflineBannerContent(
        message: 'You are offline. Changes will sync when connected.',
        icon: Icons.signal_wifi_off_outlined,
        onRetry: () => ref.read(syncProvider.notifier).sync(),
      );
    }

    if (syncState.status == SyncStatus.error) {
      return _OfflineBannerContent(
        message: syncState.errorMessage ?? 'Sync error occurred.',
        icon: Icons.cloud_off_outlined,
        isError: true,
        onRetry: () => ref.read(syncProvider.notifier).retryFailed(),
      );
    }

    return const SizedBox.shrink();
  }
}

class _OfflineBannerContent extends StatelessWidget {
  const _OfflineBannerContent({
    required this.message,
    required this.icon,
    this.isError = false,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isError
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainerHigh;
    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foregroundColor,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: foregroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A smaller inline indicator for sync status.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (syncState.status == SyncStatus.idle && !syncState.hasPendingItems) {
      return const SizedBox.shrink();
    }

    final (icon, color, label) = _getStatusDisplay(syncState, colorScheme);

    return Chip(
      avatar: syncState.status == SyncStatus.syncing
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          : Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontSize: 12),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
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
        'Error',
      ),
      SyncStatus.offline => (
        Icons.signal_wifi_off_outlined,
        colorScheme.outline,
        'Offline',
      ),
    };
  }
}
