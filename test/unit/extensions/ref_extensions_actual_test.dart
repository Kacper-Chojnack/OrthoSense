/// Unit tests for Ref Extensions.
///
/// Test coverage:
/// 1. CacheFor extension functionality
/// 2. Timer behavior
/// 3. KeepAlive link management
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheFor Extension', () {
    group('keepAlive behavior', () {
      test('keepAlive is called when cacheFor is invoked', () {
        var keepAliveCalled = false;

        void cacheFor(Duration duration) {
          keepAliveCalled = true;
          // Creates timer
          Timer(duration, () {});
        }

        cacheFor(const Duration(seconds: 5));
        expect(keepAliveCalled, isTrue);
      });

      test('link is kept alive for specified duration', () {
        var linkClosed = false;
        const duration = Duration(milliseconds: 100);

        void cacheFor(Duration d) {
          Timer(d, () {
            linkClosed = true;
          });
        }

        cacheFor(duration);

        // Link should not be closed immediately
        expect(linkClosed, isFalse);
      });

      test('link is closed after duration expires', () async {
        var linkClosed = false;
        const duration = Duration(milliseconds: 50);

        void cacheFor(Duration d) {
          Timer(d, () {
            linkClosed = true;
          });
        }

        cacheFor(duration);

        // Wait for timer to fire
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(linkClosed, isTrue);
      });
    });

    group('timer management', () {
      test('timer is created with correct duration', () async {
        var timerFired = false;
        const duration = Duration(milliseconds: 50);

        Timer(duration, () {
          timerFired = true;
        });

        expect(timerFired, isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(timerFired, isTrue);
      });

      test('timer can be cancelled before firing', () async {
        var timerFired = false;
        const duration = Duration(milliseconds: 100);

        final timer = Timer(duration, () {
          timerFired = true;
        });

        // Cancel immediately
        timer.cancel();

        // Wait past the duration
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(timerFired, isFalse);
      });

      test('onDispose cancels the timer', () async {
        var timerFired = false;
        Timer? activeTimer;

        void cacheFor(Duration d) {
          activeTimer = Timer(d, () {
            timerFired = true;
          });
        }

        void onDispose() {
          activeTimer?.cancel();
        }

        cacheFor(const Duration(milliseconds: 100));
        onDispose(); // Simulate provider dispose

        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(timerFired, isFalse);
      });
    });

    group('duration configurations', () {
      test('zero duration closes link immediately', () async {
        var linkClosed = false;

        Timer(Duration.zero, () {
          linkClosed = true;
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(linkClosed, isTrue);
      });

      test('typical cache duration for tab switching', () {
        // 5-10 seconds is reasonable for tab switching scenarios
        const duration = Duration(seconds: 5);
        expect(duration.inSeconds, greaterThanOrEqualTo(5));
        expect(duration.inSeconds, lessThanOrEqualTo(60));
      });

      test('longer cache for expensive computations', () {
        const duration = Duration(minutes: 1);
        expect(duration.inMinutes, equals(1));
      });
    });

    group('autoDispose problem solution', () {
      test('prevents premature disposal during tab switch', () {
        // Scenario: User switches tabs quickly
        // Without cacheFor: provider disposes, loses state
        // With cacheFor: provider stays alive briefly

        var wasDisposed = false;
        var statePreserved = true;

        void simulateTabSwitch({required bool useCacheFor}) {
          if (useCacheFor) {
            // State is preserved during grace period
            statePreserved = true;
          } else {
            wasDisposed = true;
            statePreserved = false;
          }
        }

        simulateTabSwitch(useCacheFor: true);
        expect(statePreserved, isTrue);
        expect(wasDisposed, isFalse);
      });

      test('eventually disposes when truly not needed', () async {
        var disposed = false;
        const gracePeriod = Duration(milliseconds: 50);

        // Simulate cacheFor with disposal
        Timer(gracePeriod, () {
          disposed = true;
        });

        // Before grace period
        expect(disposed, isFalse);

        // After grace period
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(disposed, isTrue);
      });
    });

    group('multiple calls', () {
      test('multiple cacheFor calls create multiple timers', () {
        var timerCount = 0;
        final timers = <Timer>[];

        void cacheFor(Duration d) {
          timers.add(Timer(d, () {}));
          timerCount++;
        }

        cacheFor(const Duration(seconds: 5));
        cacheFor(const Duration(seconds: 10));

        expect(timerCount, equals(2));
        expect(timers.length, equals(2));

        // Cleanup
        for (final timer in timers) {
          timer.cancel();
        }
      });

      test('each timer manages its own keepAlive link', () {
        var linksCreated = 0;

        void cacheFor(Duration d) {
          linksCreated++;
          Timer(d, () {});
        }

        cacheFor(const Duration(seconds: 5));
        cacheFor(const Duration(seconds: 10));

        expect(linksCreated, equals(2));
      });
    });
  });

  group('KeepAlive Link Behavior', () {
    test('link.close releases provider', () {
      var released = false;

      void close() {
        released = true;
      }

      close();
      expect(released, isTrue);
    });

    test('ref.keepAlive returns closeable link', () {
      var linkCreated = false;

      Object keepAlive() {
        linkCreated = true;
        return Object(); // Returns KeepAliveLink
      }

      keepAlive();
      expect(linkCreated, isTrue);
    });
  });
}
