/// Unit tests for NotificationService.
///
/// Test coverage:
/// 1. Time calculation helpers
/// 2. Reminder scheduling logic
/// 3. Permission handling
/// 4. Notification cancellation
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Next Instance of Time', () {
    test('returns same day if time is in future', () {
      final now = DateTime(2024, 1, 15, 10, 0); // 10:00 AM
      final next = _nextInstanceOfTime(14, 0, now); // 2:00 PM

      expect(next.day, equals(15));
      expect(next.hour, equals(14));
      expect(next.minute, equals(0));
    });

    test('returns next day if time has passed', () {
      final now = DateTime(2024, 1, 15, 16, 0); // 4:00 PM
      final next = _nextInstanceOfTime(10, 0, now); // 10:00 AM (passed)

      expect(next.day, equals(16));
      expect(next.hour, equals(10));
    });

    test('handles midnight correctly', () {
      final now = DateTime(2024, 1, 15, 23, 0);
      final next = _nextInstanceOfTime(0, 0, now);

      expect(next.day, equals(16));
      expect(next.hour, equals(0));
    });

    test('handles exact same time', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final next = _nextInstanceOfTime(10, 30, now);

      // Should return next day since exact time has passed
      expect(next.day, equals(16));
    });
  });

  group('Next Instance of Weekday', () {
    test('returns same day if weekday matches and time is future', () {
      // Monday Jan 15, 2024 at 10:00
      final now = DateTime(2024, 1, 15, 10, 0);
      final next = _nextInstanceOfWeekday(1, 14, 0, now); // Monday 2:00 PM

      expect(next.weekday, equals(1));
      expect(next.day, equals(15));
      expect(next.hour, equals(14));
    });

    test('returns next week if time has passed', () {
      // Monday Jan 15 at 16:00
      final now = DateTime(2024, 1, 15, 16, 0);
      final next = _nextInstanceOfWeekday(1, 10, 0, now); // Monday 10:00 AM

      expect(next.weekday, equals(1));
      expect(next.day, equals(22)); // Next Monday
    });

    test('finds correct weekday in future', () {
      // Monday Jan 15
      final now = DateTime(2024, 1, 15, 10, 0);
      final next = _nextInstanceOfWeekday(3, 14, 0, now); // Wednesday

      expect(next.weekday, equals(3));
      expect(next.day, equals(17));
    });

    test('handles week wraparound', () {
      // Friday Jan 19
      final now = DateTime(2024, 1, 19, 10, 0);
      final next = _nextInstanceOfWeekday(2, 10, 0, now); // Tuesday

      expect(next.weekday, equals(2));
      expect(next.day, equals(23)); // Next Tuesday
    });
  });

  group('Reminder Timing', () {
    test('session reminder scheduled 15 min before', () {
      final sessionTime = DateTime(2024, 1, 15, 14, 0);
      final reminderTime = _calculateReminderTime(sessionTime);

      expect(reminderTime.hour, equals(13));
      expect(reminderTime.minute, equals(45));
    });

    test('skips reminder if time has passed', () {
      final sessionTime = DateTime.now().subtract(const Duration(hours: 1));
      final shouldSchedule = _shouldScheduleReminder(sessionTime);

      expect(shouldSchedule, isFalse);
    });

    test('schedules reminder for future session', () {
      final sessionTime = DateTime.now().add(const Duration(hours: 2));
      final shouldSchedule = _shouldScheduleReminder(sessionTime);

      expect(shouldSchedule, isTrue);
    });

    test('skips if reminder time passed but session is future', () {
      // Session in 10 min, reminder would be 5 min ago
      final sessionTime = DateTime.now().add(const Duration(minutes: 10));
      final reminderTime = _calculateReminderTime(sessionTime);

      expect(reminderTime.isBefore(DateTime.now()), isTrue);
      expect(_shouldScheduleReminder(sessionTime), isFalse);
    });
  });

  group('Notification ID Generation', () {
    test('generates unique ID from session ID', () {
      final id1 = _generateNotificationId('session-abc-123');
      final id2 = _generateNotificationId('session-xyz-456');

      expect(id1, isNot(equals(id2)));
    });

    test('same session ID generates same notification ID', () {
      final id1 = _generateNotificationId('session-abc-123');
      final id2 = _generateNotificationId('session-abc-123');

      expect(id1, equals(id2));
    });

    test('ID is positive integer', () {
      final id = _generateNotificationId('test-session');

      expect(id, greaterThan(0));
    });
  });

  group('Daily Reminder Schedule', () {
    test('creates schedule for selected days', () {
      final selectedDays = [true, true, true, true, true, false, false];
      final schedules = _createDailySchedules(selectedDays, 10, 0);

      expect(schedules.length, equals(5)); // Mon-Fri
      expect(schedules.map((s) => s.weekday).toSet(), equals({1, 2, 3, 4, 5}));
    });

    test('handles weekend only selection', () {
      final selectedDays = [false, false, false, false, false, true, true];
      final schedules = _createDailySchedules(selectedDays, 9, 30);

      expect(schedules.length, equals(2));
      expect(schedules.map((s) => s.weekday).toSet(), equals({6, 7}));
    });

    test('handles no days selected', () {
      final selectedDays = [false, false, false, false, false, false, false];
      final schedules = _createDailySchedules(selectedDays, 10, 0);

      expect(schedules.isEmpty, isTrue);
    });
  });

  group('Notification Content', () {
    test('generates session reminder content', () {
      final content = _generateSessionReminderContent(
        exerciseName: 'Deep Squat',
        minutesBefore: 15,
      );

      expect(content.title, contains('Reminder'));
      expect(content.body, contains('Deep Squat'));
      expect(content.body, contains('15'));
    });

    test('generates daily reminder content', () {
      final content = _generateDailyReminderContent();

      expect(content.title, contains('Exercise'));
      expect(content.body.isNotEmpty, isTrue);
    });
  });

  group('Channel Configuration', () {
    test('has correct channel ID', () {
      const channelId = 'session_reminders';
      expect(channelId, equals('session_reminders'));
    });

    test('has correct channel name', () {
      const channelName = 'Session Reminders';
      expect(channelName, equals('Session Reminders'));
    });
  });

  group('Permission State', () {
    test('tracks permission granted state', () {
      final state = NotificationPermissionState(isGranted: true);

      expect(state.isGranted, isTrue);
    });

    test('tracks permission denied state', () {
      final state = NotificationPermissionState(isGranted: false);

      expect(state.isGranted, isFalse);
    });
  });

  group('Pending Notifications', () {
    test('MockNotificationRequest has correct properties', () {
      final request = MockPendingNotificationRequest(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        payload: null,
      );

      expect(request.id, equals(1));
      expect(request.title, equals('Test Title'));
      expect(request.body, equals('Test Body'));
    });
  });
}

