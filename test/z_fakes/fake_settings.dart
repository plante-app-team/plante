import 'package:plante/base/settings.dart';

class FakeSettings implements Settings {
  @override
  Future<bool> enableNewestFeatures() async => true;

  @override
  Future<void> setEnableNewestFeatures(bool value) async {}
}
