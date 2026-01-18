/// Unit tests for ExponentialBackoff and ConnectivityService.
///
/// Test coverage:
/// 1. ExponentialBackoff delay calculation
/// 2. Jitter application
/// 3. Delay capping
/// 4. ConnectivityService state management
/// 5. Connection type detection
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExponentialBackoff', () {
    test('first attempt returns base delay', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
      );

      final delay = backoff.getDelay(attempt: 0);

      expect(delay.inSeconds, equals(1));
    });

    test('delay doubles with each attempt', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(hours: 1), // High cap to not interfere
      );

      expect(backoff.getDelay(attempt: 0).inSeconds, equals(1));
      expect(backoff.getDelay(attempt: 1).inSeconds, equals(2));
      expect(backoff.getDelay(attempt: 2).inSeconds, equals(4));
      expect(backoff.getDelay(attempt: 3).inSeconds, equals(8));
    });

    test('delay is capped at maxDelay', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 10),
      );

      final delay = backoff.getDelay(attempt: 10); // Would be 1024 seconds

      expect(delay.inSeconds, equals(10));
    });

    test('jitter adds variation to delay', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 10),
        jitterFactor: 0.2,
      );

      // Run multiple times to check for variation
      final delays = List.generate(
        100,
        (_) => backoff.getDelayWithJitter(attempt: 0),
      );

      final uniqueDelays = delays.map((d) => d.inMilliseconds).toSet();

      // With 20% jitter on 10 seconds, we should see variation
      expect(uniqueDelays.length, greaterThan(1));
    });

    test('jitter stays within bounds', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 10),
        maxDelay: const Duration(minutes: 1),
        jitterFactor: 0.2,
      );

      for (int i = 0; i < 100; i++) {
        final delay = backoff.getDelayWithJitter(attempt: 0);

        // With 20% jitter on 10s: range should be 8s-12s
        expect(delay.inMilliseconds, greaterThanOrEqualTo(8000));
        expect(delay.inMilliseconds, lessThanOrEqualTo(12000));
      }
    });

    test('zero jitter returns exact delay', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 5),
        jitterFactor: 0,
      );

      final delays = List.generate(
        10,
        (_) => backoff.getDelayWithJitter(attempt: 0),
      );

      expect(delays.every((d) => d.inSeconds == 5), isTrue);
    });

    test('getDelaySequence returns correct number of delays', () {
      final backoff = ExponentialBackoff();

      final sequence = backoff.getDelaySequence(5);

      expect(sequence.length, equals(5));
    });

    test('delay never negative', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(milliseconds: 100),
        jitterFactor: 0.9, // High jitter
      );

      for (int i = 0; i < 100; i++) {
        final delay = backoff.getDelayWithJitter(attempt: 0);
        expect(delay.inMilliseconds, greaterThanOrEqualTo(0));
      }
    });
  });

  group('ConnectivityService State', () {
    test('initial state is online', () {
      final service = MockConnectivityService();

      expect(service.isOnline, isTrue);
    });

    test('can be set to offline', () {
      final service = MockConnectivityService();

      service.setOnline(false);

      expect(service.isOnline, isFalse);
    });

    test('notifies listeners on state change', () async {
      final service = MockConnectivityService();
      var notified = false;

      final subscription = service.onConnectivityChanged.listen((_) {
        notified = true;
      });

      // Wait a bit for the listener to be registered
      await Future<void>.delayed(const Duration(milliseconds: 10));

      service.setOnline(false);

      // Wait for notification
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await subscription.cancel();
      expect(notified, isTrue);
    });

    test('does not notify if state unchanged', () {
      final service = MockConnectivityService();
      var notificationCount = 0;

      service.onConnectivityChanged.listen((_) {
        notificationCount++;
      });

      service.setOnline(true); // Same as initial state

      expect(notificationCount, equals(0));
    });
  });

  group('Connection Type Detection', () {
    test('wifi is considered online', () {
      expect(_hasConnection([ConnectivityResult.wifi]), isTrue);
    });

    test('mobile is considered online', () {
      expect(_hasConnection([ConnectivityResult.mobile]), isTrue);
    });

    test('ethernet is considered online', () {
      expect(_hasConnection([ConnectivityResult.ethernet]), isTrue);
    });

    test('vpn is considered online', () {
      expect(_hasConnection([ConnectivityResult.vpn]), isTrue);
    });

    test('none is considered offline', () {
      expect(_hasConnection([ConnectivityResult.none]), isFalse);
    });

    test('bluetooth only is considered offline', () {
      expect(_hasConnection([ConnectivityResult.bluetooth]), isFalse);
    });

    test('mixed results with wifi returns online', () {
      expect(
        _hasConnection([ConnectivityResult.bluetooth, ConnectivityResult.wifi]),
        isTrue,
      );
    });

    test('empty results considered offline', () {
      expect(_hasConnection([]), isFalse);
    });
  });

  group('Retry Logic Integration', () {
    test('retry sequence with 5 attempts', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 30),
      );

      final delays = <Duration>[];
      for (int attempt = 0; attempt < 5; attempt++) {
        delays.add(backoff.getDelay(attempt: attempt));
      }

      expect(delays[0].inSeconds, equals(1));
      expect(delays[1].inSeconds, equals(2));
      expect(delays[2].inSeconds, equals(4));
      expect(delays[3].inSeconds, equals(8));
      expect(delays[4].inSeconds, equals(16));
    });

    test('total wait time is reasonable', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 30),
      );

      var totalMs = 0;
      for (int attempt = 0; attempt < 5; attempt++) {
        totalMs += backoff.getDelay(attempt: attempt).inMilliseconds;
      }

      // 1 + 2 + 4 + 8 + 16 = 31 seconds
      expect(totalMs, equals(31000));
    });
  });

  group('Edge Cases', () {
    test('very high attempt number is capped', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(minutes: 5),
      );

      final delay = backoff.getDelay(attempt: 100);

      expect(delay.inMinutes, equals(5));
    });

    test('very short base delay works', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(milliseconds: 10),
        maxDelay: const Duration(seconds: 1),
      );

      final delay = backoff.getDelay(attempt: 0);

      expect(delay.inMilliseconds, equals(10));
    });

    test('base delay equals max delay', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 5),
        maxDelay: const Duration(seconds: 5),
      );

      // All attempts should return same delay
      expect(backoff.getDelay(attempt: 0).inSeconds, equals(5));
      expect(backoff.getDelay(attempt: 1).inSeconds, equals(5));
      expect(backoff.getDelay(attempt: 10).inSeconds, equals(5));
    });
  });
}

