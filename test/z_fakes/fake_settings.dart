import 'package:plante/base/settings.dart';

class FakeSettings implements Settings {
  bool _enableNewestFeatures = true;
  bool _enableOFFProductsSuggestions = true;
  bool _setEnableOFFProductsSuggestions = true;

  @override
  Future<bool> enableNewestFeatures() async => _enableNewestFeatures;

  @override
  Future<void> setEnableNewestFeatures(bool value) async {
    _enableNewestFeatures = value;
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
  }

  @override
  Future<void> setEnableRadiusProductsSuggestions(bool value) async {
    _setEnableOFFProductsSuggestions = value;
  }
}
