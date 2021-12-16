import 'package:shared_preferences/shared_preferences.dart';

const _NEWEST_FEATURES = 'FAKE_NEWEST_FEATURES';

class Settings {
  Future<bool> enableNewestFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_NEWEST_FEATURES) ?? false;
  }

  Future<void> setEnableNewestFeatures(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_NEWEST_FEATURES, value);
  }
}
