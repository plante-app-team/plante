import 'package:plante/base/settings.dart';

class FakeSettings implements Settings {
  final _observers = <SettingsObserver>[];
  bool _enableNewestFeatures = true;
  bool _enableOFFProductsSuggestions = true;
  bool _setEnableOFFProductsSuggestions = true;
  bool? _distanceInMiles;

  @override
  void addObserver(SettingsObserver observer) => _observers.add(observer);

  @override
  void removeObserver(SettingsObserver observer) => _observers.remove(observer);

  @override
  Future<bool> enableNewestFeatures() async => _enableNewestFeatures;

  @override
  Future<void> setEnableNewestFeatures(bool value) async {
    _enableNewestFeatures = value;
    _observers.forEach((o) => o.onSettingsChange());
  }

  @override
  Future<bool> enableOFFProductsSuggestions() async =>
      _enableOFFProductsSuggestions;

  @override
  Future<bool> enableRadiusProductsSuggestions() async =>
      _setEnableOFFProductsSuggestions;

  @override
  Future<void> setEnableOFFProductsSuggestions(bool value) async {
    _enableOFFProductsSuggestions = value;
    _observers.forEach((o) => o.onSettingsChange());
  }

  @override
  Future<void> setEnableRadiusProductsSuggestions(bool value) async {
    _setEnableOFFProductsSuggestions = value;
    _observers.forEach((o) => o.onSettingsChange());
  }

  @override
  Future<bool?> distanceInMiles() async => _distanceInMiles;

  @override
  Future<void> setDistanceInMiles(bool? value) async {
    _distanceInMiles = value;
    _observers.forEach((o) => o.onSettingsChange());
  }
}
