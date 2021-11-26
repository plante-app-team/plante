import 'package:shared_preferences/shared_preferences.dart';

const _TESTING_BACKENDS = 'TESTING_BACKENDS';
const _TESTING_BACKENDS_QUICK_ANSWERS = 'TESTING_BACKENDS_QUICK_ANSWERS';
const _FAKE_OFF_API_PRODUCT_NOT_FOUND = 'FAKE_OFF_API_PRODUCT_NOT_FOUND';
const _NEWEST_FEATURES = 'FAKE_NEWEST_FEATURES';

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

  Future<bool> testingBackendsQuickAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_TESTING_BACKENDS_QUICK_ANSWERS) ?? false;
  }

  Future<void> setTestingBackendsQuickAnswers(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_TESTING_BACKENDS_QUICK_ANSWERS, value);
  }

  Future<bool> fakeOffApiProductNotFound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_FAKE_OFF_API_PRODUCT_NOT_FOUND) ?? false;
  }

  Future<void> setFakeOffApiProductNotFound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_FAKE_OFF_API_PRODUCT_NOT_FOUND, value);
  }

  Future<bool> enableNewestFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_NEWEST_FEATURES) ?? false;
  }

  Future<void> setEnableNewestFeatures(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_NEWEST_FEATURES, value);
  }
}
