import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/auth/presentation/screens/profile_screen.dart';
import 'package:orthosense/features/camera/presentation/screens/camera_screen.dart';
import 'package:orthosense/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:orthosense/features/dashboard/presentation/widgets/empty_measurements_view.dart';
import 'package:orthosense/features/dashboard/presentation/widgets/measurement_list_item.dart';
import 'package:orthosense/features/dashboard/presentation/widgets/sync_status_indicator.dart';
import 'package:orthosense/features/measurements/presentation/providers/sync_controller.dart';
import 'package:orthosense/features/measurements/presentation/widgets/add_measurement_dialog.dart';

/// Main dashboard screen displaying measurements list.
/// Implements SSOT pattern: UI observes Drift stream, not API.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user ID from auth provider, fallback to demo for testing
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? 'demo_user_001';

    final measurementsAsync =
        ref.watch(dashboardMeasurementsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('OrthoSense'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profile',
          onPressed: () => _openProfile(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: SyncStatusIndicator(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(ref),
        child: measurementsAsync.when(
          data: (measurements) => measurements.isEmpty
              ? _buildEmptyScrollable()
              : _buildMeasurementsList(measurements),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorView(context, error, ref, userId),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: () => _openCamera(context),
            child: const Icon(Icons.videocam),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _showAddDialog(context, userId),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  /// Wraps empty view in scrollable for RefreshIndicator to work.
  Widget _buildEmptyScrollable() {
    return const CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: EmptyMeasurementsView(),
        ),
      ],
    );
  }

  Widget _buildMeasurementsList(List<MeasurementWithStatus> measurements) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final item = measurements[index];
        return MeasurementListItem(
          measurement: item.measurement,
          syncStatus: item.syncStatus,
        );
      },
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    Object error,
    WidgetRef ref,
    String userId,
  ) {
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.tonalIcon(
                    onPressed: () => ref.invalidate(
                      dashboardMeasurementsProvider(userId),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRefresh(WidgetRef ref) async {
    final controller = ref.read(syncControllerProvider.notifier);
    await controller.syncNow();
  }

  void _showAddDialog(BuildContext context, String userId) {
    showDialog<bool>(
      context: context,
      builder: (context) => AddMeasurementDialog(
        userId: userId,
      ),
    );
  }

  void _openCamera(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CameraScreen(),
      ),
    );
  }
}
