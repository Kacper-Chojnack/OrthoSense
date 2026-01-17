import 'dart:math';

/// Exponential backoff calculator for retry logic.
///
/// Implements exponential backoff with jitter to prevent
/// thundering herd problem when multiple clients retry simultaneously.
class ExponentialBackoff {
  ExponentialBackoff({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 5),
    this.jitterFactor = 0.2,
  });

  /// Initial delay before first retry.
  final Duration baseDelay;

  /// Maximum delay cap.
  final Duration maxDelay;

  /// Jitter factor (0.0 - 1.0) to randomize delay.
  final double jitterFactor;

  final _random = Random();

  /// Calculate delay for given attempt number (0-indexed).
  ///
  /// Formula: min(baseDelay * 2^attempt, maxDelay)
  Duration getDelay({required int attempt}) {
    // Cap attempt to avoid overflow (2^30 is ~1 billion which is more than enough)
    final safeAttempt = attempt.clamp(0, 30);
    final exponentialDelay = baseDelay.inMilliseconds * pow(2, safeAttempt);
    final cappedDelay = min(exponentialDelay, maxDelay.inMilliseconds.toDouble());
    return Duration(milliseconds: cappedDelay.toInt());
  }

  /// Calculate delay with jitter to prevent thundering herd.
  ///
  /// Adds random variation to the delay based on jitterFactor.
  Duration getDelayWithJitter({required int attempt}) {
    final baseDelayMs = getDelay(attempt: attempt).inMilliseconds;

    // Add jitter: ±jitterFactor of the base delay
    final jitter = (baseDelayMs * jitterFactor * (2 * _random.nextDouble() - 1))
        .round();

    final finalDelay = max(0, baseDelayMs + jitter);
    return Duration(milliseconds: finalDelay);
  }

  /// Get sequence of delays for multiple attempts.
  List<Duration> getDelaySequence(int attempts) {
    return List.generate(attempts, (i) => getDelayWithJitter(attempt: i));
  }
}
