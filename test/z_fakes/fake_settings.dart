import 'package:plante/base/settings.dart';

class FakeSettings implements Settings {
  @override
  Future<bool> fakeOffApiProductNotFound() async => false;

  @override
  Future<void> setFakeOffApiProductNotFound(bool value) async {}

  @override
  Future<void> setTestingBackends(bool value) async {}

  @override
  Future<bool> testingBackends() async => false;

  @override
  Future<void> setTestingBackendsQuickAnswers(bool value) async {}

  @override
  Future<bool> testingBackendsQuickAnswers() async => true;

  @override
  Future<bool> enableNewestFeatures() async => true;

  @override
  Future<void> setEnableNewestFeatures(bool value) async {}
}
