import 'package:plante/base/optional.dart';
import 'package:plante/model/shared_preferences_holder.dart';

const _NEWEST_FEATURES = 'Settings.NEWEST_FEATURES';
const _PRODUCTS_SUGGESTIONS_RADIUS = 'Settings.PRODUCTS_SUGGESTIONS_RADIUS';
const _PRODUCTS_SUGGESTIONS_OFF = 'Settings.PRODUCTS_SUGGESTIONS_OFF';
const _DISTANCE_IN_MILES = 'Settings.DISTANCE_IN_MILES';

abstract class SettingsObserver {
  void onSettingsChange();
}

class Settings {
  final SharedPreferencesHolder _prefs;
  final _observers = <SettingsObserver>[];
  var _distanceInMilesCache = Optional<bool?>.empty();

  Settings(this._prefs);

  void addObserver(SettingsObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(SettingsObserver observer) {
    _observers.remove(observer);
  }

  Future<bool> enableNewestFeatures() async {
    final prefs = await _prefs.get();
    return prefs.getBool(_NEWEST_FEATURES) ?? false;
  }

  Future<void> setEnableNewestFeatures(bool value) async {
    final prefs = await _prefs.get();
    await prefs.setBool(_NEWEST_FEATURES, value);
    _observers.forEach((o) => o.onSettingsChange());
  }

  Future<bool> enableRadiusProductsSuggestions() async {
    final prefs = await _prefs.get();
    return prefs.getBool(_PRODUCTS_SUGGESTIONS_RADIUS) ?? true;
  }

  Future<void> setEnableRadiusProductsSuggestions(bool value) async {
    final prefs = await _prefs.get();
    await prefs.setBool(_PRODUCTS_SUGGESTIONS_RADIUS, value);
    _observers.forEach((o) => o.onSettingsChange());
  }

  Future<bool> enableOFFProductsSuggestions() async {
    final prefs = await _prefs.get();
    return prefs.getBool(_PRODUCTS_SUGGESTIONS_OFF) ?? true;
  }

  Future<void> setEnableOFFProductsSuggestions(bool value) async {
    final prefs = await _prefs.get();
    await prefs.setBool(_PRODUCTS_SUGGESTIONS_OFF, value);
    _observers.forEach((o) => o.onSettingsChange());
  }

  Future<bool?> distanceInMiles() async {
    if (_distanceInMilesCache.isNotPresent) {
      final prefs = await _prefs.get();
      _distanceInMilesCache = Optional.of(prefs.getBool(_DISTANCE_IN_MILES));
    }
    return _distanceInMilesCache.value;
  }

  Future<void> setDistanceInMiles(bool? value) async {
    final prefs = await _prefs.get();
    _distanceInMilesCache = Optional.of(value);
    if (value != null) {
      await prefs.setBool(_DISTANCE_IN_MILES, value);
    } else {
      await prefs.remove(_DISTANCE_IN_MILES);
    }
    _observers.forEach((o) => o.onSettingsChange());
  }
}
