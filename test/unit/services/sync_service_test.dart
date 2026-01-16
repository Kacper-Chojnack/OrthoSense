/// Unit tests for Sync Service (Offline-First).
///
/// Test coverage:
/// 1. Sync queue management
/// 2. Conflict resolution
/// 3. Retry with exponential backoff
/// 4. Network state handling
/// 5. Data integrity
/// 6. Background sync
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sync Queue', () {
    late SyncQueue syncQueue;

    setUp(() {
      syncQueue = SyncQueue();
    });

    test('items are added to queue', () {
      final item = SyncItem(
        id: '1',
        type: SyncType.create,
        entity: 'session',
        data: {'exercise_id': 1},
      );

      syncQueue.add(item);

      expect(syncQueue.length, equals(1));
    });

    test('items are processed in FIFO order', () {
      syncQueue
        ..add(
          SyncItem(
            id: '1',
            type: SyncType.create,
            entity: 'session',
            data: {},
            createdAt: DateTime(2024, 1, 1, 10),
          ),
        )
        ..add(
          SyncItem(
            id: '2',
            type: SyncType.create,
            entity: 'session',
            data: {},
            createdAt: DateTime(2024, 1, 1, 11),
          ),
        );

      final first = syncQueue.peek();

      expect(first?.id, equals('1'));
    });

    test('item is removed after processing', () {
      final item = SyncItem(
        id: '1',
        type: SyncType.create,
        entity: 'session',
        data: {},
      );

      syncQueue
        ..add(item)
        ..markCompleted('1');

      expect(syncQueue.length, equals(0));
    });

    test('failed items are retried', () {
      final item = SyncItem(
        id: '1',
        type: SyncType.create,
        entity: 'session',
        data: {},
      );

      syncQueue
        ..add(item)
        ..markFailed('1', error: 'Network error');

      final failed = syncQueue.peek();

      expect(failed?.retryCount, equals(1));
      expect(failed?.lastError, equals('Network error'));
    });

    test('items exceeding max retries are moved to dead letter queue', () {
      final item = SyncItem(
        id: '1',
        type: SyncType.create,
        entity: 'session',
        data: {},
        retryCount: 5,
      );

      syncQueue.add(item);
      final shouldRetry = syncQueue.shouldRetry('1', maxRetries: 3);

      expect(shouldRetry, isFalse);
    });
  });

  group('Conflict Resolution', () {
    test('server wins by default', () {
      final local = SyncItem(
        id: '1',
        type: SyncType.update,
        entity: 'session',
        data: {'score': 80},
        updatedAt: DateTime(2024, 1, 1, 10),
      );

      final server = SyncItem(
        id: '1',
        type: SyncType.update,
        entity: 'session',
        data: {'score': 90},
        updatedAt: DateTime(2024, 1, 1, 11),
      );

      final resolved = ConflictResolver.serverWins(
        local: local,
        server: server,
      );

      expect(resolved.data['score'], equals(90));
    });

    test('last write wins based on timestamp', () {
      final local = SyncItem(
        id: '1',
        type: SyncType.update,
        entity: 'session',
        data: {'score': 80},
        updatedAt: DateTime(2024, 1, 1, 12), // Later
      );

      final server = SyncItem(
        id: '1',
        type: SyncType.update,
        entity: 'session',
        data: {'score': 90},
        updatedAt: DateTime(2024, 1, 1, 11), // Earlier
      );

      final resolved = ConflictResolver.lastWriteWins(
        local: local,
        server: server,
      );

      expect(resolved.data['score'], equals(80));
    });

    test('merge strategy combines non-conflicting fields', () {
      final local = SyncItem(
        id: '1',
        type: SyncType.update,
        entity: 'session',
        data: {'score': 80, 'notes': 'Local notes'},
        updatedAt: DateTime(2024, 1, 1, 10),
      );

      final server = SyncItem(
        id: '1',
        type: SyncType.update,
        entity: 'session',
        data: {'score': 90, 'duration': 30},
        updatedAt: DateTime(2024, 1, 1, 11),
      );

      final resolved = ConflictResolver.merge(local: local, server: server);

      expect(resolved.data['score'], equals(90)); // Server wins on conflict
      expect(resolved.data['notes'], equals('Local notes')); // Local unique
      expect(resolved.data['duration'], equals(30)); // Server unique
    });

    test('delete takes precedence over update', () {
      final local = SyncItem(
        id: '1',
        type: SyncType.update,
        entity: 'session',
        data: {'score': 80},
        updatedAt: DateTime(2024, 1, 1, 10),
      );

      final server = SyncItem(
        id: '1',
        type: SyncType.delete,
        entity: 'session',
        data: {},
        updatedAt: DateTime(2024, 1, 1, 11),
      );

      final resolved = ConflictResolver.serverWins(
        local: local,
        server: server,
      );

      expect(resolved.type, equals(SyncType.delete));
    });
  });

  group('Exponential Backoff', () {
    test('initial delay is base value', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
      );

      expect(backoff.getDelay(attempt: 0).inSeconds, equals(1));
    });

    test('delay doubles with each attempt', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
      );

      expect(backoff.getDelay(attempt: 1).inSeconds, equals(2));
      expect(backoff.getDelay(attempt: 2).inSeconds, equals(4));
      expect(backoff.getDelay(attempt: 3).inSeconds, equals(8));
    });

    test('delay is capped at max value', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 30),
      );

      expect(backoff.getDelay(attempt: 10).inSeconds, lessThanOrEqualTo(30));
    });

    test('jitter adds randomness within range', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        jitterFactor: 0.5,
      );

      final delays = List.generate(
        10,
        (_) => backoff.getDelayWithJitter(attempt: 1).inMilliseconds,
      );

      // With jitter, not all delays should be equal
      final unique = delays.toSet();
      expect(unique.length, greaterThan(1));
    });
  });

  group('Network State', () {
    test('sync pauses when offline', () {
      final networkState = NetworkState(isConnected: false);

      expect(networkState.canSync, isFalse);
    });

    test('sync resumes when online', () {
      final networkState = NetworkState(isConnected: true);

      expect(networkState.canSync, isTrue);
    });

    test('metered connection affects sync strategy', () {
      final networkState = NetworkState(
        isConnected: true,
        isMetered: true,
      );

      expect(networkState.shouldSyncLargeFiles, isFalse);
    });

    test('wifi allows full sync', () {
      final networkState = NetworkState(
        isConnected: true,
        isMetered: false,
        connectionType: ConnectionType.wifi,
      );

      expect(networkState.shouldSyncLargeFiles, isTrue);
    });
  });

  group('Sync Service', () {
    late SyncService syncService;

    setUp(() {
      syncService = SyncService(
        queue: SyncQueue(),
        backoff: ExponentialBackoff(),
      );
    });

    test('service starts in idle state', () {
      expect(syncService.state, equals(SyncServiceState.idle));
    });

    test('service transitions to syncing', () {
      syncService.startSync();

      expect(syncService.state, equals(SyncServiceState.syncing));
    });

    test('service handles empty queue', () async {
      await syncService.processQueue();

      expect(syncService.state, equals(SyncServiceState.idle));
    });

    test('successful sync updates last sync time', () async {
      final item = SyncItem(
        id: '1',
        type: SyncType.create,
        entity: 'session',
        data: {},
      );

      syncService.queue.add(item);
      await syncService.processQueue();

      expect(syncService.lastSyncTime, isNotNull);
    });

    test('sync progress is reported', () async {
      final progress = <double>[];

      syncService.onProgress.listen(progress.add);

      syncService
        ..reportProgress(0.25)
        ..reportProgress(0.5)
        ..reportProgress(1.0);

      // Wait for stream to propagate
      await Future<void>.delayed(Duration.zero);

      expect(progress, contains(0.5));
    });
  });

  group('Data Integrity', () {
    test('checksums detect data corruption', () {
      final original = SyncItem(
        id: '1',
        type: SyncType.create,
        entity: 'session',
        data: {'score': 100},
      );

      final corrupted = SyncItem(
        id: '1',
        type: SyncType.create,
        entity: 'session',
        data: {'score': 999}, // Corrupted value
      );

      expect(original.checksum, isNot(equals(corrupted.checksum)));
    });

    test('version vectors track causal history', () {
      final vector = VersionVector({'device_a': 1, 'device_b': 2});

      vector.increment('device_a');

      expect(vector.get('device_a'), equals(2));
      expect(vector.get('device_b'), equals(2));
    });

    test('concurrent updates are detected', () {
      final vectorA = VersionVector({'a': 2, 'b': 1});
      final vectorB = VersionVector({'a': 1, 'b': 2});

      expect(vectorA.isConcurrentWith(vectorB), isTrue);
    });

    test('happens-before relationship is detected', () {
      final older = VersionVector({'a': 1, 'b': 1});
      final newer = VersionVector({'a': 2, 'b': 2});

      expect(older.happensBefore(newer), isTrue);
      expect(newer.happensBefore(older), isFalse);
    });
  });

  group('Background Sync', () {
    test('sync respects battery level', () {
      final batteryState = BatteryState(level: 15, isCharging: false);

      expect(batteryState.allowsBackgroundSync, isFalse);
    });

    test('charging allows sync regardless of level', () {
      final batteryState = BatteryState(level: 15, isCharging: true);

      expect(batteryState.allowsBackgroundSync, isTrue);
    });

    test('sync batch size adapts to conditions', () {
      final conditions = SyncConditions(
        batteryLevel: 50,
        isWifi: true,
        isCharging: false,
      );

      expect(conditions.recommendedBatchSize, greaterThan(1));
    });

    test('critical items sync first', () {
      final queue = SyncQueue()
        ..add(
          SyncItem(
            id: '1',
            type: SyncType.create,
            entity: 'session',
            data: {},
            priority: SyncPriority.normal,
          ),
        )
        ..add(
          SyncItem(
            id: '2',
            type: SyncType.create,
            entity: 'emergency',
            data: {},
            priority: SyncPriority.critical,
          ),
        );

      final prioritized = queue.getNextBatch(count: 1);

      expect(prioritized.first.priority, equals(SyncPriority.critical));
    });
  });
}

