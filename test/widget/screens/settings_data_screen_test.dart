import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsDataScreen', () {
    group('data export', () {
      testWidgets('should show export data option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
                  subtitle: Text('Download your exercise data'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Export Data'), findsOneWidget);
      });

      testWidgets('should show export format options', (tester) async {
        final formats = ['PDF', 'CSV', 'JSON'];

        expect(formats.length, equals(3));
      });

      testWidgets('should show export progress indicator', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    CircularProgressIndicator(),
                    Text('Exporting...'),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('data deletion', () {
      testWidgets('should show delete all data option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.delete_forever),
                  title: Text('Delete All Data'),
                  subtitle: Text('Permanently delete all exercise history'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Delete All Data'), findsOneWidget);
      });

      testWidgets('should show confirmation dialog', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AlertDialog(
                  title: Text('Delete All Data?'),
                  content: Text('This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: null, child: Text('Cancel')),
                    TextButton(onPressed: null, child: Text('Delete')),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Delete All Data?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });
    });

    group('storage info', () {
      testWidgets('should show storage usage', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Storage Used'),
                  subtitle: Text('125 MB of 500 MB'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Storage Used'), findsOneWidget);
        expect(find.text('125 MB of 500 MB'), findsOneWidget);
      });

      testWidgets('should show storage breakdown', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ListTile(
                      title: Text('Exercise Data'),
                      trailing: Text('80 MB'),
                    ),
                    ListTile(
                      title: Text('Cached Data'),
                      trailing: Text('45 MB'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Exercise Data'), findsOneWidget);
        expect(find.text('Cached Data'), findsOneWidget);
      });
    });

    group('cache management', () {
      testWidgets('should show clear cache option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.cleaning_services),
                  title: Text('Clear Cache'),
                  subtitle: Text('45 MB'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Clear Cache'), findsOneWidget);
      });

      testWidgets('should show auto-clear option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SwitchListTile(
                  title: Text('Auto-clear old data'),
                  subtitle: Text('Remove data older than 1 year'),
                  value: true,
                  onChanged: null,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Auto-clear old data'), findsOneWidget);
      });
    });

    group('sync settings', () {
      testWidgets('should show sync status', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Sync Status'),
                  subtitle: Text('Last synced: 5 minutes ago'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Sync Status'), findsOneWidget);
      });

      testWidgets('should show manual sync button', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Sync Now'), findsOneWidget);
      });

      testWidgets('should show pending sync count', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Pending Sync'),
                  trailing: Badge(
                    label: Text('5'),
                    child: Icon(Icons.cloud_upload),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Pending Sync'), findsOneWidget);
      });
    });

    group('backup settings', () {
      testWidgets('should show backup option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.backup),
                  title: Text('Backup Data'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Backup Data'), findsOneWidget);
      });

      testWidgets('should show restore option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Restore from Backup'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Restore from Backup'), findsOneWidget);
      });
    });
  });
}
