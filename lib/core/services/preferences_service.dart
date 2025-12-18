import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String keyDisclaimerAccepted = 'disclaimer_accepted';
  static const String keyVoiceSelected = 'voice_selected';
  static const String keySelectedVoiceMap = 'selected_voice_map'; // Storing map as JSON string if needed, or just ID

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  bool get isDisclaimerAccepted => _prefs.getBool(keyDisclaimerAccepted) ?? false;
  Future<void> setDisclaimerAccepted(bool value) => _prefs.setBool(keyDisclaimerAccepted, value);

  bool get isVoiceSelected => _prefs.getBool(keyVoiceSelected) ?? false;
  Future<void> setVoiceSelected(bool value) => _prefs.setBool(keyVoiceSelected, value);

  String? get selectedVoiceKey => _prefs.getString(keySelectedVoiceMap);
  Future<void> setSelectedVoiceKey(String value) => _prefs.setString(keySelectedVoiceMap, value);
}