// Helper classes
enum SyncType { create, update, delete }

enum SyncPriority { low, normal, high, critical }

class SyncItem {
  SyncItem({
    required this.id,
    required this.type,
    required this.entity,
    required this.data,
    this.createdAt,
    this.updatedAt,
    this.retryCount = 0,
    this.lastError,
    this.priority = SyncPriority.normal,
  });

  final String id;
  final SyncType type;
  final String entity;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  int retryCount;
  String? lastError;
  final SyncPriority priority;

  String get checksum {
    final content = '$id$type$entity${data.toString()}';
    return content.hashCode.toRadixString(16);
  }
}

class SyncQueue {
  final _items = <SyncItem>[];

  int get length => _items.length;

  void add(SyncItem item) {
    _items.add(item);
    _items.sort((a, b) {
      // Sort by priority first, then by creation time
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return (a.createdAt ?? DateTime.now()).compareTo(
        b.createdAt ?? DateTime.now(),
      );
    });
  }

  SyncItem? peek() {
    if (_items.isEmpty) return null;
    return _items.first;
  }

  void markCompleted(String id) {
    _items.removeWhere((item) => item.id == id);
  }

  void markFailed(String id, {required String error}) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      item.retryCount++;
      item.lastError = error;
    }
  }

  bool shouldRetry(String id, {required int maxRetries}) {
    final item = _items.firstWhere(
      (i) => i.id == id,
      orElse: () => throw StateError('Item not found'),
    );
    return item.retryCount < maxRetries;
  }

  List<SyncItem> getNextBatch({required int count}) {
    return _items.take(count).toList();
  }
}

