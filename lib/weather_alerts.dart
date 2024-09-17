import 'package:shared_preferences/shared_preferences.dart';

class WeatherAlertPreferences {
  static const String _key = 'weather_alert_preferences';

  static Future<List<String>> getAlertPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> saveAlertPreference(String weatherType) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPreferences = await getAlertPreferences();
    if (!currentPreferences.contains(weatherType)) {
      currentPreferences.add(weatherType);
      await prefs.setStringList(_key, currentPreferences);
    }
  }

  static Future<void> removeAlertPreference(String weatherType) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPreferences = await getAlertPreferences();
    currentPreferences.remove(weatherType);
    await prefs.setStringList(_key, currentPreferences);
  }
}