import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService(this._prefs);

  static const String keyDisclaimerAccepted = 'disclaimer_accepted';
  static const String keyPrivacyPolicyAccepted = 'privacy_policy_accepted';
  static const String keyBiometricConsentAccepted =
      'biometric_consent_accepted';
  static const String keyVoiceSelected = 'voice_selected';
  static const String keySelectedVoiceMap = 'selected_voice_map';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keySkipExerciseVideoPrefix = 'skip_exercise_video_';

  final SharedPreferences _prefs;

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // Disclaimer
  bool get isDisclaimerAccepted =>
      _prefs.getBool(keyDisclaimerAccepted) ?? false;
  Future<void> setDisclaimerAccepted({required bool value}) =>
      _prefs.setBool(keyDisclaimerAccepted, value);

  // Privacy Policy (GDPR)
  bool get isPrivacyPolicyAccepted =>
      _prefs.getBool(keyPrivacyPolicyAccepted) ?? false;
  Future<void> setPrivacyPolicyAccepted({required bool value}) =>
      _prefs.setBool(keyPrivacyPolicyAccepted, value);

  // Biometric Consent (Camera/Pose)
  bool get isBiometricConsentAccepted =>
      _prefs.getBool(keyBiometricConsentAccepted) ?? false;
  Future<void> setBiometricConsentAccepted({required bool value}) =>
      _prefs.setBool(keyBiometricConsentAccepted, value);

  // Voice Selection
  bool get isVoiceSelected => _prefs.getBool(keyVoiceSelected) ?? false;
  Future<void> setVoiceSelected({required bool value}) =>
      _prefs.setBool(keyVoiceSelected, value);

  String? get selectedVoiceKey => _prefs.getString(keySelectedVoiceMap);
  Future<void> setSelectedVoiceKey(String value) =>
      _prefs.setString(keySelectedVoiceMap, value);

  // Notifications
  bool get areNotificationsEnabled =>
      _prefs.getBool(keyNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled({required bool value}) =>
      _prefs.setBool(keyNotificationsEnabled, value);

  // Exercise Video Demo Skip Preferences
  // Returns true if user chose to skip demo video for this exercise
  bool shouldSkipExerciseVideo(int exerciseId) =>
      _prefs.getBool('$keySkipExerciseVideoPrefix$exerciseId') ?? false;

  Future<void> setSkipExerciseVideo({
    required int exerciseId,
    required bool skip,
  }) => _prefs.setBool('$keySkipExerciseVideoPrefix$exerciseId', skip);

  // Reset all exercise video skip preferences
  Future<void> resetAllExerciseVideoPreferences() async {
    final keys = _prefs.getKeys().where(
      (key) => key.startsWith(keySkipExerciseVideoPrefix),
    );
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Clears all preferences (for account deletion or reset).
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
