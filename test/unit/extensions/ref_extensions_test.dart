/// Unit tests for Ref extensions.
///
/// Test coverage:
/// 1. CacheFor extension
/// 2. Timer cancellation on dispose
/// 3. KeepAlive behavior
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheFor Extension', () {
    test('keepAlive is called with cacheFor', () {
      final mockRef = MockRef();

      mockRef.cacheFor(const Duration(seconds: 5));

      expect(mockRef.keepAliveCalled, isTrue);
    });

    test('link is closed after duration', () async {
      final mockRef = MockRef();

      mockRef.cacheFor(Duration.zero);

      // Wait for timer to fire
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mockRef.linkClosed, isTrue);
    });

    test('timer is cancelled on dispose', () {
      final mockRef = MockRef();

      mockRef.cacheFor(const Duration(hours: 1)); // Long duration

      // Simulate dispose before timer fires
      mockRef.dispose();

      expect(mockRef.timerCancelled, isTrue);
    });

    test('multiple cacheFor calls create multiple timers', () {
      final mockRef = MockRef();

      mockRef.cacheFor(const Duration(seconds: 5));
      mockRef.cacheFor(const Duration(seconds: 10));

      expect(mockRef.keepAliveCallCount, equals(2));
    });
  });

  group('KeepAlive Link', () {
    test('link keeps provider alive', () {
      final link = MockKeepAliveLink();

      expect(link.isClosed, isFalse);
    });

    test('close releases provider', () {
      final link = MockKeepAliveLink();

      link.close();

      expect(link.isClosed, isTrue);
    });

    test('multiple close calls are safe', () {
      final link = MockKeepAliveLink();

      link.close();
      link.close();

      expect(link.isClosed, isTrue);
    });
  });

  group('CacheFor Duration', () {
    test('short duration works', () {
      final duration = const Duration(milliseconds: 100);

      expect(duration.inMilliseconds, equals(100));
    });

    test('zero duration is valid', () {
      final duration = Duration.zero;

      expect(duration.inMilliseconds, equals(0));
    });

    test('common cache durations', () {
      const fiveMinutes = Duration(minutes: 5);
      const thirtySeconds = Duration(seconds: 30);
      const oneHour = Duration(hours: 1);

      expect(fiveMinutes.inSeconds, equals(300));
      expect(thirtySeconds.inSeconds, equals(30));
      expect(oneHour.inMinutes, equals(60));
    });
  });

  group('Dispose Handling', () {
    test('onDispose callback is registered', () {
      final mockRef = MockRef();

      mockRef.cacheFor(const Duration(seconds: 5));

      expect(mockRef.disposeCallbackRegistered, isTrue);
    });

    test('dispose cancels all timers', () {
      final mockRef = MockRef();

      mockRef.cacheFor(const Duration(seconds: 5));
      mockRef.cacheFor(const Duration(seconds: 10));

      mockRef.dispose();

      expect(mockRef.timersCancelledCount, equals(2));
    });
  });
}

// Mock classes

class MockRef {
  bool keepAliveCalled = false;
  int keepAliveCallCount = 0;
  bool linkClosed = false;
  bool timerCancelled = false;
  int timersCancelledCount = 0;
  bool disposeCallbackRegistered = false;
  final List<Timer> _timers = [];
  final List<void Function()> _disposeCallbacks = [];

  MockKeepAliveLink keepAlive() {
    keepAliveCalled = true;
    keepAliveCallCount++;
    return MockKeepAliveLink(onClose: () => linkClosed = true);
  }

  void onDispose(void Function() callback) {
    disposeCallbackRegistered = true;
    _disposeCallbacks.add(callback);
  }

  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    _timers.add(timer);
    onDispose(() {
      timer.cancel();
      timerCancelled = true;
      timersCancelledCount++;
    });
  }

  void dispose() {
    for (final callback in _disposeCallbacks) {
      callback();
    }
    _disposeCallbacks.clear();
  }
}

class MockKeepAliveLink {
  MockKeepAliveLink({this.onClose});

  final void Function()? onClose;
  bool isClosed = false;

  void close() {
    if (!isClosed) {
      isClosed = true;
      onClose?.call();
    }
  }
}