// Models

class ExponentialBackoff {
  ExponentialBackoff({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 5),
    this.jitterFactor = 0.2,
  });

  final Duration baseDelay;
  final Duration maxDelay;
  final double jitterFactor;
  final _random = Random();

  Duration getDelay({required int attempt}) {
    // Cap attempt to avoid overflow (2^20 is ~1 million which is more than enough)
    final safeattempt = attempt.clamp(0, 20);
    final exponentialDelay = baseDelay.inMilliseconds * pow(2, safeattempt);
    final cappedDelay = min(
      exponentialDelay,
      maxDelay.inMilliseconds.toDouble(),
    );
    return Duration(milliseconds: cappedDelay.toInt());
  }

  Duration getDelayWithJitter({required int attempt}) {
    final baseDelayMs = getDelay(attempt: attempt).inMilliseconds;
    final jitter = (baseDelayMs * jitterFactor * (2 * _random.nextDouble() - 1))
        .round();
    final finalDelay = max(0, baseDelayMs + jitter);
    return Duration(milliseconds: finalDelay);
  }

  List<Duration> getDelaySequence(int attempts) {
    return List.generate(attempts, (i) => getDelayWithJitter(attempt: i));
  }
}

enum ConnectivityResult { wifi, mobile, ethernet, vpn, bluetooth, none }

bool _hasConnection(List<ConnectivityResult> results) {
  return results.any(
    (result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn,
  );
}

class MockConnectivityService {
  bool _isOnline = true;
  final List<void Function(bool)> _listeners = [];

  bool get isOnline => _isOnline;

  Stream<bool> get onConnectivityChanged => Stream.multi((controller) {
    void listener(bool value) {
      controller.add(value);
    }

    _listeners.add(listener);
    controller.onCancel = () => _listeners.remove(listener);
  });

  void setOnline(bool value) {
    if (_isOnline != value) {
      _isOnline = value;
      for (final listener in _listeners) {
        listener(value);
      }
    }
  }
}
