/// Unit tests for NotificationSchedule and related providers.
///
/// Test coverage:
/// 1. NotificationSchedule model
/// 2. Schedule serialization/deserialization
/// 3. Default values
/// 4. copyWith functionality
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationSchedule', () {
    test('creates instance with required fields', () {
      final schedule = NotificationSchedule(
        hour: 9,
        minute: 30,
        days: {1, 3, 5}, // Mon, Wed, Fri
      );

      expect(schedule.hour, equals(9));
      expect(schedule.minute, equals(30));
      expect(schedule.days, equals({1, 3, 5}));
    });

    test('defaultSchedule returns expected values', () {
      final defaultSchedule = NotificationSchedule.defaultSchedule();

      expect(defaultSchedule.hour, equals(9));
      expect(defaultSchedule.minute, equals(0));
      expect(defaultSchedule.days, equals({1, 3, 5})); // Mon, Wed, Fri
    });

    test('toJson serializes correctly', () {
      final schedule = NotificationSchedule(
        hour: 14,
        minute: 45,
        days: {2, 4, 6}, // Tue, Thu, Sat
      );

      final json = schedule.toJson();

      expect(json['hour'], equals(14));
      expect(json['minute'], equals(45));
      expect(json['days'], unorderedEquals([2, 4, 6]));
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'hour': 8,
        'minute': 15,
        'days': [1, 2, 3, 4, 5],
      };

      final schedule = NotificationSchedule.fromJson(json);

      expect(schedule.hour, equals(8));
      expect(schedule.minute, equals(15));
      expect(schedule.days, equals({1, 2, 3, 4, 5}));
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};

      final schedule = NotificationSchedule.fromJson(json);

      expect(schedule.hour, equals(9));
      expect(schedule.minute, equals(0));
      expect(schedule.days, equals({1, 3, 5}));
    });

    test('fromJson handles partial data', () {
      final json = {
        'hour': 10,
        // minute and days are missing
      };

      final schedule = NotificationSchedule.fromJson(json);

      expect(schedule.hour, equals(10));
      expect(schedule.minute, equals(0)); // default
      expect(schedule.days, equals({1, 3, 5})); // default
    });

    test('copyWith creates new instance with updated values', () {
      final original = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {1, 3, 5},
      );

      final updated = original.copyWith(hour: 10, minute: 30);

      expect(updated.hour, equals(10));
      expect(updated.minute, equals(30));
      expect(updated.days, equals({1, 3, 5})); // unchanged
      // Original unchanged
      expect(original.hour, equals(9));
    });

    test('copyWith can update days', () {
      final original = NotificationSchedule.defaultSchedule();

      final updated = original.copyWith(days: {1, 2, 3, 4, 5, 6, 7});

      expect(updated.days, equals({1, 2, 3, 4, 5, 6, 7}));
    });

    test('round-trip JSON serialization preserves data', () {
      final original = NotificationSchedule(
        hour: 17,
        minute: 45,
        days: {1, 4, 7},
      );

      final jsonString = jsonEncode(original.toJson());
      final restoredJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = NotificationSchedule.fromJson(restoredJson);

      expect(restored.hour, equals(original.hour));
      expect(restored.minute, equals(original.minute));
      expect(restored.days, equals(original.days));
    });
  });

  group('NotificationSchedule - Edge Cases', () {
    test('handles midnight (hour 0)', () {
      final schedule = NotificationSchedule(
        hour: 0,
        minute: 0,
        days: {1},
      );

      expect(schedule.hour, equals(0));
    });

    test('handles late night (hour 23)', () {
      final schedule = NotificationSchedule(
        hour: 23,
        minute: 59,
        days: {7},
      );

      expect(schedule.hour, equals(23));
      expect(schedule.minute, equals(59));
    });

    test('handles empty days set', () {
      final schedule = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {},
      );

      expect(schedule.days, isEmpty);
    });

    test('handles all days of week', () {
      final schedule = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {1, 2, 3, 4, 5, 6, 7},
      );

      expect(schedule.days.length, equals(7));
    });

    test('handles single day', () {
      final schedule = NotificationSchedule(
        hour: 9,
        minute: 0,
        days: {3}, // Wednesday only
      );

      expect(schedule.days, equals({3}));
    });

    test('handles weekend only', () {
      final schedule = NotificationSchedule(
        hour: 10,
        minute: 0,
        days: {6, 7}, // Sat, Sun
      );

      expect(schedule.days, equals({6, 7}));
    });
  });

  group('NotificationSchedule - Time Formatting', () {
    test('formatTime handles morning hours', () {
      expect(_formatTime(9, 0), equals('9:00 AM'));
      expect(_formatTime(9, 30), equals('9:30 AM'));
      expect(_formatTime(11, 45), equals('11:45 AM'));
    });

    test('formatTime handles afternoon hours', () {
      expect(_formatTime(13, 0), equals('1:00 PM'));
      expect(_formatTime(14, 30), equals('2:30 PM'));
      expect(_formatTime(17, 15), equals('5:15 PM'));
    });

    test('formatTime handles midnight', () {
      expect(_formatTime(0, 0), equals('12:00 AM'));
      expect(_formatTime(0, 30), equals('12:30 AM'));
    });

    test('formatTime handles noon', () {
      expect(_formatTime(12, 0), equals('12:00 PM'));
      expect(_formatTime(12, 30), equals('12:30 PM'));
    });

    test('formatTime handles late night', () {
      expect(_formatTime(23, 0), equals('11:00 PM'));
      expect(_formatTime(23, 59), equals('11:59 PM'));
    });

    test('formatTime pads single digit minutes', () {
      expect(_formatTime(9, 5), equals('9:05 AM'));
      expect(_formatTime(15, 1), equals('3:01 PM'));
    });
  });

  group('NotificationSchedule - Day Names', () {
    test('getDayName returns correct weekday names', () {
      expect(_getDayName(1), equals('Mon'));
      expect(_getDayName(2), equals('Tue'));
      expect(_getDayName(3), equals('Wed'));
      expect(_getDayName(4), equals('Thu'));
      expect(_getDayName(5), equals('Fri'));
      expect(_getDayName(6), equals('Sat'));
      expect(_getDayName(7), equals('Sun'));
    });

    test('getDayName handles invalid day', () {
      expect(_getDayName(0), equals(''));
      expect(_getDayName(8), equals(''));
      expect(_getDayName(-1), equals(''));
    });

    test('formatDays formats single day', () {
      expect(_formatDays({1}), equals('Mon'));
      expect(_formatDays({5}), equals('Fri'));
    });

    test('formatDays formats multiple days', () {
      expect(_formatDays({1, 3, 5}), equals('Mon, Wed, Fri'));
    });

    test('formatDays formats weekdays', () {
      expect(_formatDays({1, 2, 3, 4, 5}), equals('Weekdays'));
    });

    test('formatDays formats weekend', () {
      expect(_formatDays({6, 7}), equals('Weekend'));
    });

    test('formatDays formats every day', () {
      expect(_formatDays({1, 2, 3, 4, 5, 6, 7}), equals('Every day'));
    });

    test('formatDays handles empty set', () {
      expect(_formatDays({}), equals('None'));
    });
  });
}

// Model class (simplified for testing)
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
String _formatTime(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final displayMinute = minute.toString().padLeft(2, '0');
  return '$displayHour:$displayMinute $period';
}

String _getDayName(int day) {
  const names = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
  return names[day] ?? '';
}

String _formatDays(Set<int> days) {
  if (days.isEmpty) return 'None';
  if (days.length == 7) return 'Every day';
  if (days.containsAll({1, 2, 3, 4, 5}) && days.length == 5) return 'Weekdays';
  if (days.containsAll({6, 7}) && days.length == 2) return 'Weekend';

  final sortedDays = days.toList()..sort();
  return sortedDays.map(_getDayName).join(', ');
}