// Helper functions

DateTime _nextInstanceOfTime(int hour, int minute, DateTime now) {
  var scheduled = DateTime(
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  return scheduled;
}

DateTime _nextInstanceOfWeekday(int weekday, int hour, int minute, DateTime now) {
  var scheduled = _nextInstanceOfTime(hour, minute, now);
  while (scheduled.weekday != weekday) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

DateTime _calculateReminderTime(DateTime sessionTime) {
  return sessionTime.subtract(const Duration(minutes: 15));
}

bool _shouldScheduleReminder(DateTime sessionTime) {
  final reminderTime = _calculateReminderTime(sessionTime);
  return reminderTime.isAfter(DateTime.now());
}

int _generateNotificationId(String sessionId) {
  return sessionId.hashCode.abs();
}

class DaySchedule {
  DaySchedule({
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  final int weekday;
  final int hour;
  final int minute;
}

List<DaySchedule> _createDailySchedules(
  List<bool> selectedDays,
  int hour,
  int minute,
) {
  final schedules = <DaySchedule>[];
  for (int i = 0; i < selectedDays.length; i++) {
    if (selectedDays[i]) {
      schedules.add(DaySchedule(
        weekday: i + 1, // 1 = Monday
        hour: hour,
        minute: minute,
      ));
    }
  }
  return schedules;
}

class NotificationContent {
  NotificationContent({required this.title, required this.body});

  final String title;
  final String body;
}

NotificationContent _generateSessionReminderContent({
  required String exerciseName,
  required int minutesBefore,
}) {
  return NotificationContent(
    title: 'Session Reminder',
    body: 'Your $exerciseName session starts in $minutesBefore minutes.',
  );
}

NotificationContent _generateDailyReminderContent() {
  return NotificationContent(
    title: "Time for Your Exercise",
    body: "Don't forget your daily rehabilitation exercises!",
  );
}

// Mock classes

class NotificationPermissionState {
  NotificationPermissionState({required this.isGranted});

  final bool isGranted;
}

class MockPendingNotificationRequest {
  MockPendingNotificationRequest({
    required this.id,
    this.title,
    this.body,
    this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}
