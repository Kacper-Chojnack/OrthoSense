import 'package:orthosense/core/services/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_provider.g.dart';

/// Provides a singleton instance of [NotificationService].
///
/// keepAlive ensures the service persists across the app lifecycle.
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService();
}
