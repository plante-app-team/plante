import 'package:shared_preferences/shared_preferences.dart';

const _FAKE_OFF_API = "FAKE_OFF_API";
const _FAKE_OFF_API_PRODUCT_NOT_FOUND = "FAKE_OFF_API_PRODUCT_NOT_FOUND";
const _FAKE_SCANNED_PRODUCT_BARCODE = "FAKE_SCANNED_PRODUCT_BARCODE";
const _CRASH_ON_ERRORS = "CRASH_ON_ERRORS";

class Settings {
  /// Fake OFF API and SOME of the backend functions
  Future<bool> fakeOffApi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_FAKE_OFF_API) ?? false;
  }

  Future<void> setFakeOffApi(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_FAKE_OFF_API, value);
  }

  Future<bool> fakeOffApiProductNotFound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_FAKE_OFF_API_PRODUCT_NOT_FOUND) ?? false;
  }

  Future<void> setFakeOffApiProductNotFound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_FAKE_OFF_API_PRODUCT_NOT_FOUND, value);
  }

  Future<String> fakeScannedProductBarcode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_FAKE_SCANNED_PRODUCT_BARCODE) ?? "";
  }

  Future<void> setFakeScannedProductBarcode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_FAKE_SCANNED_PRODUCT_BARCODE, value);
  }

  Future<void> setCrashOnErrors(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_CRASH_ON_ERRORS, value);
  }

  Future<bool> crashOnErrors() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_CRASH_ON_ERRORS) ?? true;
  }
}
