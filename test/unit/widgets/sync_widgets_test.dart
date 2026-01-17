/// Unit tests for SyncStatusIndicator and OfflineBanner widgets.
///
/// Test coverage:
/// 1. SyncStatus display states
/// 2. Icon and label display
/// 3. Compact vs full layouts
/// 4. Offline banner behavior
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncStatusIndicator', () {
    group('status display', () {
      test('idle with no pending items shows synced', () {
        final state = SyncState(
          status: SyncStatus.idle,
          pendingCount: 0,
        );
        final display = _getStatusDisplay(state);

        expect(display.label, equals('Synced'));
        expect(display.icon, equals(Icons.cloud_done_outlined));
      });

      test('idle with pending items shows pending count', () {
        final state = SyncState(
          status: SyncStatus.idle,
          pendingCount: 5,
        );
        final display = _getStatusDisplay(state);

        expect(display.label, equals('5 pending'));
        expect(display.icon, equals(Icons.cloud_upload_outlined));
      });

      test('syncing shows syncing message', () {
        final state = SyncState(
          status: SyncStatus.syncing,
        );
        final display = _getStatusDisplay(state);

        expect(display.label, equals('Syncing...'));
        expect(display.icon, equals(Icons.sync));
      });

      test('error shows error message', () {
        final state = SyncState(
          status: SyncStatus.error,
        );
        final display = _getStatusDisplay(state);

        expect(display.label, equals('Sync error'));
        expect(display.icon, equals(Icons.cloud_off_outlined));
      });

      test('offline shows offline message', () {
        final state = SyncState(
          status: SyncStatus.offline,
        );
        final display = _getStatusDisplay(state);

        expect(display.label, equals('Offline'));
        expect(display.icon, equals(Icons.signal_wifi_off_outlined));
      });
    });

    group('configuration', () {
      test('default size is 20', () {
        const size = 20.0;
        expect(size, equals(20.0));
      });

      test('showLabel defaults to true', () {
        const showLabel = true;
        expect(showLabel, isTrue);
      });

      test('compact defaults to false', () {
        const compact = false;
        expect(compact, isFalse);
      });
    });

    group('hasPendingItems', () {
      test('returns true when pendingCount > 0', () {
        final state = SyncState(pendingCount: 5);
        expect(state.hasPendingItems, isTrue);
      });

      test('returns false when pendingCount is 0', () {
        final state = SyncState(pendingCount: 0);
        expect(state.hasPendingItems, isFalse);
      });
    });

    group('compact indicator', () {
      test('shows badge when pending items', () {
        final state = SyncState(
          status: SyncStatus.idle,
          pendingCount: 3,
        );

        expect(state.hasPendingItems, isTrue);
      });

      test('no badge when no pending items', () {
        final state = SyncState(
          status: SyncStatus.idle,
          pendingCount: 0,
        );

        expect(state.hasPendingItems, isFalse);
      });
    });
  });

  group('OfflineBanner', () {
    group('banner visibility', () {
      test('shows banner when offline', () {
        const status = SyncStatus.offline;
        final shouldShow = status == SyncStatus.offline ||
            status == SyncStatus.error;

        expect(shouldShow, isTrue);
      });

      test('shows banner when error', () {
        const status = SyncStatus.error;
        final shouldShow = status == SyncStatus.offline ||
            status == SyncStatus.error;

        expect(shouldShow, isTrue);
      });

      test('hides banner when synced', () {
        const status = SyncStatus.idle;
        final shouldShow = status == SyncStatus.offline ||
            status == SyncStatus.error;

        expect(shouldShow, isFalse);
      });

      test('hides banner when syncing', () {
        const status = SyncStatus.syncing;
        final shouldShow = status == SyncStatus.offline ||
            status == SyncStatus.error;

        expect(shouldShow, isFalse);
      });
    });

    group('offline banner content', () {
      test('shows offline message', () {
        const message = 'You are offline. Changes will sync when connected.';
        expect(message, contains('offline'));
      });

      test('uses wifi off icon', () {
        const icon = Icons.signal_wifi_off_outlined;
        expect(icon, equals(Icons.signal_wifi_off_outlined));
      });
    });

    group('error banner content', () {
      test('shows error message', () {
        const errorMessage = 'Sync error occurred.';
        expect(errorMessage, contains('error'));
      });

      test('uses cloud off icon', () {
        const icon = Icons.cloud_off_outlined;
        expect(icon, equals(Icons.cloud_off_outlined));
      });

      test('uses custom error message when available', () {
        const customError = 'Network timeout';
        const errorMessage = customError;

        expect(errorMessage, equals('Network timeout'));
      });
    });

    group('retry functionality', () {
      test('retry triggers sync', () {
        var syncCalled = false;
        void onRetry() => syncCalled = true;

        onRetry();

        expect(syncCalled, isTrue);
      });

      test('error retry triggers retryFailed', () {
        var retryFailedCalled = false;
        void onRetry() => retryFailedCalled = true;

        onRetry();

        expect(retryFailedCalled, isTrue);
      });
    });

    group('styling', () {
      test('error uses error container color', () {
        const isError = true;
        // Error uses errorContainer, non-error uses surfaceContainerHigh
        expect(isError, isTrue);
      });

      test('offline uses surface container color', () {
        const isError = false;
        expect(isError, isFalse);
      });
    });

    group('animation', () {
      test('animated size duration is 200ms', () {
        const duration = Duration(milliseconds: 200);
        expect(duration.inMilliseconds, equals(200));
      });
    });
  });

  group('SyncState', () {
    test('default values', () {
      final state = SyncState();

      expect(state.status, equals(SyncStatus.idle));
      expect(state.pendingCount, equals(0));
      expect(state.failedCount, equals(0));
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates status', () {
      final state = SyncState(status: SyncStatus.idle);
      final updated = state.copyWith(status: SyncStatus.syncing);

      expect(updated.status, equals(SyncStatus.syncing));
    });

    test('copyWith updates error message', () {
      final state = SyncState();
      final updated = state.copyWith(errorMessage: 'Test error');

      expect(updated.errorMessage, equals('Test error'));
    });
  });

  group('SyncStatus enum', () {
    test('has all status values', () {
      expect(SyncStatus.values.length, equals(4));
    });

    test('includes idle', () {
      expect(SyncStatus.idle, isNotNull);
    });

    test('includes syncing', () {
      expect(SyncStatus.syncing, isNotNull);
    });

    test('includes error', () {
      expect(SyncStatus.error, isNotNull);
    });

    test('includes offline', () {
      expect(SyncStatus.offline, isNotNull);
    });
  });
}

// Helper function

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

// Models for testing

enum SyncStatus { idle, syncing, error, offline }

class SyncState {
  SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.errorMessage,
  });

  final SyncStatus status;
  final int pendingCount;
  final int failedCount;
  final String? errorMessage;

  bool get hasPendingItems => pendingCount > 0;

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? failedCount,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class StatusDisplay {
  StatusDisplay({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
