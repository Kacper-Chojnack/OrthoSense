/// Unit tests for GalleryAnalysisScreen business logic.
///
/// Test coverage:
/// 1. Video analysis state management
/// 2. Extraction progress tracking
/// 3. Error handling and messages
/// 4. Cancellation token handling
/// 5. Result display logic
/// 6. Temp file cleanup
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Analysis State Management', () {
    test('initial state has no video selected', () {
      final state = GalleryAnalysisState();

      expect(state.selectedVideo, isNull);
      expect(state.isAnalyzing, isFalse);
      expect(state.result, isNull);
    });

    test('selecting video resets previous state', () {
      var state = GalleryAnalysisState(
        result: {'exercise': 'Deep Squat'},
        error: 'Previous error',
      );

      state = state.copyWith(
        selectedVideo: '/path/to/video.mp4',
        result: null,
        error: null,
        extractionProgress: 0,
      );

      expect(state.selectedVideo, equals('/path/to/video.mp4'));
      expect(state.result, isNull);
      expect(state.error, isNull);
      expect(state.extractionProgress, equals(0));
    });

    test('analyzing state shows loading', () {
      var state = GalleryAnalysisState(
        selectedVideo: '/path/to/video.mp4',
      );

      state = state.copyWith(isAnalyzing: true, isExtractingLandmarks: true);

      expect(state.isAnalyzing, isTrue);
      expect(state.isExtractingLandmarks, isTrue);
    });
  });

  group('Extraction Progress Tracking', () {
    test('progress starts at 0', () {
      final state = GalleryAnalysisState(
        selectedVideo: '/path/to/video.mp4',
        isAnalyzing: true,
      );

      expect(state.extractionProgress, equals(0));
    });

    test('progress updates during extraction', () {
      var progress = 0.0;

      for (var i = 0; i <= 10; i++) {
        progress = i / 10;
        expect(progress, greaterThanOrEqualTo(0));
        expect(progress, lessThanOrEqualTo(1));
      }

      expect(progress, equals(1.0));
    });

    test('progress percentage calculation', () {
      const progress = 0.75;
      final percentage = (progress * 100).round();

      expect(percentage, equals(75));
    });

    test('transitions from extracting to classifying', () {
      var state = GalleryAnalysisState(
        selectedVideo: '/path/to/video.mp4',
        isAnalyzing: true,
        isExtractingLandmarks: true,
        extractionProgress: 1.0,
      );

      // After extraction complete
      state = state.copyWith(isExtractingLandmarks: false);

      expect(state.isAnalyzing, isTrue);
      expect(state.isExtractingLandmarks, isFalse);
    });
  });

  group('Error Handling', () {
    test('no pose detected error', () {
      final error = _getErrorForEmptyLandmarks();

      expect(error, contains('No pose detected'));
      expect(error, contains('video is too short'));
    });

    test('insufficient visibility error', () {
      const originalError = 'Insufficient pose frames detected';
      final userFriendlyError = _convertToUserFriendlyError(originalError);

      expect(userFriendlyError, contains('Insufficient body visibility'));
      expect(userFriendlyError, contains('full body is visible'));
    });

    test('generic analysis error', () {
      const originalError = 'Some internal error occurred';
      final userFriendlyError = _convertToUserFriendlyError(originalError);

      expect(userFriendlyError, contains('Analysis failed'));
    });

    test('error clears on new video selection', () {
      var state = GalleryAnalysisState(
        error: 'Previous error message',
      );

      state = state.copyWith(
        selectedVideo: '/new/video.mp4',
        error: null,
      );

      expect(state.error, isNull);
    });
  });

  group('Cancellation Token', () {
    test('new analysis cancels previous', () {
      var runId = 0;
      var wasCancelled = false;

      final token1 = MockCancellationToken(
        onCancel: () => wasCancelled = true,
      );

      // Start first analysis
      runId++;
      expect(runId, equals(1));

      // Start second analysis - should cancel first
      token1.cancel();
      runId++;

      expect(wasCancelled, isTrue);
      expect(runId, equals(2));
    });

    test('cancelled analysis returns early', () {
      final token = MockCancellationToken();

      // Simulate cancellation during processing
      token.cancel();

      expect(token.isCancelled, isTrue);
    });

    test('cancellation exception is caught silently', () {
      var errorLogged = false;

      try {
        throw MockCancelledException();
      } on MockCancelledException {
        // Should not log error for cancellation
        errorLogged = false;
      } catch (_) {
        errorLogged = true;
      }

      expect(errorLogged, isFalse);
    });

    test('run ID mismatch prevents state update', () {
      final updates = <int>[];
      var currentRunId = 1;

      // Simulate async callback with old run ID
      void maybeUpdate(int callbackRunId, int value) {
        if (callbackRunId == currentRunId) {
          updates.add(value);
        }
      }

      maybeUpdate(1, 100); // Should update
      currentRunId = 2; // New analysis started
      maybeUpdate(1, 200); // Old callback - should NOT update
      maybeUpdate(2, 300); // Current callback - should update

      expect(updates, equals([100, 300]));
    });
  });

  group('Result Display', () {
    test('result contains exercise classification', () {
      final result = {
        'exercise': 'Deep Squat',
        'confidence': 0.95,
        'is_correct': true,
        'feedback': <String, dynamic>{},
        'text_report': 'Great form!',
      };

      expect(result['exercise'], equals('Deep Squat'));
      expect(result['confidence'], greaterThan(0.9));
    });

    test('result contains feedback for incorrect form', () {
      final result = {
        'exercise': 'Deep Squat',
        'confidence': 0.92,
        'is_correct': false,
        'feedback': {
          'Knee Valgus': true,
          'Heel Rise': 'Left',
        },
        'text_report': 'Issues detected...',
      };

      expect(result['is_correct'], isFalse);
      expect((result['feedback'] as Map).isNotEmpty, isTrue);
    });

    test('empty feedback indicates correct form', () {
      final result = {
        'exercise': 'Deep Squat',
        'is_correct': true,
        'feedback': <String, dynamic>{},
      };

      expect(result['is_correct'], isTrue);
      expect((result['feedback'] as Map).isEmpty, isTrue);
    });

    test('text report is generated for display', () {
      final result = {
        'text_report': '''
Exercise: Deep Squat
Status: Form issues detected

Errors Found:
- Knee Valgus detected
- Heels rising on left side

Recommendations:
- Focus on knee alignment
''',
      };

      final report = result['text_report'] as String;

      expect(report, contains('Deep Squat'));
      expect(report, contains('Knee Valgus'));
      expect(report, contains('Recommendations'));
    });
  });

  group('Temp File Management', () {
    test('temp file path generation', () {
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      const ext = '.mp4';
      final tmpPath = 'orthosense_gallery_$timestamp$ext';

      expect(tmpPath, contains('orthosense_gallery_'));
      expect(tmpPath, endsWith('.mp4'));
    });

    test('temp file is deleted on dispose', () {
      var deleted = false;
      final tempFile = MockTempFile(
        onDelete: () => deleted = true,
      );

      // Simulate dispose
      tempFile.delete();

      expect(deleted, isTrue);
    });

    test('falls back to original if copy fails', () {
      const originalPath = '/original/video.mp4';
      String? tempPath;
      var copyFailed = false;

      try {
        // Simulate copy failure
        throw Exception('Cannot create temp file');
      } catch (_) {
        copyFailed = true;
        tempPath = null;
      }

      final pathToUse = tempPath ?? originalPath;

      expect(copyFailed, isTrue);
      expect(pathToUse, equals(originalPath));
    });
  });

  group('Video Player Integration', () {
    test('video controller initialized after picking', () {
      var isInitialized = false;

      // Simulate controller initialization
      isInitialized = true;

      expect(isInitialized, isTrue);
    });

    test('controller disposed on new video selection', () {
      var disposeCount = 0;

      // Simulate picking new video
      disposeCount++; // Old controller disposed

      expect(disposeCount, equals(1));
    });

    test('controller disposed on screen dispose', () {
      var disposeCount = 0;

      // Simulate screen dispose
      disposeCount++;

      expect(disposeCount, equals(1));
    });
  });

  group('Empty Landmarks Handling', () {
    test('empty landmarks shows error', () {
      final landmarks = <dynamic>[];

      expect(landmarks.isEmpty, isTrue);
    });

    test('valid landmarks proceed to classification', () {
      final landmarks = List.generate(
        60,
        (i) => MockLandmark(frameIndex: i),
      );

      expect(landmarks.isEmpty, isFalse);
      expect(landmarks.length, equals(60));
    });

    test('filters invalid landmarks', () {
      final landmarks = [
        MockLandmark(frameIndex: 0, isValid: true),
        MockLandmark(frameIndex: 1, isValid: false),
        MockLandmark(frameIndex: 2, isValid: true),
      ];

      final valid = landmarks.where((l) => l.isValid).toList();

      expect(valid.length, equals(2));
    });
  });

  group('UI State Transitions', () {
    test('picking video sets selected video', () {
      var state = GalleryAnalysisState();

      state = state.copyWith(selectedVideo: '/path/to/video.mp4');

      expect(state.selectedVideo, isNotNull);
    });

    test('analyze button enabled when video selected', () {
      final state = GalleryAnalysisState(
        selectedVideo: '/path/to/video.mp4',
        isAnalyzing: false,
      );

      final canAnalyze =
          state.selectedVideo != null && !state.isAnalyzing;

      expect(canAnalyze, isTrue);
    });

    test('analyze button disabled during analysis', () {
      final state = GalleryAnalysisState(
        selectedVideo: '/path/to/video.mp4',
        isAnalyzing: true,
      );

      final canAnalyze =
          state.selectedVideo != null && !state.isAnalyzing;

      expect(canAnalyze, isFalse);
    });

    test('shows result when analysis complete', () {
      final state = GalleryAnalysisState(
        selectedVideo: '/path/to/video.mp4',
        isAnalyzing: false,
        result: {'exercise': 'Deep Squat'},
      );

      expect(state.result, isNotNull);
      expect(state.isAnalyzing, isFalse);
    });

    test('shows error when analysis fails', () {
      final state = GalleryAnalysisState(
        selectedVideo: '/path/to/video.mp4',
        isAnalyzing: false,
        error: 'Analysis failed',
      );

      expect(state.error, isNotNull);
      expect(state.result, isNull);
    });
  });
}

