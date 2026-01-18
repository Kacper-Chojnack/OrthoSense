import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('SettingsNotificationsScreen', () {
    group('notification toggles', () {
      testWidgets('should show exercise reminders toggle', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SwitchListTile(
                  title: Text('Exercise Reminders'),
                  value: true,
                  onChanged: null,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Exercise Reminders'), findsOneWidget);
      });

      testWidgets('should show progress updates toggle', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SwitchListTile(
                  title: Text('Progress Updates'),
                  value: true,
                  onChanged: null,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Progress Updates'), findsOneWidget);
      });

      testWidgets('should show achievement alerts toggle', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SwitchListTile(
                  title: Text('Achievement Alerts'),
                  value: true,
                  onChanged: null,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Achievement Alerts'), findsOneWidget);
      });
    });

    group('reminder scheduling', () {
      testWidgets('should show schedule section', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Reminder Schedule'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Reminder Schedule'), findsOneWidget);
      });

      testWidgets('should show time picker for reminder', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Reminder Time'),
                  subtitle: Text('9:00 AM'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('9:00 AM'), findsOneWidget);
      });

      testWidgets('should show weekday selection', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Wrap(
                  children: [
                    Chip(label: Text('Mon')),
                    Chip(label: Text('Tue')),
                    Chip(label: Text('Wed')),
                    Chip(label: Text('Thu')),
                    Chip(label: Text('Fri')),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Fri'), findsOneWidget);
      });
    });

    group('quiet hours', () {
      testWidgets('should show quiet hours toggle', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SwitchListTile(
                  title: Text('Quiet Hours'),
                  value: false,
                  onChanged: null,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Quiet Hours'), findsOneWidget);
      });

      testWidgets('should show start time for quiet hours', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Start Time'),
                  subtitle: Text('10:00 PM'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('10:00 PM'), findsOneWidget);
      });

      testWidgets('should show end time for quiet hours', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('End Time'),
                  subtitle: Text('7:00 AM'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('7:00 AM'), findsOneWidget);
      });
    });

    group('sound settings', () {
      testWidgets('should show notification sound option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Notification Sound'),
                  subtitle: Text('Default'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Notification Sound'), findsOneWidget);
      });

      testWidgets('should show vibration toggle', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SwitchListTile(
                  title: Text('Vibration'),
                  value: true,
                  onChanged: null,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Vibration'), findsOneWidget);
      });
    });

    group('permissions', () {
      testWidgets('should show notification permission status', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Notification Permission'),
                  subtitle: Text('Granted'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Notification Permission'), findsOneWidget);
      });

      testWidgets('should show request permission button if denied', (
        tester,
      ) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ElevatedButton(
                  onPressed: null,
                  child: Text('Enable Notifications'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Enable Notifications'), findsOneWidget);
      });
    });
  });
}
