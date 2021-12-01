import 'dart:collection';

import 'package:plante/outside/off/off_cacher.dart';
import 'package:plante/outside/off/off_shop.dart';

class OffVeganBarcodesStorage {
  static const _DEFAULT_MAX_LIFETIME = Duration(days: 14);

  final OffCacher _offCacher;
  final Duration _maxLifetime;
  final Map<String, List<String>> _cache = {};

  OffVeganBarcodesStorage(this._offCacher,
      [this._maxLifetime = _DEFAULT_MAX_LIFETIME]);

  Future<Map<OffShop, List<String>>> getBarcodesAtShops(
      Iterable<OffShop> shops) async {
    final Map<OffShop, List<String>> result = {};
    for (final shop in shops) {
      var barcodes = _cache[shop.id];
      barcodes ??= await _getBarcodesFromDB(shop.country, shop.id);
      if (barcodes != null) {
        _cache[shop.id] = barcodes;
        result[shop] = UnmodifiableListView(barcodes);
      }
    }
    return result;
  }

  Future<List<String>?> _getBarcodesFromDB(
      String countryCode, String shopId) async {
    final barcodesAtShop =
        await _offCacher.getBarcodesAtShop(countryCode, shopId);
    if (barcodesAtShop == null) {
      return null;
    }
    final now = DateTime.now();
    if (now.difference(barcodesAtShop.whenObtained) > _maxLifetime) {
      await _offCacher.deleteShopsCache([shopId], countryCode);
      return null;
    }
    return barcodesAtShop.barcodes;
  }

  Future<void> setBarcodesOfShop(
      OffShop shop, Iterable<String> barcodes) async {
    final now = DateTime.now();
    await _offCacher.setBarcodes(now, shop.country, shop.id, barcodes);
    _cache[shop.id] = barcodes.toList();
  }
}