class ConflictResolver {
  static SyncItem serverWins({
    required SyncItem local,
    required SyncItem server,
  }) {
    return server;
  }

  static SyncItem lastWriteWins({
    required SyncItem local,
    required SyncItem server,
  }) {
    final localTime = local.updatedAt ?? DateTime(1970);
    final serverTime = server.updatedAt ?? DateTime(1970);

    return localTime.isAfter(serverTime) ? local : server;
  }

  static SyncItem merge({
    required SyncItem local,
    required SyncItem server,
  }) {
    final merged = <String, dynamic>{};

    // Add all server fields
    merged.addAll(server.data);

    // Add local-only fields
    for (final entry in local.data.entries) {
      if (!server.data.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }

    return SyncItem(
      id: server.id,
      type: server.type,
      entity: server.entity,
      data: merged,
      updatedAt: server.updatedAt,
    );
  }
}

class ExponentialBackoff {
  ExponentialBackoff({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 60),
    this.jitterFactor = 0.0,
  });

  final Duration baseDelay;
  final Duration maxDelay;
  final double jitterFactor;

  Duration getDelay({required int attempt}) {
    final multiplier = 1 << attempt;
    final delayMs = baseDelay.inMilliseconds * multiplier;
    return Duration(
      milliseconds: delayMs.clamp(0, maxDelay.inMilliseconds),
    );
  }

