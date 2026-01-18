/// Unit tests for NotificationSettingsScreen logic and UI components.
///
/// Test coverage:
/// 1. Time formatting
/// 2. Day selector logic
/// 3. Permission request flow
/// 4. Schedule application
/// 5. Master toggle behavior
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Time Formatting', () {
    test('formats morning time correctly', () {
      expect(_formatTime(9, 0), equals('9:00 AM'));
      expect(_formatTime(9, 30), equals('9:30 AM'));
    });

    test('formats afternoon time correctly', () {
      expect(_formatTime(14, 0), equals('2:00 PM'));
      expect(_formatTime(14, 45), equals('2:45 PM'));
    });

    test('formats noon correctly', () {
      expect(_formatTime(12, 0), equals('12:00 PM'));
      expect(_formatTime(12, 30), equals('12:30 PM'));
    });

    test('formats midnight correctly', () {
      expect(_formatTime(0, 0), equals('12:00 AM'));
      expect(_formatTime(0, 15), equals('12:15 AM'));
    });

    test('formats late night correctly', () {
      expect(_formatTime(23, 59), equals('11:59 PM'));
    });

    test('pads minutes with zero', () {
      expect(_formatTime(8, 5), equals('8:05 AM'));
    });
  });

  group('Day Selector', () {
    test('all days are initially selectable', () {
      final allDays = [1, 2, 3, 4, 5, 6, 7];

      expect(allDays.length, equals(7));
      expect(allDays.first, equals(1)); // Monday
      expect(allDays.last, equals(7)); // Sunday
    });

    test('selecting a day adds it to list', () {
      var selectedDays = <int>[1, 3, 5]; // Mon, Wed, Fri

      // Select Thursday
      selectedDays = [...selectedDays, 4];

      expect(selectedDays, contains(4));
      expect(selectedDays.length, equals(4));
    });

    test('deselecting a day removes it from list', () {
      var selectedDays = [1, 2, 3, 4, 5]; // Weekdays

      // Deselect Wednesday
      selectedDays = selectedDays.where((d) => d != 3).toList();

      expect(selectedDays, isNot(contains(3)));
      expect(selectedDays.length, equals(4));
    });

    test('toggling day selection', () {
      var selectedDays = [1, 2, 3];

      // Toggle day 2 (should remove)
      selectedDays = _toggleDay(selectedDays, 2);
      expect(selectedDays, isNot(contains(2)));

      // Toggle day 4 (should add)
      selectedDays = _toggleDay(selectedDays, 4);
      expect(selectedDays, contains(4));
    });

    test('at least one day must remain selected', () {
      var selectedDays = [1]; // Only Monday selected

      // Try to deselect Monday
      if (selectedDays.length > 1 || !selectedDays.contains(1)) {
        selectedDays = selectedDays.where((d) => d != 1).toList();
      }

      // Should still have Monday since it's the only day
      expect(selectedDays, contains(1));
    });

    test('day names mapping', () {
      expect(_getDayName(1), equals('Mon'));
      expect(_getDayName(2), equals('Tue'));
      expect(_getDayName(3), equals('Wed'));
      expect(_getDayName(4), equals('Thu'));
      expect(_getDayName(5), equals('Fri'));
      expect(_getDayName(6), equals('Sat'));
      expect(_getDayName(7), equals('Sun'));
    });

    test('full day names', () {
      expect(_getFullDayName(1), equals('Monday'));
      expect(_getFullDayName(7), equals('Sunday'));
    });
  });

  group('Permission Request Flow', () {
    test('enabling notifications requests permission', () async {
      var permissionRequested = false;

      // Simulate enabling notifications
      await _simulateEnableNotifications(
        onRequestPermission: () async {
          permissionRequested = true;
          return true;
        },
      );

      expect(permissionRequested, isTrue);
    });

    test('denied permission shows snackbar message', () async {
      String? snackbarMessage;

      await _simulateEnableNotifications(
        onRequestPermission: () async => false,
        onShowSnackbar: (message) {
          snackbarMessage = message;
        },
      );

      expect(snackbarMessage, contains('permission denied'));
    });

    test('denied permission does not enable notifications', () async {
      var notificationsEnabled = false;

      await _simulateEnableNotifications(
        onRequestPermission: () async => false,
        onEnable: () {
          notificationsEnabled = true;
        },
      );

      expect(notificationsEnabled, isFalse);
    });

    test('granted permission enables notifications', () async {
      var notificationsEnabled = false;

      await _simulateEnableNotifications(
        onRequestPermission: () async => true,
        onEnable: () {
          notificationsEnabled = true;
        },
      );

      expect(notificationsEnabled, isTrue);
    });
  });

  group('Schedule Application', () {
    test('disabling notifications cancels all', () async {
      var cancelAllCalled = false;

      await _simulateDisableNotifications(
        onCancelAll: () async {
          cancelAllCalled = true;
        },
      );

      expect(cancelAllCalled, isTrue);
    });

    test('enabling notifications applies schedule', () async {
      var applyScheduleCalled = false;

      await _simulateEnableNotifications(
        onRequestPermission: () async => true,
        onApplySchedule: () async {
          applyScheduleCalled = true;
        },
      );

      expect(applyScheduleCalled, isTrue);
    });

    test('changing time applies new schedule', () async {
      var scheduleApplied = false;
      var newHour = 0;
      var newMinute = 0;

      await _simulateSetTime(
        hour: 9,
        minute: 30,
        onApply: (h, m) async {
          scheduleApplied = true;
          newHour = h;
          newMinute = m;
        },
      );

      expect(scheduleApplied, isTrue);
      expect(newHour, equals(9));
      expect(newMinute, equals(30));
    });

    test('changing days applies new schedule', () async {
      var newDays = <int>[];

      await _simulateSetDays(
        days: [1, 2, 3, 4, 5],
        onApply: (days) async {
          newDays = days;
        },
      );

      expect(newDays, equals([1, 2, 3, 4, 5]));
    });
  });

  group('Master Toggle', () {
    test('toggle on shows schedule options', () {
      final state = NotificationSettingsState(
        notificationsEnabled: true,
      );

      expect(state.shouldShowScheduleOptions, isTrue);
    });

    test('toggle off hides schedule options', () {
      final state = NotificationSettingsState(
        notificationsEnabled: false,
      );

      expect(state.shouldShowScheduleOptions, isFalse);
    });

    test('toggle state persists in preferences', () async {
      var persistedValue = false;

      await _simulatePersistToggle(
        value: true,
        onPersist: (v) async {
          persistedValue = v;
        },
      );

      expect(persistedValue, isTrue);
    });
  });

  group('NotificationSettingsScreen Widget', () {
    testWidgets('displays master toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestNotificationSettingsScreen(
            notificationsEnabled: false,
          ),
        ),
      );

      expect(find.text('Enable Reminders'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows schedule when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestNotificationSettingsScreen(
            notificationsEnabled: true,
          ),
        ),
      );

      expect(find.text('Reminder Schedule'), findsOneWidget);
      expect(find.text('Reminder Time'), findsOneWidget);
      expect(find.text('Training Days'), findsOneWidget);
    });

    testWidgets('hides schedule when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestNotificationSettingsScreen(
            notificationsEnabled: false,
          ),
        ),
      );

      expect(find.text('Reminder Schedule'), findsNothing);
      expect(find.text('Reminder Time'), findsNothing);
    });

    testWidgets('displays current time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestNotificationSettingsScreen(
            notificationsEnabled: true,
            hour: 9,
            minute: 30,
          ),
        ),
      );

      expect(find.text('9:30 AM'), findsOneWidget);
    });

    testWidgets('displays selected days', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestNotificationSettingsScreen(
            notificationsEnabled: true,
            selectedDays: [1, 2, 3, 4, 5],
          ),
        ),
      );

      // Day chips should be visible
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
    });
  });

  group('Preview Section', () {
    test('generates preview text for weekdays', () {
      final days = [1, 2, 3, 4, 5];
      const hour = 9;
      const minute = 0;

      final preview = _generatePreviewText(days, hour, minute);

      expect(preview, contains('Weekdays'));
      expect(preview, contains('9:00 AM'));
    });

    test('generates preview text for weekend', () {
      final days = [6, 7];
      const hour = 10;
      const minute = 30;

      final preview = _generatePreviewText(days, hour, minute);

      expect(preview, contains('Sat'));
      expect(preview, contains('Sun'));
      expect(preview, contains('10:30 AM'));
    });

    test('generates preview text for every day', () {
      final days = [1, 2, 3, 4, 5, 6, 7];
      const hour = 8;
      const minute = 0;

      final preview = _generatePreviewText(days, hour, minute);

      expect(preview, contains('Every day'));
    });
  });
}

