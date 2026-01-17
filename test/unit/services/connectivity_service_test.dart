/// Unit tests for ConnectivityService.
///
/// Test coverage:
/// 1. Initialization
/// 2. Online/offline state
/// 3. Connectivity change detection
/// 4. Connection type checking
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/services/sync/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityService', () {
    late MockConnectivity mockConnectivity;
    late ConnectivityService service;
    late StreamController<List<ConnectivityResult>> connectivityController;

    setUp(() {
      mockConnectivity = MockConnectivity();
      connectivityController = StreamController<List<ConnectivityResult>>.broadcast();
      
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => connectivityController.stream);
      
      service = ConnectivityService(connectivity: mockConnectivity);
    });

    tearDown(() {
      connectivityController.close();
      service.dispose();
    });

    group('initialization', () {
      test('isInitialized is false before initialize', () {
        expect(service.isInitialized, isFalse);
      });

      test('initialize sets isInitialized to true', () async {
        await service.initialize();
        expect(service.isInitialized, isTrue);
      });

      test('initialize only runs once', () async {
        await service.initialize();
        await service.initialize(); // Second call should be no-op
        
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('defaults to online if check fails', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Network error'));
        
        await service.initialize();
        expect(service.isOnline, isTrue);
      });
    });

    group('online status', () {
      test('isOnline is true with wifi connection', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        
        await service.initialize();
        expect(service.isOnline, isTrue);
      });

      test('isOnline is true with mobile connection', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);
        
        await service.initialize();
        expect(service.isOnline, isTrue);
      });

      test('isOnline is true with ethernet connection', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.ethernet]);
        
        await service.initialize();
        expect(service.isOnline, isTrue);
      });

      test('isOnline is true with VPN connection', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.vpn]);
        
        await service.initialize();
        expect(service.isOnline, isTrue);
      });

      test('isOnline is false with no connection', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        
        await service.initialize();
        expect(service.isOnline, isFalse);
      });

      test('isOnline is false with bluetooth only', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.bluetooth]);
        
        await service.initialize();
        expect(service.isOnline, isFalse);
      });
    });

    group('connectivity changes', () {
      test('emits event when connectivity changes', () async {
        await service.initialize();
        
        final events = <bool>[];
        service.onConnectivityChanged.listen(events.add);
        
        // Change from wifi to none
        connectivityController.add([ConnectivityResult.none]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        expect(events, contains(false));
      });

      test('does not emit when connectivity stays same', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        
        await service.initialize();
        
        final events = <bool>[];
        service.onConnectivityChanged.listen(events.add);
        
        // Send same connectivity (wifi to wifi via mobile+wifi)
        connectivityController.add([ConnectivityResult.mobile, ConnectivityResult.wifi]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        // Should still be online, so no event
        expect(events, isEmpty);
      });

      test('going offline emits false', () async {
        await service.initialize();
        
        bool? lastEvent;
        service.onConnectivityChanged.listen((e) => lastEvent = e);
        
        connectivityController.add([ConnectivityResult.none]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        expect(lastEvent, isFalse);
        expect(service.isOnline, isFalse);
      });

      test('going online emits true', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        
        await service.initialize();
        expect(service.isOnline, isFalse);
        
        bool? lastEvent;
        service.onConnectivityChanged.listen((e) => lastEvent = e);
        
        connectivityController.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        expect(lastEvent, isTrue);
        expect(service.isOnline, isTrue);
      });
    });

    group('checkConnectivity', () {
      test('returns current online status', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        
        await service.initialize();
        final result = await service.checkConnectivity();
        
        expect(result, isTrue);
      });

      test('updates status if changed', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        
        await service.initialize();
        expect(service.isOnline, isTrue);
        
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        
        final result = await service.checkConnectivity();
        expect(result, isFalse);
        expect(service.isOnline, isFalse);
      });

      test('returns last known status on error', () async {
        await service.initialize();
        
        when(() => mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Check failed'));
        
        final result = await service.checkConnectivity();
        expect(result, isTrue); // Last known status
      });
    });

    group('dispose', () {
      test('sets isInitialized to false', () async {
        await service.initialize();
        expect(service.isInitialized, isTrue);
        
        service.dispose();
        expect(service.isInitialized, isFalse);
      });
    });
  });

  group('Connection type helpers', () {
    test('wifi is considered online', () {
      const results = [ConnectivityResult.wifi];
      final hasConnection = results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );
      expect(hasConnection, isTrue);
    });

    test('mobile is considered online', () {
      const results = [ConnectivityResult.mobile];
      final hasConnection = results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );
      expect(hasConnection, isTrue);
    });

    test('ethernet is considered online', () {
      const results = [ConnectivityResult.ethernet];
      final hasConnection = results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );
      expect(hasConnection, isTrue);
    });

    test('none is not considered online', () {
      const results = [ConnectivityResult.none];
      final hasConnection = results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );
      expect(hasConnection, isFalse);
    });

    test('multiple results with at least one valid is online', () {
      const results = [ConnectivityResult.bluetooth, ConnectivityResult.wifi];
      final hasConnection = results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );
      expect(hasConnection, isTrue);
    });
  });
}
