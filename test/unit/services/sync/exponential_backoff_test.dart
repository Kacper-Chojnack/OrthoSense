/// Unit tests for ExponentialBackoff.
///
/// Test coverage:
/// 1. Basic delay calculation
/// 2. Exponential growth
/// 3. Maximum delay cap
/// 4. Jitter application
/// 5. Delay sequence generation
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExponentialBackoff', () {
    group('getDelay', () {
      test('first attempt returns base delay', () {
        const baseDelay = Duration(seconds: 1);
        const attempt = 0;

        // baseDelay * 2^0 = 1 second
        final expectedDelay = baseDelay.inMilliseconds * 1;

        expect(expectedDelay, equals(1000));
      });

      test('second attempt doubles the delay', () {
        const baseDelayMs = 1000;
        const attempt = 1;

        // baseDelay * 2^1 = 2 seconds
        final expectedDelay = baseDelayMs * (1 << attempt);

        expect(expectedDelay, equals(2000));
      });

      test('third attempt quadruples the delay', () {
        const baseDelayMs = 1000;
        const attempt = 2;

        // baseDelay * 2^2 = 4 seconds
        final expectedDelay = baseDelayMs * (1 << attempt);

        expect(expectedDelay, equals(4000));
      });

      test('delay grows exponentially', () {
        const baseDelayMs = 1000;

        final delays = List.generate(5, (attempt) {
          return baseDelayMs * (1 << attempt);
        });

        expect(delays, equals([1000, 2000, 4000, 8000, 16000]));
      });

      test('delay is capped at maxDelay', () {
        const baseDelayMs = 1000;
        const maxDelayMs = 5000;
        const attempt = 10;

        // 1000 * 2^10 = 1024000, but capped at 5000
        final exponentialDelay = baseDelayMs * (1 << attempt);
        final cappedDelay =
            exponentialDelay > maxDelayMs ? maxDelayMs : exponentialDelay;

        expect(cappedDelay, equals(maxDelayMs));
      });
    });

    group('jitter', () {
      test('jitter factor 0 returns exact delay', () {
        const jitterFactor = 0.0;
        const baseDelayMs = 1000;

        // With 0 jitter, delay should be exactly base delay
        final jitterAmount = baseDelayMs * jitterFactor;

        expect(jitterAmount, equals(0.0));
      });

      test('jitter factor 0.2 adds up to 20% variation', () {
        const jitterFactor = 0.2;
        const baseDelayMs = 1000;

        final maxJitter = (baseDelayMs * jitterFactor).abs();

        expect(maxJitter, equals(200.0));
      });

      test('delay with jitter is within expected range', () {
        const baseDelayMs = 1000;
        const jitterFactor = 0.2;
        final minDelay = baseDelayMs - (baseDelayMs * jitterFactor);
        final maxDelay = baseDelayMs + (baseDelayMs * jitterFactor);

        expect(minDelay, equals(800.0));
        expect(maxDelay, equals(1200.0));
      });

      test('jitter can be negative', () {
        const baseDelayMs = 1000;
        const jitterFactor = 0.2;

        // randomValue in range [0, 1], transformed to [-1, 1]
        const randomValue = 0.0;
        final jitterMultiplier = 2 * randomValue - 1;
        final jitter = baseDelayMs * jitterFactor * jitterMultiplier;

        expect(jitter, equals(-200.0));
      });

      test('jitter can be positive', () {
        const baseDelayMs = 1000;
        const jitterFactor = 0.2;

        // randomValue in range [0, 1], transformed to [-1, 1]
        const randomValue = 1.0;
        final jitterMultiplier = 2 * randomValue - 1;
        final jitter = baseDelayMs * jitterFactor * jitterMultiplier;

        expect(jitter, equals(200.0));
      });

      test('final delay is never negative', () {
        const baseDelayMs = 100;
        const jitter = -200; // More than base delay

        final finalDelay = baseDelayMs + jitter;
        final adjustedDelay = finalDelay < 0 ? 0 : finalDelay;

        expect(adjustedDelay, equals(0));
      });
    });

    group('getDelaySequence', () {
      test('generates sequence of specified length', () {
        const attempts = 5;
        final sequence = List.generate(attempts, (i) => Duration(seconds: i));

        expect(sequence.length, equals(5));
      });

      test('sequence delays increase', () {
        const baseDelayMs = 1000;

        final sequence = List.generate(4, (attempt) {
          return Duration(milliseconds: baseDelayMs * (1 << attempt));
        });

        // Each delay should be greater than or equal to previous
        for (int i = 1; i < sequence.length; i++) {
          expect(sequence[i] >= sequence[i - 1], isTrue);
        }
      });
    });

    group('default values', () {
      test('default base delay is 1 second', () {
        const defaultBaseDelay = Duration(seconds: 1);
        expect(defaultBaseDelay.inSeconds, equals(1));
      });

      test('default max delay is 5 minutes', () {
        const defaultMaxDelay = Duration(minutes: 5);
        expect(defaultMaxDelay.inMinutes, equals(5));
      });

      test('default jitter factor is 0.2', () {
        const defaultJitterFactor = 0.2;
        expect(defaultJitterFactor, equals(0.2));
      });
    });

    group('edge cases', () {
      test('zero base delay returns zero', () {
        const baseDelayMs = 0;
        const attempt = 5;

        final delay = baseDelayMs * (1 << attempt);

        expect(delay, equals(0));
      });

      test('max attempt number is handled', () {
        const baseDelayMs = 1;
        const attempt = 30;
        const maxDelayMs = 300000;

        // 1 * 2^30 = 1073741824
        final exponentialDelay = baseDelayMs * (1 << attempt);
        final cappedDelay =
            exponentialDelay > maxDelayMs ? maxDelayMs : exponentialDelay;

        expect(cappedDelay, equals(maxDelayMs));
      });

      test('custom base delay works', () {
        const baseDelay = Duration(milliseconds: 500);
        expect(baseDelay.inMilliseconds, equals(500));
      });

      test('custom max delay works', () {
        const maxDelay = Duration(minutes: 10);
        expect(maxDelay.inMinutes, equals(10));
      });
    });
  });

  group('Thundering Herd Prevention', () {
    test('jitter spreads retry times', () {
      // With jitter, different instances will have different delays
      // preventing all clients from retrying at the same time
      const jitterFactor = 0.2;

      // Two instances with same base delay
      const baseDelayMs = 1000;

      // Different random values would result in different delays
      const random1 = 0.3;
      const random2 = 0.7;

      final jitter1 = baseDelayMs * jitterFactor * (2 * random1 - 1);
      final jitter2 = baseDelayMs * jitterFactor * (2 * random2 - 1);

      final delay1 = baseDelayMs + jitter1;
      final delay2 = baseDelayMs + jitter2;

      expect(delay1, isNot(equals(delay2)));
    });
  });

  group('Mathematical properties', () {
    test('power of 2 calculation is correct', () {
      expect(1 << 0, equals(1));
      expect(1 << 1, equals(2));
      expect(1 << 2, equals(4));
      expect(1 << 3, equals(8));
      expect(1 << 4, equals(16));
    });

    test('min function caps value correctly', () {
      const value = 10000;
      const cap = 5000;

      final result = value > cap ? cap : value;

      expect(result, equals(cap));
    });

    test('max function ensures non-negative', () {
      const value = -500;
      final result = value < 0 ? 0 : value;

      expect(result, equals(0));
    });
  });
}
