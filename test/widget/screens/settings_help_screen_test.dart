import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('SettingsHelpScreen', () {
    group('help sections', () {
      testWidgets('should show FAQ section', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('FAQ'),
                  subtitle: Text('Frequently asked questions'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('FAQ'), findsOneWidget);
      });

      testWidgets('should show user guide section', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.book),
                  title: Text('User Guide'),
                  subtitle: Text('Learn how to use OrthoSense'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('User Guide'), findsOneWidget);
      });

      testWidgets('should show video tutorials section', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.play_circle_outline),
                  title: Text('Video Tutorials'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Video Tutorials'), findsOneWidget);
      });
    });

    group('support options', () {
      testWidgets('should show contact support option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Contact Support'),
                  subtitle: Text('support@orthosense.com'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Contact Support'), findsOneWidget);
      });

      testWidgets('should show feedback option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.feedback),
                  title: Text('Send Feedback'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Send Feedback'), findsOneWidget);
      });

      testWidgets('should show report bug option', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Report a Bug'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Report a Bug'), findsOneWidget);
      });
    });

    group('app info', () {
      testWidgets('should show app version', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Version'),
                  subtitle: Text('1.0.0 (build 42)'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Version'), findsOneWidget);
      });

      testWidgets('should show privacy policy link', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.privacy_tip),
                  title: Text('Privacy Policy'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Privacy Policy'), findsOneWidget);
      });

      testWidgets('should show terms of service link', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('Terms of Service'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Terms of Service'), findsOneWidget);
      });

      testWidgets('should show licenses link', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  leading: Icon(Icons.article),
                  title: Text('Open Source Licenses'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Open Source Licenses'), findsOneWidget);
      });
    });

    group('exercise guides', () {
      testWidgets('should show squat guide', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Squat Guide'),
                  subtitle: Text('Learn proper squat form'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Squat Guide'), findsOneWidget);
      });

      testWidgets('should show hurdle step guide', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Hurdle Step Guide'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Hurdle Step Guide'), findsOneWidget);
      });

      testWidgets('should show shoulder abduction guide', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Shoulder Abduction Guide'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Shoulder Abduction Guide'), findsOneWidget);
      });
    });

    group('troubleshooting', () {
      testWidgets('should show camera troubleshooting', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Camera Issues'),
                  subtitle: Text('Troubleshoot camera problems'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Camera Issues'), findsOneWidget);
      });

      testWidgets('should show sync troubleshooting', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListTile(
                  title: Text('Sync Issues'),
                  subtitle: Text('Fix data synchronization problems'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Sync Issues'), findsOneWidget);
      });
    });
  });
}
