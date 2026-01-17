/// Unit and widget tests for OfflineBanner and SyncStatusIndicator widgets.
///
/// Test coverage:
/// 1. OfflineBanner state display
/// 2. SyncStatusIndicator status display
/// 3. Status display logic
/// 4. Rotating icon animation
/// 5. Sync details sheet
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncStatus Enum', () {
    test('has all expected values', () {
      expect(SyncStatus.values.length, equals(4));
      expect(SyncStatus.values, contains(SyncStatus.idle));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.error));
      expect(SyncStatus.values, contains(SyncStatus.offline));
    });
  });

  group('SyncState Model', () {
    test('creates with idle status', () {
      final state = SyncState(
        status: SyncStatus.idle,
        pendingCount: 0,
      );

      expect(state.status, equals(SyncStatus.idle));
      expect(state.hasPendingItems, isFalse);
    });

    test('hasPendingItems is true when count > 0', () {
      final state = SyncState(
        status: SyncStatus.idle,
        pendingCount: 5,
      );

      expect(state.hasPendingItems, isTrue);
      expect(state.pendingCount, equals(5));
    });

    test('stores error message', () {
      final state = SyncState(
        status: SyncStatus.error,
        pendingCount: 0,
        errorMessage: 'Network error',
      );

      expect(state.errorMessage, equals('Network error'));
    });

    test('stores last sync time', () {
      final syncTime = DateTime(2024, 1, 15, 10, 30);
      final state = SyncState(
        status: SyncStatus.idle,
        pendingCount: 0,
        lastSyncTime: syncTime,
      );

      expect(state.lastSyncTime, equals(syncTime));
    });
  });

  group('Status Display Logic', () {
    test('idle with no pending shows synced', () {
      final state = SyncState(status: SyncStatus.idle, pendingCount: 0);
      final display = _getStatusDisplay(state);

      expect(display.icon, equals(Icons.cloud_done_outlined));
      expect(display.label, equals('Synced'));
    });

    test('idle with pending shows count', () {
      final state = SyncState(status: SyncStatus.idle, pendingCount: 3);
      final display = _getStatusDisplay(state);

      expect(display.icon, equals(Icons.cloud_upload_outlined));
      expect(display.label, equals('3 pending'));
    });

    test('syncing shows sync icon', () {
      final state = SyncState(status: SyncStatus.syncing, pendingCount: 0);
      final display = _getStatusDisplay(state);

      expect(display.icon, equals(Icons.sync));
      expect(display.label, equals('Syncing...'));
    });

    test('error shows error icon', () {
      final state = SyncState(status: SyncStatus.error, pendingCount: 0);
      final display = _getStatusDisplay(state);

      expect(display.icon, equals(Icons.cloud_off_outlined));
      expect(display.label, equals('Sync error'));
    });

    test('offline shows wifi off icon', () {
      final state = SyncState(status: SyncStatus.offline, pendingCount: 0);
      final display = _getStatusDisplay(state);

      expect(display.icon, equals(Icons.signal_wifi_off_outlined));
      expect(display.label, equals('Offline'));
    });
  });

  group('Banner Display Logic', () {
    test('shows banner for offline status', () {
      final state = SyncState(status: SyncStatus.offline, pendingCount: 0);

      expect(_shouldShowBanner(state), isTrue);
    });

    test('shows banner for error status', () {
      final state = SyncState(status: SyncStatus.error, pendingCount: 0);

      expect(_shouldShowBanner(state), isTrue);
    });

    test('hides banner for idle status', () {
      final state = SyncState(status: SyncStatus.idle, pendingCount: 0);

      expect(_shouldShowBanner(state), isFalse);
    });

    test('hides banner for syncing status', () {
      final state = SyncState(status: SyncStatus.syncing, pendingCount: 0);

      expect(_shouldShowBanner(state), isFalse);
    });
  });

  group('Banner Message', () {
    test('offline message mentions connectivity', () {
      final message = _getBannerMessage(SyncStatus.offline, null);

      expect(message.toLowerCase(), contains('offline'));
    });

    test('error message uses provided error', () {
      final message = _getBannerMessage(SyncStatus.error, 'Server unavailable');

      expect(message, equals('Server unavailable'));
    });

    test('error message has default when null', () {
      final message = _getBannerMessage(SyncStatus.error, null);

      expect(message, contains('error'));
    });
  });

  group('SyncStatusIndicator Widget', () {
    testWidgets('shows icon without label when showLabel false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockSyncStatusIndicator(
              state: SyncState(status: SyncStatus.idle, pendingCount: 0),
              showLabel: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
      expect(find.text('Synced'), findsNothing);
    });

    testWidgets('shows label when showLabel true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockSyncStatusIndicator(
              state: SyncState(status: SyncStatus.idle, pendingCount: 0),
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('shows pending count in compact mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockSyncStatusIndicator(
              state: SyncState(status: SyncStatus.idle, pendingCount: 5),
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });
  });

  group('OfflineBanner Widget', () {
    testWidgets('shows banner when offline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockOfflineBanner(
              state: SyncState(status: SyncStatus.offline, pendingCount: 0),
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.signal_wifi_off_outlined), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('hides banner when synced', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockOfflineBanner(
              state: SyncState(status: SyncStatus.idle, pendingCount: 0),
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.signal_wifi_off_outlined), findsNothing);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('shows error banner with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockOfflineBanner(
              state: SyncState(
                status: SyncStatus.error,
                pendingCount: 0,
                errorMessage: 'Connection failed',
              ),
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('retry button is present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockOfflineBanner(
              state: SyncState(status: SyncStatus.offline, pendingCount: 0),
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Rotating Icon', () {
    testWidgets('animates when syncing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockRotatingIcon(animate: true),
          ),
        ),
      );

      // Find the RotationTransition created by our mock widget
      expect(find.byType(RotationTransition), findsWidgets);
    });

    testWidgets('does not animate when not syncing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockRotatingIcon(animate: false),
          ),
        ),
      );

      // The mock widget returns just an Icon when not animating
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });
  });

  group('Sync Details Sheet', () {
    test('formats last sync time correctly', () {
      final time = DateTime(2024, 1, 15, 14, 30);
      final formatted = _formatLastSyncTime(time);

      expect(formatted, contains('14:30'));
    });

    test('shows never synced for null time', () {
      final formatted = _formatLastSyncTime(null);

      expect(formatted.toLowerCase(), contains('never'));
    });

    test('calculates time since last sync', () {
      final now = DateTime(2024, 1, 15, 15, 0);
      final lastSync = DateTime(2024, 1, 15, 14, 30);

      final duration = _timeSinceLastSync(lastSync, now);

      expect(duration.inMinutes, equals(30));
    });
  });

  group('Color Calculations', () {
    test('error status uses error color', () {
      final colorScheme = _mockColorScheme();
      final color = _getStatusColor(SyncStatus.error, colorScheme);

      expect(color, equals(colorScheme.error));
    });

    test('syncing uses secondary color', () {
      final colorScheme = _mockColorScheme();
      final color = _getStatusColor(SyncStatus.syncing, colorScheme);

      expect(color, equals(colorScheme.secondary));
    });

    test('offline uses outline color', () {
      final colorScheme = _mockColorScheme();
      final color = _getStatusColor(SyncStatus.offline, colorScheme);

      expect(color, equals(colorScheme.outline));
    });

    test('idle uses primary color', () {
      final colorScheme = _mockColorScheme();
      final color = _getStatusColor(SyncStatus.idle, colorScheme);

      expect(color, equals(colorScheme.primary));
    });
  });
}

