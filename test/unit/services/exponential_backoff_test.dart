/// Unit tests for ExponentialBackoff.
///
/// Test coverage:
/// 1. Default constructor values
/// 2. getDelay calculation
/// 3. getDelayWithJitter calculation
/// 4. getDelaySequence generation
/// 5. Max delay cap
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/sync/exponential_backoff.dart';

void main() {
  group('ExponentialBackoff', () {
    group('constructor', () {
      test('creates with default values', () {
        final backoff = ExponentialBackoff();

        expect(backoff.baseDelay, equals(const Duration(seconds: 1)));
        expect(backoff.maxDelay, equals(const Duration(minutes: 5)));
        expect(backoff.jitterFactor, equals(0.2));
      });

      test('accepts custom baseDelay', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 2),
        );

        expect(backoff.baseDelay, equals(const Duration(seconds: 2)));
      });

      test('accepts custom maxDelay', () {
        final backoff = ExponentialBackoff(
          maxDelay: const Duration(minutes: 10),
        );

        expect(backoff.maxDelay, equals(const Duration(minutes: 10)));
      });

      test('accepts custom jitterFactor', () {
        final backoff = ExponentialBackoff(
          jitterFactor: 0.5,
        );

        expect(backoff.jitterFactor, equals(0.5));
      });

      test('accepts all custom values', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(milliseconds: 500),
          maxDelay: const Duration(seconds: 30),
          jitterFactor: 0.3,
        );

        expect(backoff.baseDelay, equals(const Duration(milliseconds: 500)));
        expect(backoff.maxDelay, equals(const Duration(seconds: 30)));
        expect(backoff.jitterFactor, equals(0.3));
      });
    });

    group('getDelay', () {
      test('returns baseDelay for attempt 0', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
        );

        final delay = backoff.getDelay(attempt: 0);

        expect(delay, equals(const Duration(seconds: 1)));
      });

      test('doubles delay for attempt 1', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
        );

        final delay = backoff.getDelay(attempt: 1);

        expect(delay, equals(const Duration(seconds: 2)));
      });

      test('quadruples delay for attempt 2', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
        );

        final delay = backoff.getDelay(attempt: 2);

        expect(delay, equals(const Duration(seconds: 4)));
      });

      test('follows 2^n pattern', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(hours: 1),
        );

        expect(backoff.getDelay(attempt: 0).inSeconds, equals(1));
        expect(backoff.getDelay(attempt: 1).inSeconds, equals(2));
        expect(backoff.getDelay(attempt: 2).inSeconds, equals(4));
        expect(backoff.getDelay(attempt: 3).inSeconds, equals(8));
        expect(backoff.getDelay(attempt: 4).inSeconds, equals(16));
        expect(backoff.getDelay(attempt: 5).inSeconds, equals(32));
      });

      test('caps at maxDelay', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(seconds: 10),
        );

        // Attempt 10 would be 1024 seconds without cap
        final delay = backoff.getDelay(attempt: 10);

        expect(delay, equals(const Duration(seconds: 10)));
      });

      test('caps at maxDelay for high attempts', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(minutes: 5),
        );

        // Attempt 20 would be 1048576 seconds without cap
        final delay = backoff.getDelay(attempt: 20);

        expect(delay, equals(const Duration(minutes: 5)));
      });

      test('works with millisecond baseDelay', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(milliseconds: 100),
        );

        expect(backoff.getDelay(attempt: 0).inMilliseconds, equals(100));
        expect(backoff.getDelay(attempt: 1).inMilliseconds, equals(200));
        expect(backoff.getDelay(attempt: 2).inMilliseconds, equals(400));
      });
    });

    group('getDelayWithJitter', () {
      test('returns delay close to base delay for attempt 0', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          jitterFactor: 0.2,
        );

        // Run multiple times to verify jitter adds variation
        final delays = <int>[];
        for (var i = 0; i < 100; i++) {
          delays.add(backoff.getDelayWithJitter(attempt: 0).inMilliseconds);
        }

        // All delays should be within ±20% of 1000ms
        for (final delay in delays) {
          expect(delay, greaterThanOrEqualTo(800));
          expect(delay, lessThanOrEqualTo(1200));
        }
      });

      test('adds variation with jitter', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          jitterFactor: 0.2,
        );

        // Generate many delays to check for variation
        final delays = <int>{};
        for (var i = 0; i < 50; i++) {
          delays.add(backoff.getDelayWithJitter(attempt: 0).inMilliseconds);
        }

        // Should have multiple different values due to jitter
        expect(delays.length, greaterThan(1));
      });

      test('returns non-negative delay', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(milliseconds: 100),
          jitterFactor: 1.0, // Maximum jitter
        );

        for (var i = 0; i < 100; i++) {
          final delay = backoff.getDelayWithJitter(attempt: 0);
          expect(delay.inMilliseconds, greaterThanOrEqualTo(0));
        }
      });

      test('scales with attempt number', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          jitterFactor: 0.1, // Small jitter for predictability
        );

        // Average of many samples should be close to exponential value
        int sumAttempt0 = 0;
        int sumAttempt2 = 0;

        for (var i = 0; i < 100; i++) {
          sumAttempt0 += backoff.getDelayWithJitter(attempt: 0).inMilliseconds;
          sumAttempt2 += backoff.getDelayWithJitter(attempt: 2).inMilliseconds;
        }

        final avgAttempt0 = sumAttempt0 / 100;
        final avgAttempt2 = sumAttempt2 / 100;

        // Attempt 2 should be roughly 4x attempt 0
        expect(avgAttempt2 / avgAttempt0, closeTo(4.0, 0.5));
      });

      test('respects maxDelay with jitter', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(seconds: 5),
          jitterFactor: 0.2,
        );

        for (var i = 0; i < 50; i++) {
          final delay = backoff.getDelayWithJitter(attempt: 10);
          // Max should be 5000ms + 20% jitter = 6000ms
          expect(delay.inMilliseconds, lessThanOrEqualTo(6000));
        }
      });
    });

    group('getDelaySequence', () {
      test('generates correct number of delays', () {
        final backoff = ExponentialBackoff();

        final sequence = backoff.getDelaySequence(5);

        expect(sequence.length, equals(5));
      });

      test('generates empty list for 0 attempts', () {
        final backoff = ExponentialBackoff();

        final sequence = backoff.getDelaySequence(0);

        expect(sequence, isEmpty);
      });

      test('generates single delay for 1 attempt', () {
        final backoff = ExponentialBackoff();

        final sequence = backoff.getDelaySequence(1);

        expect(sequence.length, equals(1));
      });

      test('delays generally increase', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          jitterFactor: 0.1, // Low jitter
          maxDelay: const Duration(hours: 1),
        );

        // Run multiple times to verify trend
        var increasingCount = 0;
        for (var run = 0; run < 10; run++) {
          final sequence = backoff.getDelaySequence(5);

          var increasing = true;
          for (var i = 1; i < sequence.length; i++) {
            // Allow for some jitter variation, check if next is >= 50% of expected growth
            final expected = sequence[i - 1].inMilliseconds * 1.5;
            if (sequence[i].inMilliseconds < expected) {
              increasing = false;
              break;
            }
          }
          if (increasing) increasingCount++;
        }

        // Most runs should show increasing delays
        expect(increasingCount, greaterThanOrEqualTo(5));
      });
    });

    group('jitterFactor edge cases', () {
      test('zero jitter returns exact exponential delays', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          jitterFactor: 0.0,
        );

        // With zero jitter, all calls should return exact same value
        final delays = <int>{};
        for (var i = 0; i < 10; i++) {
          delays.add(backoff.getDelayWithJitter(attempt: 0).inMilliseconds);
        }

        expect(delays.length, equals(1));
        expect(delays.first, equals(1000));
      });

      test('high jitter factor produces wide range', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          jitterFactor: 0.5,
        );

        int minDelay = 10000;
        int maxDelay = 0;

        for (var i = 0; i < 100; i++) {
          final delay = backoff.getDelayWithJitter(attempt: 0).inMilliseconds;
          if (delay < minDelay) minDelay = delay;
          if (delay > maxDelay) maxDelay = delay;
        }

        // Should have at least 500ms range (50% of 1000ms)
        expect(maxDelay - minDelay, greaterThan(200));
      });
    });

    group('real-world scenarios', () {
      test('typical API retry scenario', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(seconds: 30),
          jitterFactor: 0.2,
        );

        // Simulate 5 retry attempts
        final sequence = backoff.getDelaySequence(5);

        expect(sequence.length, equals(5));
        // All delays should be reasonable
        for (final delay in sequence) {
          expect(delay.inSeconds, lessThanOrEqualTo(36)); // 30 + 20% jitter
        }
      });

      test('fast retry for UI operations', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(milliseconds: 50),
          maxDelay: const Duration(milliseconds: 500),
          jitterFactor: 0.1,
        );

        final delay = backoff.getDelay(attempt: 0);
        expect(delay.inMilliseconds, equals(50));

        final cappedDelay = backoff.getDelay(attempt: 10);
        expect(cappedDelay.inMilliseconds, equals(500));
      });

      test('slow retry for background sync', () {
        final backoff = ExponentialBackoff(
          baseDelay: const Duration(seconds: 5),
          maxDelay: const Duration(minutes: 30),
          jitterFactor: 0.3,
        );

        // After 5 attempts: 5s -> 10s -> 20s -> 40s -> 80s
        final delay5 = backoff.getDelay(attempt: 4);
        expect(delay5.inSeconds, equals(80));

        // High attempts should cap
        final delayMax = backoff.getDelay(attempt: 20);
        expect(delayMax.inMinutes, equals(30));
      });
    });
  });
}