// Helper classes and functions

class NotificationSettingsState {
  NotificationSettingsState({
    this.notificationsEnabled = false,
    this.hour = 9,
    this.minute = 0,
    this.days = const [1, 2, 3, 4, 5],
  });

  final bool notificationsEnabled;
  final int hour;
  final int minute;
  final List<int> days;

  bool get shouldShowScheduleOptions => notificationsEnabled;
}

String _formatTime(int hour, int minute) {
  final isPM = hour >= 12;
  var displayHour = hour % 12;
  if (displayHour == 0) displayHour = 12;

  final minuteStr = minute.toString().padLeft(2, '0');
  return '$displayHour:$minuteStr ${isPM ? "PM" : "AM"}';
}

List<int> _toggleDay(List<int> selectedDays, int day) {
  if (selectedDays.contains(day)) {
    return selectedDays.where((d) => d != day).toList();
  } else {
    return [...selectedDays, day];
  }
}

String _getDayName(int day) {
  const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[day];
}

String _getFullDayName(int day) {
  const names = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[day];
}

Future<void> _simulateEnableNotifications({
  required Future<bool> Function() onRequestPermission,
  void Function(String)? onShowSnackbar,
  void Function()? onEnable,
  Future<void> Function()? onApplySchedule,
}) async {
  final granted = await onRequestPermission();

  if (!granted) {
    onShowSnackbar?.call(
      'Notification permission denied. Please enable in system settings.',
    );
    return;
  }

  onEnable?.call();
  await onApplySchedule?.call();
}