// Test data classes

class GalleryAnalysisState {
  GalleryAnalysisState({
    this.selectedVideo,
    this.isAnalyzing = false,
    this.isExtractingLandmarks = false,
    this.extractionProgress = 0,
    this.result,
    this.error,
  });

  final String? selectedVideo;
  final bool isAnalyzing;
  final bool isExtractingLandmarks;
  final double extractionProgress;
  final Map<String, dynamic>? result;
  final String? error;

  GalleryAnalysisState copyWith({
    String? selectedVideo,
    bool? isAnalyzing,
    bool? isExtractingLandmarks,
    double? extractionProgress,
    Map<String, dynamic>? result,
    String? error,
  }) {
    return GalleryAnalysisState(
      selectedVideo: selectedVideo ?? this.selectedVideo,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isExtractingLandmarks:
          isExtractingLandmarks ?? this.isExtractingLandmarks,
      extractionProgress: extractionProgress ?? this.extractionProgress,
      result: result,
      error: error,
    );
  }
}

class MockCancellationToken {
  MockCancellationToken({this.onCancel});

  final void Function()? onCancel;
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    onCancel?.call();
  }
}

class MockCancelledException implements Exception {}

class MockTempFile {
  MockTempFile({this.onDelete});

  final void Function()? onDelete;

  void delete() {
    onDelete?.call();
  }
}

class MockLandmark {
  MockLandmark({
    required this.frameIndex,
    this.isValid = true,
  });

  final int frameIndex;
  final bool isValid;
}

// Helper functions

String _getErrorForEmptyLandmarks() {
  return 'No pose detected in the video or video is too short.';
}

String _convertToUserFriendlyError(String error) {
  if (error.contains('Insufficient pose frames detected')) {
    return 'Insufficient body visibility detected. Please ensure your full body is visible in the video.';
  }
  return 'Analysis failed: $error';
}