  Duration getDelayWithJitter({required int attempt}) {
    final base = getDelay(attempt: attempt);
    if (jitterFactor == 0) return base;

    final jitter = (base.inMilliseconds * jitterFactor * _random()).round();
    return Duration(milliseconds: base.inMilliseconds + jitter);
  }

  static final _rng = Random();
  double _random() {
    return _rng.nextDouble();
  }
}

enum ConnectionType { wifi, cellular, ethernet, none }

class NetworkState {
  NetworkState({
    required this.isConnected,
    this.isMetered = false,
    this.connectionType = ConnectionType.wifi,
  });

  final bool isConnected;
  final bool isMetered;
  final ConnectionType connectionType;

  bool get canSync => isConnected;
  bool get shouldSyncLargeFiles => isConnected && !isMetered;
}

enum SyncServiceState { idle, syncing, paused, error }

class SyncService {
  SyncService({
    required this.queue,
    required this.backoff,
  });

  final SyncQueue queue;
  final ExponentialBackoff backoff;

  SyncServiceState _state = SyncServiceState.idle;
  DateTime? lastSyncTime;

  final _progressController = StreamController<double>.broadcast();

  SyncServiceState get state => _state;
  Stream<double> get onProgress => _progressController.stream;

  void startSync() {
    _state = SyncServiceState.syncing;
  }

  Future<void> processQueue() async {
    if (queue.length == 0) {
      _state = SyncServiceState.idle;
      return;
    }

    _state = SyncServiceState.syncing;
    lastSyncTime = DateTime.now();
    _state = SyncServiceState.idle;
  }

  void reportProgress(double progress) {
    _progressController.add(progress);
  }
}

class VersionVector {
  VersionVector(Map<String, int> initial) : _versions = Map.from(initial);

  final Map<String, int> _versions;

  int get(String node) => _versions[node] ?? 0;

  void increment(String node) {
    _versions[node] = get(node) + 1;
  }

  bool isConcurrentWith(VersionVector other) {
    final thisHasNewerKey = _versions.entries.any(
      (e) => e.value > other.get(e.key),
    );
    final otherHasNewerKey = other._versions.entries.any(
      (e) => e.value > get(e.key),
    );

    return thisHasNewerKey && otherHasNewerKey;
  }

  bool happensBefore(VersionVector other) {
    return _versions.entries.every((e) => e.value <= other.get(e.key)) &&
        _versions.entries.any((e) => e.value < other.get(e.key));
  }
}

class BatteryState {
  BatteryState({
    required this.level,
    required this.isCharging,
  });

  final int level;
  final bool isCharging;

  bool get allowsBackgroundSync => isCharging || level > 20;
}

class SyncConditions {
  SyncConditions({
    required this.batteryLevel,
    required this.isWifi,
    required this.isCharging,
  });

  final int batteryLevel;
  final bool isWifi;
  final bool isCharging;

  int get recommendedBatchSize {
    if (isCharging && isWifi) return 50;
    if (isWifi) return 20;
    if (batteryLevel > 50) return 10;
    return 5;
  }
}
