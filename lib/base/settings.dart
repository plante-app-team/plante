import 'package:shared_preferences/shared_preferences.dart';

const _TESTING_BACKENDS = 'TESTING_BACKENDS';
const _FAKE_OFF_API_PRODUCT_NOT_FOUND = 'FAKE_OFF_API_PRODUCT_NOT_FOUND';

class Settings {
  /// Fake OFF API and SOME of the backend functions
  Future<bool> testingBackends() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_TESTING_BACKENDS) ?? false;
  }

  Future<void> setTestingBackends(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_TESTING_BACKENDS, value);
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
