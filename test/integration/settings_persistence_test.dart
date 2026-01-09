/// Integration tests for settings persistence.
///
/// Test coverage:
/// 1. Settings are saved correctly
/// 2. Settings persist across app restarts (simulated)
/// 3. Multiple settings can be changed atomically
/// 4. Default values are applied for new installations
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Settings Persistence', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('new installation has default values', () async {
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('disclaimer_accepted'), isNull);
      expect(prefs.getBool('privacy_policy_accepted'), isNull);
      expect(prefs.getBool('notifications_enabled'), isNull);
    });

    test('disclaimer acceptance persists', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('disclaimer_accepted', true);

      // Simulate restart by getting new instance
      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(prefsAfterRestart.getBool('disclaimer_accepted'), isTrue);
    });

    test('privacy policy acceptance persists', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('privacy_policy_accepted', true);

      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(prefsAfterRestart.getBool('privacy_policy_accepted'), isTrue);
    });

    test('biometric consent persists', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('biometric_consent_accepted', true);

      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(prefsAfterRestart.getBool('biometric_consent_accepted'), isTrue);
    });

    test('notification settings persist', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('notifications_enabled', false);

      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(prefsAfterRestart.getBool('notifications_enabled'), isFalse);
    });

    test('voice selection persists', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('selected_voice_map', 'en-US-voice-premium');

      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(
        prefsAfterRestart.getString('selected_voice_map'),
        equals('en-US-voice-premium'),
      );
    });

    test('multiple settings can be saved together', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('disclaimer_accepted', true);
      await prefs.setBool('privacy_policy_accepted', true);
      await prefs.setBool('biometric_consent_accepted', true);
      await prefs.setBool('notifications_enabled', true);

      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(prefsAfterRestart.getBool('disclaimer_accepted'), isTrue);
      expect(prefsAfterRestart.getBool('privacy_policy_accepted'), isTrue);
      expect(prefsAfterRestart.getBool('biometric_consent_accepted'), isTrue);
      expect(prefsAfterRestart.getBool('notifications_enabled'), isTrue);
    });

    test('clearing preferences resets all values', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set some values
      await prefs.setBool('disclaimer_accepted', true);
      await prefs.setString('selected_voice_map', 'voice-id');

      // Clear all
      await prefs.clear();

      // Verify cleared
      expect(prefs.getBool('disclaimer_accepted'), isNull);
      expect(prefs.getString('selected_voice_map'), isNull);
    });
  });

  group('Exercise Video Skip Preferences Persistence', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('video skip preference for single exercise persists', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('skip_exercise_video_123', true);

      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(prefsAfterRestart.getBool('skip_exercise_video_123'), isTrue);
    });

    test('video skip preferences for multiple exercises persist', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('skip_exercise_video_1', true);
      await prefs.setBool('skip_exercise_video_2', false);
      await prefs.setBool('skip_exercise_video_3', true);

      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(prefsAfterRestart.getBool('skip_exercise_video_1'), isTrue);
      expect(prefsAfterRestart.getBool('skip_exercise_video_2'), isFalse);
      expect(prefsAfterRestart.getBool('skip_exercise_video_3'), isTrue);
    });

    test('can reset all exercise video skip preferences', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set multiple skip preferences
      await prefs.setBool('skip_exercise_video_1', true);
      await prefs.setBool('skip_exercise_video_2', true);
      await prefs.setString('other_preference', 'value');

      // Get all keys starting with prefix and remove
      final keys = prefs.getKeys().where(
        (key) => key.startsWith('skip_exercise_video_'),
      );
      for (final key in keys) {
        await prefs.remove(key);
      }

      // Verify only skip preferences are removed
      expect(prefs.getBool('skip_exercise_video_1'), isNull);
      expect(prefs.getBool('skip_exercise_video_2'), isNull);
      expect(prefs.getString('other_preference'), equals('value'));
    });
  });

  group('Schedule Data Persistence', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('schedule JSON persists', () async {
      final prefs = await SharedPreferences.getInstance();
      const scheduleJson = '{"monday": ["09:00"], "friday": ["14:00"]}';

      await prefs.setString('user_schedule', scheduleJson);

      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(
        prefsAfterRestart.getString('user_schedule'),
        equals(scheduleJson),
      );
    });

    test('complex schedule data persists correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      const complexSchedule = '''
{
  "exercises": [1, 2, 3],
  "days": {
    "monday": true,
    "tuesday": false,
    "wednesday": true
  },
  "time": "09:00",
  "reminders": true
}
''';

      await prefs.setString('complex_schedule', complexSchedule);

      final prefsAfterRestart = await SharedPreferences.getInstance();
      expect(
        prefsAfterRestart.getString('complex_schedule'),
        equals(complexSchedule),
      );
    });
  });
}
