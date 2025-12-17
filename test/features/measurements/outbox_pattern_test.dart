import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/database/daos/measurements_dao.dart';
import 'package:orthosense/core/providers/database_provider.dart';
import 'package:orthosense/features/measurements/data/api/mock_measurement_service.dart';
import 'package:orthosense/features/measurements/data/repositories/measurement_repository_impl.dart';
import 'package:orthosense/features/measurements/presentation/providers/measurement_providers.dart';
import 'package:orthosense/features/measurements/presentation/providers/sync_controller.dart';

void main() {
  late AppDatabase database;
  late MeasurementsDao dao;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = database.measurementsDao;

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        measurementsDaoProvider.overrideWithValue(dao),
        measurementServiceProvider.overrideWithValue(
          MockMeasurementService(simulatedDelayMs: 10),
        ),
        measurementRepositoryProvider.overrideWith(
          (ref) => MeasurementRepositoryImpl(
            dao: ref.watch(measurementsDaoProvider),
            service: ref.watch(measurementServiceProvider),
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    await database.close();
    container.dispose();
  });

  group('Outbox Pattern', () {
    test('saveMeasurement creates entry with pending status', () async {
      final repository = container.read(measurementRepositoryProvider);

      final id = await repository.saveMeasurement(
        userId: 'test_user',
        type: 'pose_analysis',
        data: {'angle': 45},
      );

      expect(id, isNotEmpty);

      final entries = await dao.watchByUserId('test_user').first;
      expect(entries, hasLength(1));
      expect(entries.first.id, equals(id));
      expect(entries.first.syncStatus, equals(SyncStatus.pending));
    });

    test('syncPendingMeasurements updates status to synced', () async {
      final repository = container.read(measurementRepositoryProvider);

      // Add pending measurement
      await repository.saveMeasurement(
        userId: 'test_user',
        type: 'rom_measurement',
        data: {'flexion': 90},
      );

      // Verify pending
      var entries = await dao.watchByUserId('test_user').first;
      expect(entries.first.syncStatus, equals(SyncStatus.pending));

      // Trigger sync
      final result = await repository.syncPendingMeasurements();

      expect(result.attempted, equals(1));
      expect(result.succeeded, equals(1));
      expect(result.failed, equals(0));

      // Verify synced
      entries = await dao.watchByUserId('test_user').first;
      expect(entries.first.syncStatus, equals(SyncStatus.synced));
    });

    test('sync failure increments retry count and sets failed status',
        () async {
      // Override with failing service
      final failingContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          measurementsDaoProvider.overrideWithValue(dao),
          measurementServiceProvider.overrideWithValue(
            MockMeasurementService(
              simulatedDelayMs: 10,
              failureRate: 1, // Always fail
            ),
          ),
          measurementRepositoryProvider.overrideWith(
            (ref) => MeasurementRepositoryImpl(
              dao: ref.watch(measurementsDaoProvider),
              service: ref.watch(measurementServiceProvider),
            ),
          ),
        ],
      );

      final repository = failingContainer.read(measurementRepositoryProvider);

      await repository.saveMeasurement(
        userId: 'test_user',
        type: 'test',
        data: {'value': 1},
      );

      final result = await repository.syncPendingMeasurements();

      expect(result.failed, equals(1));

      final entries = await dao.watchByUserId('test_user').first;
      expect(entries.first.syncStatus, equals(SyncStatus.failed));
      expect(entries.first.syncRetryCount, equals(1));

      failingContainer.dispose();
    });

    test('multiple pending items sync correctly', () async {
      final repository = container.read(measurementRepositoryProvider);

      // Add multiple measurements
      await repository.saveMeasurement(
        userId: 'test_user',
        type: 'type_a',
        data: {'a': 1},
      );
      await repository.saveMeasurement(
        userId: 'test_user',
        type: 'type_b',
        data: {'b': 2},
      );
      await repository.saveMeasurement(
        userId: 'test_user',
        type: 'type_c',
        data: {'c': 3},
      );

      // Verify all pending
      var entries = await dao.watchByUserId('test_user').first;
      expect(entries, hasLength(3));
      expect(
        entries.every((e) => e.syncStatus == SyncStatus.pending),
        isTrue,
      );

      // Sync all
      final result = await repository.syncPendingMeasurements();

      expect(result.attempted, equals(3));
      expect(result.succeeded, equals(3));

      // Verify all synced
      entries = await dao.watchByUserId('test_user').first;
      expect(
        entries.every((e) => e.syncStatus == SyncStatus.synced),
        isTrue,
      );
    });
  });

  group('SyncController', () {
    test('syncNow updates state correctly on success', () async {
      final repository = container.read(measurementRepositoryProvider);

      await repository.saveMeasurement(
        userId: 'test_user',
        type: 'test',
        data: {},
      );

      final controller = container.read(syncControllerProvider.notifier);

      expect(
        container.read(syncControllerProvider).state,
        equals(SyncState.idle),
      );

      await controller.syncNow();

      final status = container.read(syncControllerProvider);
      expect(status.state, equals(SyncState.success));
      expect(status.lastResult?.succeeded, equals(1));
      expect(status.lastSyncTime, isNotNull);
    });

    test('syncNow prevents concurrent sync', () async {
      final repository = container.read(measurementRepositoryProvider);

      await repository.saveMeasurement(
        userId: 'test_user',
        type: 'test',
        data: {},
      );

      final controller = container.read(syncControllerProvider.notifier);

      // Start first sync (don't await)
      final future1 = controller.syncNow();
      // Try to start second sync immediately
      final future2 = controller.syncNow();

      await Future.wait([future1, future2]);

      // Only one sync should have occurred
      final status = container.read(syncControllerProvider);
      expect(status.lastResult?.attempted, equals(1));
    });
  });

  group('SSOT Pattern', () {
    test('watchMeasurements emits updates when data changes', () async {
      final repository = container.read(measurementRepositoryProvider);

      final stream = repository.watchMeasurements('test_user');

      // Initial empty
      expect(await stream.first, isEmpty);

      // Add measurement
      await repository.saveMeasurement(
        userId: 'test_user',
        type: 'test',
        data: {'initial': true},
      );

      // Stream should emit new data
      final measurements = await stream.first;
      expect(measurements, hasLength(1));
      expect(measurements.first.data['initial'], isTrue);
    });

    test('sync status changes are reflected in stream', () async {
      final repository = container.read(measurementRepositoryProvider);

      await repository.saveMeasurement(
        userId: 'test_user',
        type: 'test',
        data: {},
      );

      // Watch pending stream
      final pendingStream = repository.watchByStatus(SyncStatus.pending);

      expect((await pendingStream.first).length, equals(1));

      // Sync
      await repository.syncPendingMeasurements();

      // Pending should be empty now
      expect((await pendingStream.first).length, equals(0));
    });
  });
}
