
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/camera/data/repositories/mock_camera_repository.dart';
import 'package:orthosense/features/camera/domain/repositories/camera_repository.dart';
import 'package:orthosense/features/camera/presentation/providers/camera_providers.dart';

void main() {
  group('MockCameraRepository', () {
    late MockCameraRepository repository;

    setUp(() {
      repository = MockCameraRepository(
        frameIntervalMs: 50, // Faster for testing
        simulatedWidth: 320,
        simulatedHeight: 240,
      );
    });

    tearDown(() async {
      await repository.dispose();
    });

    test('initializes successfully', () async {
      expect(repository.isInitialized, isFalse);

      await repository.initialize();

      expect(repository.isInitialized, isTrue);
    });

    test('emits frames after initialization', () async {
      await repository.initialize();

      final frames = <dynamic>[];
      final subscription = repository.frameStream.listen(frames.add);

      // Wait for a few frames
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await subscription.cancel();

      expect(frames.length, greaterThan(2));
    });

    test('frames have correct dimensions', () async {
      await repository.initialize();

      final frame = await repository.frameStream.first;

      expect(frame.width, equals(320));
      expect(frame.height, equals(240));
      expect(frame.isValid, isTrue);
    });

    test('switchCamera toggles lens direction', () async {
      await repository.initialize();

      expect(
        repository.currentLensDirection,
        equals(CameraLensDirection.back),
      );

      await repository.switchCamera();

      expect(
        repository.currentLensDirection,
        equals(CameraLensDirection.front),
      );

      await repository.switchCamera();

      expect(
        repository.currentLensDirection,
        equals(CameraLensDirection.back),
      );
    });

    test('dispose stops frame emission', () async {
      await repository.initialize();

      var frameCount = 0;
      final subscription = repository.frameStream.listen((_) => frameCount++);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      final countBeforeDispose = frameCount;

      await repository.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // No new frames after dispose
      expect(frameCount, equals(countBeforeDispose));
      expect(repository.isInitialized, isFalse);
    });

    test('initialize with custom config', () async {
      await repository.initialize(
        const CameraConfig(
          lensDirection: CameraLensDirection.front,
          resolution: CameraResolution.high,
        ),
      );

      expect(
        repository.currentLensDirection,
        equals(CameraLensDirection.front),
      );
    });
  });

  group('CameraRepository DI', () {
    test('can override with mock in ProviderContainer', () {
      final mockRepo = MockCameraRepository();

      final container = ProviderContainer(
        overrides: [
          cameraRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      addTearDown(container.dispose);

      final repository = container.read(cameraRepositoryProvider);

      expect(repository, isA<MockCameraRepository>());
      expect(repository, equals(mockRepo));
    });
  });
}