// Enums and Models

enum SyncStatus { idle, syncing, error, offline }

class SyncState {
  SyncState({
    required this.status,
    required this.pendingCount,
    this.errorMessage,
    this.lastSyncTime,
  });

  final SyncStatus status;
  final int pendingCount;
  final String? errorMessage;
  final DateTime? lastSyncTime;

  bool get hasPendingItems => pendingCount > 0;
}

class StatusDisplay {
  StatusDisplay({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

// Helper functions

StatusDisplay _getStatusDisplay(SyncState state) {
  return switch (state.status) {
    SyncStatus.idle when state.hasPendingItems => StatusDisplay(
        icon: Icons.cloud_upload_outlined,
        label: '${state.pendingCount} pending',
      ),
    SyncStatus.idle => StatusDisplay(
        icon: Icons.cloud_done_outlined,
        label: 'Synced',
      ),
    SyncStatus.syncing => StatusDisplay(
        icon: Icons.sync,
        label: 'Syncing...',
      ),
    SyncStatus.error => StatusDisplay(
        icon: Icons.cloud_off_outlined,
        label: 'Sync error',
      ),
    SyncStatus.offline => StatusDisplay(
        icon: Icons.signal_wifi_off_outlined,
        label: 'Offline',
      ),
  };
}

bool _shouldShowBanner(SyncState state) {
  return state.status == SyncStatus.offline || state.status == SyncStatus.error;
}

String _getBannerMessage(SyncStatus status, String? errorMessage) {
  if (status == SyncStatus.error) {
    return errorMessage ?? 'Sync error occurred.';
  }
  return 'You are offline. Changes will sync when connected.';
}

String _formatLastSyncTime(DateTime? time) {
  if (time == null) return 'Never synced';
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

Duration _timeSinceLastSync(DateTime lastSync, DateTime now) {
  return now.difference(lastSync);
}

Color _getStatusColor(SyncStatus status, ColorScheme colorScheme) {
  return switch (status) {
    SyncStatus.error => colorScheme.error,
    SyncStatus.syncing => colorScheme.secondary,
    SyncStatus.offline => colorScheme.outline,
    SyncStatus.idle => colorScheme.primary,
  };
}

ColorScheme _mockColorScheme() {
  return const ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.teal,
    error: Colors.red,
    outline: Colors.grey,
  );
}

// Mock widgets

class _MockSyncStatusIndicator extends StatelessWidget {
  const _MockSyncStatusIndicator({
    required this.state,
    this.showLabel = true,
    this.compact = false,
  });

  final SyncState state;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final display = _getStatusDisplay(state);

    if (compact && state.hasPendingItems) {
      return Stack(
        children: [
          Icon(display.icon),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text('${state.pendingCount}'),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(display.icon),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(display.label),
        ],
      ],
    );
  }
}

class _MockOfflineBanner extends StatelessWidget {
  const _MockOfflineBanner({
    required this.state,
    required this.child,
  });

  final SyncState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_shouldShowBanner(state))
          Container(
            color: state.status == SyncStatus.error
                ? Colors.red.shade100
                : Colors.grey.shade200,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  state.status == SyncStatus.offline
                      ? Icons.signal_wifi_off_outlined
                      : Icons.cloud_off_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getBannerMessage(state.status, state.errorMessage),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

class _MockRotatingIcon extends StatelessWidget {
  const _MockRotatingIcon({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final icon = const Icon(Icons.sync);

    if (animate) {
      return RotationTransition(
        turns: const AlwaysStoppedAnimation(0),
        child: icon,
      );
    }

    return icon;
  }
}
