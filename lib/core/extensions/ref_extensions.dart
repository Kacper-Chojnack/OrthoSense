import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Grace period extension to prevent premature state disposal.
extension CacheForExtension on Ref {
  /// Keeps provider alive for [duration] after last listener disposes.
  /// Solves the autoDispose + tab switching problem.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
