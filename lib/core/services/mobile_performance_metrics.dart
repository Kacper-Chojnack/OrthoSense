import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service for collecting performance metrics on mobile device.
/// Collects real-world data for thesis charts and documentation.
///
/// Usage:
/// 1. Add to your main.dart or a provider:
///    final metrics = MobilePerformanceMetrics();
///    await metrics.startSession("live_analysis");
///
/// 2. Record frame processing times:
///    metrics.recordFrameTime(frameLatencyMs);
///
/// 3. End session and export:
///    final report = await metrics.endSession();
///    await metrics.exportToJson();
class MobilePerformanceMetrics {
  static final MobilePerformanceMetrics _instance =
      MobilePerformanceMetrics._internal();
  factory MobilePerformanceMetrics() => _instance;
  MobilePerformanceMetrics._internal();

  // Session data
  String? _sessionName;
  DateTime? _sessionStart;
  DateTime? _sessionEnd;
  final List<double> _frameLatencies = [];
  final List<double> _inferenceLatencies = [];
  final List<_ResourceSample> _resourceSamples = [];

  // Timers
  Timer? _resourceSamplingTimer;
  final Stopwatch _sessionStopwatch = Stopwatch();

  // Memory baseline
  int? _baselineMemoryMB;

  /// Start a new metrics collection session.
  Future<void> startSession(String sessionName) async {
    _sessionName = sessionName;
    _sessionStart = DateTime.now();
    _frameLatencies.clear();
    _inferenceLatencies.clear();
    _resourceSamples.clear();
    _sessionStopwatch.reset();
    _sessionStopwatch.start();

    // Get baseline memory
    _baselineMemoryMB = await _getCurrentMemoryMB();

    // Start periodic resource sampling (every 5 seconds)
    _resourceSamplingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _sampleResources(),
    );

    debugPrint('📊 Performance metrics session started: $sessionName');
  }

  /// Record a single frame processing time in milliseconds.
  void recordFrameTime(double latencyMs) {
    if (_sessionStart == null) return;
    _frameLatencies.add(latencyMs);
  }

  /// Record ML inference time in milliseconds.
  void recordInferenceTime(double latencyMs) {
    if (_sessionStart == null) return;
    _inferenceLatencies.add(latencyMs);
  }

  /// Sample current resource usage.
  Future<void> _sampleResources() async {
    if (_sessionStart == null) return;

    final memoryMB = await _getCurrentMemoryMB();
    final elapsedSeconds = _sessionStopwatch.elapsedMilliseconds / 1000;

    _resourceSamples.add(_ResourceSample(
      timestampSeconds: elapsedSeconds,
      memoryMB: memoryMB,
      // Note: Actual CPU/battery metrics require platform-specific code
      cpuPercent: null,
      batteryPercent: null,
    ));
  }

  /// Get current memory usage in MB.
  Future<int> _getCurrentMemoryMB() async {
    // This is an approximation - actual implementation would use
    // platform-specific memory APIs
    if (Platform.isIOS) {
      // On iOS, we'd use ProcessInfo or similar
      return 0; // Placeholder
    } else if (Platform.isAndroid) {
      // On Android, we'd use Debug.getNativeHeapAllocatedSize()
      return 0; // Placeholder
    }
    return 0;
  }

  /// End the current session and generate a report.
  Future<PerformanceReport?> endSession() async {
    if (_sessionStart == null) return null;

    _sessionStopwatch.stop();
    _sessionEnd = DateTime.now();
    _resourceSamplingTimer?.cancel();

    // Take final resource sample
    await _sampleResources();

    // Calculate statistics
    final report = PerformanceReport(
      sessionName: _sessionName ?? 'unknown',
      startTime: _sessionStart!,
      endTime: _sessionEnd!,
      durationSeconds: _sessionStopwatch.elapsedMilliseconds / 1000,
      frameStats: _calculateStats(_frameLatencies),
      inferenceStats: _calculateStats(_inferenceLatencies),
      resourceSamples: List.from(_resourceSamples),
      totalFrames: _frameLatencies.length,
      averageFps: _frameLatencies.isNotEmpty
          ? 1000 / (_frameLatencies.reduce((a, b) => a + b) / _frameLatencies.length)
          : 0,
    );

    debugPrint('📊 Performance session ended: ${report.sessionName}');
    debugPrint('   Frames: ${report.totalFrames}, Avg FPS: ${report.averageFps.toStringAsFixed(1)}');
    debugPrint('   Frame latency - Mean: ${report.frameStats.mean.toStringAsFixed(1)}ms, P95: ${report.frameStats.p95.toStringAsFixed(1)}ms');

    return report;
  }

  /// Calculate statistics from a list of latencies.
  LatencyStats _calculateStats(List<double> latencies) {
    if (latencies.isEmpty) {
      return LatencyStats.empty();
    }

    final sorted = List<double>.from(latencies)..sort();
    final count = sorted.length;

    return LatencyStats(
      count: count,
      min: sorted.first,
      max: sorted.last,
      mean: sorted.reduce((a, b) => a + b) / count,
      median: count.isOdd
          ? sorted[count ~/ 2]
          : (sorted[count ~/ 2 - 1] + sorted[count ~/ 2]) / 2,
      p95: sorted[(count * 0.95).floor().clamp(0, count - 1)],
      p99: sorted[(count * 0.99).floor().clamp(0, count - 1)],
      stdDev: _calculateStdDev(sorted),
    );
  }

  double _calculateStdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / (values.length - 1));
  }

  double sqrt(double value) {
    // Simple Newton-Raphson sqrt
    if (value <= 0) return 0;
    double x = value;
    double y = (x + 1) / 2;
    while (y < x) {
      x = y;
      y = (x + value / x) / 2;
    }
    return x;
  }

  /// Export the last session report to a JSON file.
  Future<String?> exportToJson() async {
    final report = await endSession();
    if (report == null) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/perf_${report.sessionName}_$timestamp.json');

      final jsonData = report.toJson();
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonData));

      debugPrint('📊 Performance report exported to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ Failed to export performance report: $e');
      return null;
    }
  }

  /// Get raw frame latencies for charting.
  List<double> get frameLatencies => List.unmodifiable(_frameLatencies);

  /// Get raw inference latencies for charting.
  List<double> get inferenceLatencies => List.unmodifiable(_inferenceLatencies);
}

