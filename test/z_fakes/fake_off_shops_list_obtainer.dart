import 'dart:io';

import 'package:plante/base/result.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_list_obtainer.dart';

class FakeOffShopsListObtainer implements OffShopsListObtainer {
  final _shops = <String, Result<List<OffShop>, OffShopsListObtainerError>?>{};

  @override
  String get folderName => 'FakeOffShopsListObtainer';
  @override
  int get maxFolderSize => 0;
  @override
  Duration get maxPersistentCacheLifetime => Duration.zero;

  void setShopsForCountry(String countryIso,
      Result<List<OffShop>, OffShopsListObtainerError>? shops) {
    _shops[countryIso] = shops;
  }

  @override
  Future<Result<List<OffShop>, OffShopsListObtainerError>> getShopsForCountry(
      String countryIso) async {
    final result = _shops[countryIso];
    if (result == null) {
      return Ok(const []);
    }
    return result;
  }

  @override
  Future<Directory> getFolder() async {
    return Directory('/tmp/$folderName');
  }
}
