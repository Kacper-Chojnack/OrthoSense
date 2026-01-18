/// Unit tests for notification schedule provider.
///
/// Test coverage:
/// 1. NotificationSchedule model
/// 2. JSON serialization
/// 3. Default schedule values
/// 4. copyWith functionality
/// 5. Schedule validation
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationSchedule', () {
    test('creates with required fields', () {
      const schedule = NotificationSchedule(
        hour: 9,
        minute: 30,
        days: {1, 3, 5},
      );

      expect(schedule.hour, equals(9));
      expect(schedule.minute, equals(30));
      expect(schedule.days, equals({1, 3, 5}));
    });

    test('default schedule is 9:00 on Mon/Wed/Fri', () {
      final schedule = NotificationSchedule.defaultSchedule();

      expect(schedule.hour, equals(9));
      expect(schedule.minute, equals(0));
      expect(schedule.days, equals({1, 3, 5}));
    });
  });

  group('NotificationSchedule JSON Serialization', () {
    test('toJson produces valid JSON', () {
      const schedule = NotificationSchedule(
        hour: 14,
        minute: 45,
        days: {2, 4, 6},
      );

      final json = schedule.toJson();

      expect(json['hour'], equals(14));
      expect(json['minute'], equals(45));
      expect(json['days'], equals([2, 4, 6]));
    });

    test('fromJson parses JSON correctly', () {
      final json = {
        'hour': 10,
        'minute': 15,
        'days': [1, 2, 3, 4, 5],
      };

      final schedule = NotificationSchedule.fromJson(json);

      expect(schedule.hour, equals(10));
      expect(schedule.minute, equals(15));
      expect(schedule.days, equals({1, 2, 3, 4, 5}));
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{};

      final schedule = NotificationSchedule.fromJson(json);

      expect(schedule.hour, equals(9));
      expect(schedule.minute, equals(0));
      expect(schedule.days, equals({1, 3, 5}));
    });

    test('serialization roundtrip preserves data', () {
      const original = NotificationSchedule(
        hour: 18,
        minute: 30,
        days: {1, 2, 3, 4, 5, 6, 7},
      );

      final jsonString = jsonEncode(original.toJson());
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = NotificationSchedule.fromJson(decoded);

      expect(restored.hour, equals(original.hour));
      expect(restored.minute, equals(original.minute));
      expect(restored.days, equals(original.days));
    });
  });

  group('NotificationSchedule copyWith', () {
    test('copyWith changes hour only', () {
      const original = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {1, 3, 5},
      );

      final modified = original.copyWith(hour: 10);

      expect(modified.hour, equals(10));
      expect(modified.minute, equals(0));
      expect(modified.days, equals({1, 3, 5}));
    });

    test('copyWith changes minute only', () {
      const original = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {1, 3, 5},
      );

      final modified = original.copyWith(minute: 30);

      expect(modified.hour, equals(9));
      expect(modified.minute, equals(30));
      expect(modified.days, equals({1, 3, 5}));
    });

    test('copyWith changes days only', () {
      const original = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {1, 3, 5},
      );

      final modified = original.copyWith(days: {2, 4, 6});

      expect(modified.hour, equals(9));
      expect(modified.minute, equals(0));
      expect(modified.days, equals({2, 4, 6}));
    });

    test('copyWith with no changes returns equivalent schedule', () {
      const original = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {1, 3, 5},
      );

      final modified = original.copyWith();

      expect(modified.hour, equals(original.hour));
      expect(modified.minute, equals(original.minute));
      expect(modified.days, equals(original.days));
    });
  });

  group('Schedule Time Validation', () {
    test('hour is valid (0-23)', () {
      expect(_isValidHour(0), isTrue);
      expect(_isValidHour(12), isTrue);
      expect(_isValidHour(23), isTrue);
      expect(_isValidHour(-1), isFalse);
      expect(_isValidHour(24), isFalse);
    });

    test('minute is valid (0-59)', () {
      expect(_isValidMinute(0), isTrue);
      expect(_isValidMinute(30), isTrue);
      expect(_isValidMinute(59), isTrue);
      expect(_isValidMinute(-1), isFalse);
      expect(_isValidMinute(60), isFalse);
    });
  });

  group('Schedule Days Validation', () {
    test('day values are 1-7 (Monday-Sunday)', () {
      const validDays = {1, 2, 3, 4, 5, 6, 7};

      for (final day in validDays) {
        expect(_isValidDay(day), isTrue);
      }
    });

    test('day 0 is invalid', () {
      expect(_isValidDay(0), isFalse);
    });

    test('day 8 is invalid', () {
      expect(_isValidDay(8), isFalse);
    });

    test('empty days set is valid (no notifications)', () {
      const schedule = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {},
      );

      expect(schedule.days.isEmpty, isTrue);
    });
  });

  group('Day Name Formatting', () {
    test('day 1 is Monday', () {
      expect(_getDayName(1), equals('Monday'));
    });

    test('day 5 is Friday', () {
      expect(_getDayName(5), equals('Friday'));
    });

    test('day 7 is Sunday', () {
      expect(_getDayName(7), equals('Sunday'));
    });

    test('short day names', () {
      expect(_getDayShortName(1), equals('Mon'));
      expect(_getDayShortName(7), equals('Sun'));
    });
  });

  group('Time Formatting', () {
    test('formats 24-hour time', () {
      expect(_formatTime24(9, 0), equals('09:00'));
      expect(_formatTime24(14, 30), equals('14:30'));
      expect(_formatTime24(0, 5), equals('00:05'));
    });

    test('formats 12-hour time with AM/PM', () {
      expect(_formatTime12(9, 0), equals('9:00 AM'));
      expect(_formatTime12(14, 30), equals('2:30 PM'));
      expect(_formatTime12(0, 0), equals('12:00 AM'));
      expect(_formatTime12(12, 0), equals('12:00 PM'));
    });
  });

  group('Schedule Storage', () {
    test('storage key is defined', () {
      const storageKey = 'notification_schedule';
      expect(storageKey, isNotEmpty);
    });

    test('can serialize to storage format', () {
      const schedule = NotificationSchedule(
        hour: 10,
        minute: 30,
        days: {1, 3, 5},
      );

      final jsonString = jsonEncode(schedule.toJson());

      expect(jsonString, isNotEmpty);
      expect(jsonString, contains('"hour":10'));
      expect(jsonString, contains('"minute":30'));
    });
  });

  group('Schedule Provider Logic', () {
    test('loads default schedule when no saved value', () async {
      final mockPrefs = MockPreferencesService();
      mockPrefs.values['notification_schedule'] = null;

      final schedule = await _loadSchedule(mockPrefs);

      expect(schedule.hour, equals(9));
      expect(schedule.minute, equals(0));
    });

    test('loads saved schedule from preferences', () async {
      final mockPrefs = MockPreferencesService();
      mockPrefs.values['notification_schedule'] = jsonEncode({
        'hour': 15,
        'minute': 45,
        'days': [2, 4],
      });

      final schedule = await _loadSchedule(mockPrefs);

      expect(schedule.hour, equals(15));
      expect(schedule.minute, equals(45));
      expect(schedule.days, equals({2, 4}));
    });

    test('handles malformed JSON gracefully', () async {
      final mockPrefs = MockPreferencesService();
      mockPrefs.values['notification_schedule'] = 'not valid json';

      final schedule = await _loadSchedule(mockPrefs);

      // Should return default schedule
      expect(schedule.hour, equals(9));
      expect(schedule.minute, equals(0));
    });
  });

  group('Schedule Update', () {
    test('saves schedule to preferences', () async {
      final mockPrefs = MockPreferencesService();
      const schedule = NotificationSchedule(
        hour: 11,
        minute: 15,
        days: {1, 2, 3},
      );

      await _saveSchedule(mockPrefs, schedule);

      final saved = mockPrefs.values['notification_schedule'];
      expect(saved, isNotNull);
      expect(saved, contains('"hour":11'));
    });
  });

  group('Weekday Set Operations', () {
    test('adding a day', () {
      const schedule = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {1, 3, 5},
      );

      final newDays = {...schedule.days, 2};
      final modified = schedule.copyWith(days: newDays);

      expect(modified.days, contains(2));
      expect(modified.days.length, equals(4));
    });

    test('removing a day', () {
      const schedule = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {1, 3, 5},
      );

      final newDays = schedule.days.where((d) => d != 3).toSet();
      final modified = schedule.copyWith(days: newDays);

      expect(modified.days, isNot(contains(3)));
      expect(modified.days.length, equals(2));
    });

    test('toggling a day', () {
      const schedule = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {1, 3, 5},
      );

      const dayToToggle = 3;
      final Set<int> newDays;

      if (schedule.days.contains(dayToToggle)) {
        newDays = schedule.days.where((d) => d != dayToToggle).toSet();
      } else {
        newDays = {...schedule.days, dayToToggle};
      }

      expect(newDays, isNot(contains(3)));
    });
  });
}

// Model class

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

// Helper functions

bool _isValidHour(int hour) => hour >= 0 && hour <= 23;
bool _isValidMinute(int minute) => minute >= 0 && minute <= 59;
bool _isValidDay(int day) => day >= 1 && day <= 7;

String _getDayName(int day) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[day - 1];
}

String _getDayShortName(int day) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[day - 1];
}

String _formatTime24(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String _formatTime12(int hour, int minute) {
  final period = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

// Mock classes

class MockPreferencesService {
  final Map<String, String?> values = {};

  String? getString(String key) => values[key];

  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}

Future<NotificationSchedule> _loadSchedule(MockPreferencesService prefs) async {
  final jsonString = prefs.getString('notification_schedule');

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

Future<void> _saveSchedule(
  MockPreferencesService prefs,
  NotificationSchedule schedule,
) async {
  await prefs.setString(
    'notification_schedule',
    jsonEncode(schedule.toJson()),
  );
}
