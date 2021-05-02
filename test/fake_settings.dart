import 'package:plante/base/settings.dart';

class FakeSettings implements Settings {
  @override
  Future<bool> fakeOffApi() async => false;

  @override
  Future<bool> fakeOffApiProductNotFound() async => false;

  @override
  Future<String> fakeScannedProductBarcode() async => "";

  @override
  Future<void> setFakeOffApi(bool value) async {
  }

  @override
  Future<void> setFakeOffApiProductNotFound(bool value) async {
  }

  @override
  Future<void> setFakeScannedProductBarcode(String value) async {
  }
}
