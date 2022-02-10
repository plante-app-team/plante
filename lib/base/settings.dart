import 'package:shared_preferences/shared_preferences.dart';

const _NEWEST_FEATURES = 'Settings.NEWEST_FEATURES';
const _PRODUCTS_SUGGESTIONS_RADIUS = 'Settings.PRODUCTS_SUGGESTIONS_RADIUS';
const _PRODUCTS_SUGGESTIONS_OFF = 'Settings.PRODUCTS_SUGGESTIONS_OFF';

class Settings {
  Future<bool> enableNewestFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_NEWEST_FEATURES) ?? false;
  }

  Future<void> setEnableNewestFeatures(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_NEWEST_FEATURES, value);
  }

  Future<bool> enableRadiusProductsSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_PRODUCTS_SUGGESTIONS_RADIUS) ?? true;
  }

  Future<void> setEnableRadiusProductsSuggestions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PRODUCTS_SUGGESTIONS_RADIUS, value);
  }

  Future<bool> enableOFFProductsSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_PRODUCTS_SUGGESTIONS_OFF) ?? true;
  }

  Future<void> setEnableOFFProductsSuggestions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PRODUCTS_SUGGESTIONS_OFF, value);
  }
}
