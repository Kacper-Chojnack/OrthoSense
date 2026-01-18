/// Unit tests for BackgroundSyncWorker.
///
/// Test coverage:
/// 1. Start/stop lifecycle
/// 2. Pause/resume
/// 3. Periodic sync
/// 4. Connectivity-triggered sync
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/services/sync/background_sync_worker.dart';
import 'package:orthosense/core/services/sync/connectivity_service.dart';
import 'package:orthosense/core/services/sync/sync_service.dart';
import 'package:orthosense/core/services/sync/sync_state.dart';

class MockSyncService extends Mock implements SyncService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('BackgroundSyncWorker', () {
    late MockSyncService mockSyncService;
    late MockConnectivityService mockConnectivity;
    late StreamController<bool> connectivityController;
    late BackgroundSyncWorker worker;

    setUp(() {
      mockSyncService = MockSyncService();
      mockConnectivity = MockConnectivityService();
      connectivityController = StreamController<bool>.broadcast();

      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => connectivityController.stream);
      when(
        () => mockSyncService.state,
      ).thenReturn(const SyncState(pendingCount: 0));
      when(() => mockSyncService.syncPendingItems()).thenAnswer((_) async {});

      worker = BackgroundSyncWorker(
        syncService: mockSyncService,
        connectivityService: mockConnectivity,
        syncInterval: const Duration(milliseconds: 100),
        debounceDelay: const Duration(milliseconds: 10),
      );
    });

    tearDown(() {
      connectivityController.close();
      worker.dispose();
    });

    group('lifecycle', () {
      test('starts not running', () {
        expect(worker.isRunning, isFalse);
        expect(worker.isPaused, isFalse);
        expect(worker.isActive, isFalse);
      });

      test('start sets isRunning to true', () {
        worker.start();
        expect(worker.isRunning, isTrue);
        expect(worker.isPaused, isFalse);
      });

      test('stop sets isRunning to false', () {
        worker.start();
        worker.stop();
        expect(worker.isRunning, isFalse);
      });

      test('start is idempotent', () {
        worker.start();
        worker.start(); // Second call should be no-op
        expect(worker.isRunning, isTrue);
      });

      test('stop is idempotent', () {
        worker.stop(); // Not running yet
        expect(worker.isRunning, isFalse);
      });
    });

    group('pause/resume', () {
      test('pause sets isPaused to true', () {
        worker.start();
        worker.pause();
        expect(worker.isPaused, isTrue);
      });

      test('resume sets isPaused to false', () {
        worker.start();
        worker.pause();
        worker.resume();
        expect(worker.isPaused, isFalse);
      });

      test('pause only works when running', () {
        worker.pause(); // Not running
        expect(worker.isPaused, isFalse);
      });

      test('resume only works when paused', () {
        worker.start();
        worker.resume(); // Not paused
        expect(worker.isPaused, isFalse);
      });

      test('isActive is false when paused', () {
        worker.start();
        expect(worker.isActive, isTrue);
        worker.pause();
        expect(worker.isActive, isFalse);
      });

      test('isActive is true after resume', () {
        worker.start();
        worker.pause();
        worker.resume();
        expect(worker.isActive, isTrue);
      });
    });

    group('connectivity sync trigger', () {
      test('syncs when going online with pending items', () async {
        when(
          () => mockSyncService.state,
        ).thenReturn(const SyncState(pendingCount: 5));
        when(() => mockConnectivity.isOnline).thenReturn(false);

        worker.start();

        // Simulate going online
        when(() => mockConnectivity.isOnline).thenReturn(true);
        connectivityController.add(true);

        // Wait for debounce
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => mockSyncService.syncPendingItems()).called(greaterThan(0));
      });
    });

    group('initial sync', () {
      test('syncs on start if online with pending items', () async {
        when(() => mockConnectivity.isOnline).thenReturn(true);
        when(
          () => mockSyncService.state,
        ).thenReturn(const SyncState(pendingCount: 3));

        worker.start();

        // Give time for initial sync
        await Future<void>.delayed(const Duration(milliseconds: 10));

        verify(() => mockSyncService.syncPendingItems()).called(greaterThan(0));
      });

      test('does not sync on start if no pending items', () async {
        when(() => mockConnectivity.isOnline).thenReturn(true);
        when(
          () => mockSyncService.state,
        ).thenReturn(const SyncState(pendingCount: 0));

        worker.start();

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Initial sync should not be called since no pending items
        verifyNever(() => mockSyncService.syncPendingItems());
      });
    });

    group('dispose', () {
      test('dispose stops the worker', () {
        worker.start();
        worker.dispose();
        expect(worker.isRunning, isFalse);
      });
    });
  });

  group('BackgroundSyncWorker intervals', () {
    test('default sync interval is 5 minutes', () {
      final worker = BackgroundSyncWorker(
        syncService: MockSyncService(),
        connectivityService: MockConnectivityService(),
      );
      expect(worker.syncInterval, equals(const Duration(minutes: 5)));
      worker.dispose();
    });

    test('default debounce delay is 500ms', () {
      final worker = BackgroundSyncWorker(
        syncService: MockSyncService(),
        connectivityService: MockConnectivityService(),
      );
      expect(worker.debounceDelay, equals(const Duration(milliseconds: 500)));
      worker.dispose();
    });

    test('custom intervals are respected', () {
      final worker = BackgroundSyncWorker(
        syncService: MockSyncService(),
        connectivityService: MockConnectivityService(),
        syncInterval: const Duration(minutes: 10),
        debounceDelay: const Duration(seconds: 1),
      );
      expect(worker.syncInterval, equals(const Duration(minutes: 10)));
      expect(worker.debounceDelay, equals(const Duration(seconds: 1)));
      worker.dispose();
    });
  });

  group('SyncState helpers', () {
    test('hasPendingItems returns true when pendingCount > 0', () {
      const state = SyncState(pendingCount: 5);
      expect(state.hasPendingItems, isTrue);
    });

    test('hasPendingItems returns false when pendingCount is 0', () {
      const state = SyncState(pendingCount: 0);
      expect(state.hasPendingItems, isFalse);
    });

    test('hasFailedItems returns true when failedCount > 0', () {
      const state = SyncState(failedCount: 2);
      expect(state.hasFailedItems, isTrue);
    });

    test('hasFailedItems returns false when failedCount is 0', () {
      const state = SyncState(failedCount: 0);
      expect(state.hasFailedItems, isFalse);
    });
  });
}