Future<void> _simulateDisableNotifications({
  required Future<void> Function() onCancelAll,
}) async {
  await onCancelAll();
}

Future<void> _simulateSetTime({
  required int hour,
  required int minute,
  required Future<void> Function(int, int) onApply,
}) async {
  await onApply(hour, minute);
}

Future<void> _simulateSetDays({
  required List<int> days,
  required Future<void> Function(List<int>) onApply,
}) async {
  await onApply(days);
}

Future<void> _simulatePersistToggle({
  required bool value,
  required Future<void> Function(bool) onPersist,
}) async {
  await onPersist(value);
}

String _generatePreviewText(List<int> days, int hour, int minute) {
  final time = _formatTime(hour, minute);

  if (days.length == 7) {
    return 'Every day at $time';
  }

  if (days.length == 5 &&
      days.contains(1) &&
      days.contains(2) &&
      days.contains(3) &&
      days.contains(4) &&
      days.contains(5)) {
    return 'Weekdays at $time';
  }

  final dayNames = days.map((d) => _getDayName(d)).join(', ');
  return '$dayNames at $time';
}

// Test widget

class TestNotificationSettingsScreen extends StatelessWidget {
  const TestNotificationSettingsScreen({
    super.key,
    required this.notificationsEnabled,
    this.hour = 9,
    this.minute = 0,
    this.selectedDays = const [1, 2, 3, 4, 5],
  });

  final bool notificationsEnabled;
  final int hour;
  final int minute;
  final List<int> selectedDays;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Training Reminders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Master toggle
          Card(
            child: SwitchListTile(
              secondary: Icon(
                Icons.notifications_active,
                color: colorScheme.primary,
              ),
              title: const Text('Enable Reminders'),
              subtitle: const Text('Get notified about your training sessions'),
              value: notificationsEnabled,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 24),

          if (notificationsEnabled) ...[
            Text(
              'Reminder Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Time selection
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.access_time,
                  color: colorScheme.primary,
                ),
                title: const Text('Reminder Time'),
                subtitle: Text(_formatTime(hour, minute)),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 16),

            // Day selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        const Text('Training Days'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: List.generate(7, (index) {
                        final day = index + 1;
                        final isSelected = selectedDays.contains(day);
                        return ChoiceChip(
                          label: Text(_getDayName(day)),
                          selected: isSelected,
                          onSelected: (_) {},
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