/// Statistics for latency measurements.
class LatencyStats {
  final int count;
  final double min;
  final double max;
  final double mean;
  final double median;
  final double p95;
  final double p99;
  final double stdDev;

  const LatencyStats({
    required this.count,
    required this.min,
    required this.max,
    required this.mean,
    required this.median,
    required this.p95,
    required this.p99,
    required this.stdDev,
  });

  factory LatencyStats.empty() => const LatencyStats(
        count: 0,
        min: 0,
        max: 0,
        mean: 0,
        median: 0,
        p95: 0,
        p99: 0,
        stdDev: 0,
      );

  Map<String, dynamic> toJson() => {
        'count': count,
        'min_ms': double.parse(min.toStringAsFixed(2)),
        'max_ms': double.parse(max.toStringAsFixed(2)),
        'mean_ms': double.parse(mean.toStringAsFixed(2)),
        'median_ms': double.parse(median.toStringAsFixed(2)),
        'p95_ms': double.parse(p95.toStringAsFixed(2)),
        'p99_ms': double.parse(p99.toStringAsFixed(2)),
        'std_dev_ms': double.parse(stdDev.toStringAsFixed(2)),
      };
}

/// Resource usage sample at a point in time.
class _ResourceSample {
  final double timestampSeconds;
  final int memoryMB;
  final double? cpuPercent;
  final double? batteryPercent;

  const _ResourceSample({
    required this.timestampSeconds,
    required this.memoryMB,
    this.cpuPercent,
    this.batteryPercent,
  });

  Map<String, dynamic> toJson() => {
        'timestamp_seconds': double.parse(timestampSeconds.toStringAsFixed(2)),
        'memory_mb': memoryMB,
        if (cpuPercent != null) 'cpu_percent': cpuPercent,
        if (batteryPercent != null) 'battery_percent': batteryPercent,
      };
}

/// Complete performance report for a session.
class PerformanceReport {
  final String sessionName;
  final DateTime startTime;
  final DateTime endTime;
  final double durationSeconds;
  final LatencyStats frameStats;
  final LatencyStats inferenceStats;
  final List<_ResourceSample> resourceSamples;
  final int totalFrames;
  final double averageFps;

  const PerformanceReport({
    required this.sessionName,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.frameStats,
    required this.inferenceStats,
    required this.resourceSamples,
    required this.totalFrames,
    required this.averageFps,
  });

  Map<String, dynamic> toJson() => {
        'session_name': sessionName,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'duration_seconds': double.parse(durationSeconds.toStringAsFixed(2)),
        'total_frames': totalFrames,
        'average_fps': double.parse(averageFps.toStringAsFixed(2)),
        'frame_latency': frameStats.toJson(),
        'inference_latency': inferenceStats.toJson(),
        'resource_samples': resourceSamples.map((s) => s.toJson()).toList(),
        'summary': {
          'meets_100ms_threshold': frameStats.p95 < 100,
          'meets_15fps_target': averageFps >= 15,
        },
      };
}
