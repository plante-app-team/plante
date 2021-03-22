import 'package:shared_preferences/shared_preferences.dart';

extension SharedPreferencesExtensions on SharedPreferences {
  Future<bool> safeRemove(String key) async {
    if (containsKey(key)) {
      return await remove(key);
    }
    return false;
  }
}
