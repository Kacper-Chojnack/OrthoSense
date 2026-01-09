import 'dart:async';
import 'dart:convert';

import 'package:orthosense/core/providers/notification_provider.dart';
import 'package:orthosense/core/providers/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_schedule_provider.g.dart';

/// Represents the notification schedule configuration.
class NotificationSchedule {
  const NotificationSchedule({
    required this.hour,
    required this.minute,
    required this.days,
  });

  factory NotificationSchedule.fromJson(Map<String, dynamic> json) {
    return NotificationSchedule(
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      days:
          (json['days'] as List<dynamic>?)?.map((e) => e as int).toSet() ??
          {1, 3, 5},
    );
  }

  factory NotificationSchedule.defaultSchedule() {
    return const NotificationSchedule(
      hour: 9,
      minute: 0,
      days: {1, 3, 5},
    );
  }

  final int hour;
  final int minute;
  final Set<int> days;

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'days': days.toList(),
    };
  }

  NotificationSchedule copyWith({
    int? hour,
    int? minute,
    Set<int>? days,
  }) {
    return NotificationSchedule(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
    );
  }
}

/// Provider for managing notification schedule settings.
@Riverpod(keepAlive: true)
class NotificationScheduleNotifier extends _$NotificationScheduleNotifier {
  static const String _scheduleKey = 'notification_schedule';

  @override
  FutureOr<NotificationSchedule> build() async {
    final prefs = ref.watch(preferencesServiceProvider);
    final jsonString = prefs.getString(_scheduleKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return NotificationSchedule.fromJson(json);
      } catch (_) {
        return NotificationSchedule.defaultSchedule();
      }
    }

    return NotificationSchedule.defaultSchedule();
  }

  Future<void> _saveSchedule(NotificationSchedule schedule) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setString(_scheduleKey, jsonEncode(schedule.toJson()));
    state = AsyncData(schedule);
    await applySchedule();
  }

  Future<void> setTime(int hour, int minute) async {
    final current = state.value ?? NotificationSchedule.defaultSchedule();
    await _saveSchedule(current.copyWith(hour: hour, minute: minute));
  }

  Future<void> setDays(Set<int> days) async {
    final current = state.value ?? NotificationSchedule.defaultSchedule();
    await _saveSchedule(current.copyWith(days: days));
  }

  Future<void> applySchedule() async {
    final prefs = ref.read(preferencesServiceProvider);
    if (!prefs.areNotificationsEnabled) return;

    final schedule = state.value ?? NotificationSchedule.defaultSchedule();
    final notificationService = ref.read(notificationServiceProvider);

    await notificationService.cancelAll();

    for (final day in schedule.days) {
      await notificationService.scheduleWeeklyReminder(
        id: 1000 + day,
        title: 'Time for Training! 💪',
        body: 'Your rehabilitation session is waiting. Stay consistent!',
        weekday: day,
        hour: schedule.hour,
        minute: schedule.minute,
      );
    }
  }
}
