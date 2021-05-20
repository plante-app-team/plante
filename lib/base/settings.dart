import 'package:shared_preferences/shared_preferences.dart';

const _FAKE_OFF_API = 'FAKE_OFF_API';
const _FAKE_OFF_API_PRODUCT_NOT_FOUND = 'FAKE_OFF_API_PRODUCT_NOT_FOUND';

class Settings {
  /// Fake OFF API and SOME of the backend functions
  Future<bool> fakeOffApi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_FAKE_OFF_API) ?? false;
  }

  Future<void> setFakeOffApi(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_FAKE_OFF_API, value);
  }

  Future<bool> fakeOffApiProductNotFound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_FAKE_OFF_API_PRODUCT_NOT_FOUND) ?? false;
  }

  Future<void> setFakeOffApiProductNotFound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_FAKE_OFF_API_PRODUCT_NOT_FOUND, value);
  }
}
