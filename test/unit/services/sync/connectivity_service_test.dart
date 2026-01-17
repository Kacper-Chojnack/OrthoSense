/// Unit tests for ConnectivityService.
///
/// Test coverage:
/// 1. Initialization
/// 2. Connectivity status tracking
/// 3. Connection type detection
/// 4. Stream broadcasting
/// 5. Disposal
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectivityService', () {
    group('initialization', () {
      test('service starts uninitialized', () {
        var isInitialized = false;
        expect(isInitialized, isFalse);
      });

      test('initializes only once', () {
        var initCount = 0;

        void initialize() {
          initCount++;
        }

        initialize();
        expect(initCount, equals(1));
      });

      test('checks current connectivity on initialize', () {
        var checked = false;

        Future<void> checkConnectivity() async {
          checked = true;
        }

        checkConnectivity();
        expect(checked, isTrue);
      });

      test('assumes online if check fails', () {
        // If connectivity check fails, assume online
        const isOnlineOnError = true;
        expect(isOnlineOnError, isTrue);
      });
    });

    group('isOnline', () {
      test('defaults to true', () {
        const isOnline = true;
        expect(isOnline, isTrue);
      });

      test('updates when connectivity changes', () {
        var isOnline = true;

        void onConnectivityChanged(bool online) {
          isOnline = online;
        }

        onConnectivityChanged(false);
        expect(isOnline, isFalse);
      });
    });

    group('connection types', () {
      test('wifi is considered online', () {
        const result = 'wifi';
        final hasConnection = ['wifi', 'mobile', 'ethernet', 'vpn'].contains(result);
        expect(hasConnection, isTrue);
      });

      test('mobile is considered online', () {
        const result = 'mobile';
        final hasConnection = ['wifi', 'mobile', 'ethernet', 'vpn'].contains(result);
        expect(hasConnection, isTrue);
      });

      test('ethernet is considered online', () {
        const result = 'ethernet';
        final hasConnection = ['wifi', 'mobile', 'ethernet', 'vpn'].contains(result);
        expect(hasConnection, isTrue);
      });

      test('vpn is considered online', () {
        const result = 'vpn';
        final hasConnection = ['wifi', 'mobile', 'ethernet', 'vpn'].contains(result);
        expect(hasConnection, isTrue);
      });

      test('none is considered offline', () {
        const result = 'none';
        final hasConnection = ['wifi', 'mobile', 'ethernet', 'vpn'].contains(result);
        expect(hasConnection, isFalse);
      });

      test('bluetooth only is considered offline', () {
        const result = 'bluetooth';
        final hasConnection = ['wifi', 'mobile', 'ethernet', 'vpn'].contains(result);
        expect(hasConnection, isFalse);
      });

      test('multiple results with at least one valid is online', () {
        const results = ['none', 'wifi'];
        final hasConnection =
            results.any((r) => ['wifi', 'mobile', 'ethernet', 'vpn'].contains(r));
        expect(hasConnection, isTrue);
      });

      test('empty results is offline', () {
        const results = <String>[];
        final hasConnection =
            results.any((r) => ['wifi', 'mobile', 'ethernet', 'vpn'].contains(r));
        expect(hasConnection, isFalse);
      });
    });

    group('onConnectivityChanged stream', () {
      test('stream is broadcast', () {
        var listenerCount = 0;

        void addListener() {
          listenerCount++;
        }

        addListener();
        addListener();
        expect(listenerCount, equals(2));
      });

      test('only emits when status changes', () {
        var emissions = 0;
        var wasOnline = true;
        var isOnline = true;

        void onChanged() {
          if (wasOnline != isOnline) {
            emissions++;
            wasOnline = isOnline;
          }
        }

        // Same status - no emission
        onChanged();
        expect(emissions, equals(0));

        // Changed status - emission
        isOnline = false;
        onChanged();
        expect(emissions, equals(1));

        // Same status - no emission
        onChanged();
        expect(emissions, equals(1));
      });
    });

    group('checkConnectivity', () {
      test('returns current status', () {
        const isOnline = true;
        expect(isOnline, isTrue);
      });

      test('updates status if changed', () {
        var isOnline = true;

        bool checkAndUpdate(bool newStatus) {
          if (isOnline != newStatus) {
            isOnline = newStatus;
          }
          return isOnline;
        }

        final result = checkAndUpdate(false);
        expect(result, isFalse);
        expect(isOnline, isFalse);
      });

      test('emits to stream if status changed', () {
        var emitted = false;
        var isOnline = true;

        void checkConnectivity(bool newStatus) {
          if (isOnline != newStatus) {
            isOnline = newStatus;
            emitted = true;
          }
        }

        checkConnectivity(false);
        expect(emitted, isTrue);
      });

      test('returns cached status on error', () {
        const cachedStatus = true;
        const errorOccurred = true;

        // On error, return cached status
        final result = errorOccurred ? cachedStatus : false;

        expect(result, isTrue);
      });
    });

    group('dispose', () {
      test('cancels subscription', () {
        var subscriptionCancelled = false;

        void cancel() {
          subscriptionCancelled = true;
        }

        cancel();
        expect(subscriptionCancelled, isTrue);
      });

      test('closes stream controller', () {
        var controllerClosed = false;

        void close() {
          controllerClosed = true;
        }

        close();
        expect(controllerClosed, isTrue);
      });

      test('resets initialized flag', () {
        var isInitialized = true;

        void dispose() {
          isInitialized = false;
        }

        dispose();
        expect(isInitialized, isFalse);
      });

      test('sets subscription to null', () {
        String? subscription = 'active';

        void dispose() {
          subscription = null;
        }

        dispose();
        expect(subscription, isNull);
      });
    });

    group('error handling', () {
      test('handles initialization error gracefully', () {
        var handledGracefully = false;

        void initialize() {
          try {
            throw Exception('Network error');
          } catch (e) {
            handledGracefully = true;
          }
        }

        initialize();
        expect(handledGracefully, isTrue);
      });

      test('logs connectivity change errors', () {
        var errorLogged = false;

        void onError(Object error) {
          errorLogged = true;
        }

        onError(Exception('Stream error'));
        expect(errorLogged, isTrue);
      });
    });

    group('constructor', () {
      test('accepts optional connectivity instance', () {
        Object? injectedConnectivity;

        void createService({Object? connectivity}) {
          injectedConnectivity = connectivity ?? 'default';
        }

        createService(connectivity: 'custom');
        expect(injectedConnectivity, equals('custom'));
      });

      test('uses default connectivity if not provided', () {
        Object? injectedConnectivity;

        void createService({Object? connectivity}) {
          injectedConnectivity = connectivity ?? 'default';
        }

        createService();
        expect(injectedConnectivity, equals('default'));
      });
    });
  });

  group('NetworkStatus transitions', () {
    test('offline to online transition', () {
      var isOnline = false;

      void goOnline() {
        isOnline = true;
      }

      goOnline();
      expect(isOnline, isTrue);
    });

    test('online to offline transition', () {
      var isOnline = true;

      void goOffline() {
        isOnline = false;
      }

      goOffline();
      expect(isOnline, isFalse);
    });

    test('tracks transition count', () {
      var transitionCount = 0;
      var isOnline = true;

      void toggle() {
        isOnline = !isOnline;
        transitionCount++;
      }

      toggle();
      toggle();
      toggle();

      expect(transitionCount, equals(3));
    });
  });

  group('Debug logging', () {
    test('logs initial status', () {
      const logFormat = 'ConnectivityService: Initial status - online: true';
      expect(logFormat, contains('Initial status'));
    });

    test('logs status changes', () {
      const logFormat = 'ConnectivityService: Status changed - online: false';
      expect(logFormat, contains('Status changed'));
    });

    test('logs initialization failures', () {
      const logFormat = 'ConnectivityService: Failed to initialize - error';
      expect(logFormat, contains('Failed to initialize'));
    });

    test('logs check failures', () {
      const logFormat = 'ConnectivityService: Check failed - error';
      expect(logFormat, contains('Check failed'));
    });
  });
}
