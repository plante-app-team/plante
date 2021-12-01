import 'package:flutter/foundation.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/off/off_vegan_barcodes_storage.dart';

typedef ShopsAndBarcodesMap = Map<OffShop, List<String>>;

class OffVeganBarcodesObtainer {
  final OffApi _offApi;
  final OffVeganBarcodesStorage _storage;

  // OFF categories considered acceptable for products which are vegan
  // accidentally. The field is needed to avoid returning grains and canned
  // vegetables.
  static const _ACCIDENTALLY_VEGAN_ACCEPTABLE_CATEGORIES = [
    'en:desserts',
    'en:snacks',
    'en:meat-analogues',
    'en:milk-substitute',
    'en:non-dairy-yogurts',
    'en:frozen-desserts',
    'en:chips-and-fries',
    'en:biscuits-and-cakes',
    'en:veggie-patties',
    'en:biscuits',
  ];

  OffVeganBarcodesObtainer(this._offApi, this._storage);

  Future<Result<ShopsAndBarcodesMap, OffShopsManagerError>>
      obtainVeganBarcodesForShops(
          String countryCode, Iterable<OffShop> shops) async {
    _validateCountryCodes(shops, countryCode);

    final ShopsAndBarcodesMap result = {};

    for (final shop in shops) {
      final existingCache = await _storage.getBarcodesAtShops([shop]);
      if (existingCache[shop] != null) {
        result[shop] = existingCache[shop]!;
      } else {
        final barcodesRes = await _queryBarcodesFor(shop, countryCode);
        if (barcodesRes.isErr) {
          return Err(barcodesRes.unwrapErr());
        }

        final barcodes = barcodesRes.unwrap();
        result[shop] = barcodes;
        await _storage.setBarcodesOfShop(shop, barcodes);
      }
    }
    return Ok(result);
  }

  void _validateCountryCodes(Iterable<OffShop> shops, String countryCode) {
    if (kDebugMode) {
      for (final shop in shops) {
        if (shop.country != countryCode) {
          throw Exception(
              'countryCode $countryCode does not match country code in $shop');
        }
      }
    }
  }

  Future<Result<List<String>, OffShopsManagerError>> _queryBarcodesFor(
      OffShop shop, String countryCode) async {
    final barcodesRes1 = await _offApi.getBarcodesVeganByIngredients(
        countryCode, shop, _ACCIDENTALLY_VEGAN_ACCEPTABLE_CATEGORIES);
    final barcodesRes2 =
        await _offApi.getBarcodesVeganByLabel(countryCode, shop);

    if (barcodesRes1.isOk && barcodesRes2.isOk) {
      final barcodes1 = barcodesRes1.unwrap().toSet();
      final barcodes2Filtered =
          barcodesRes2.unwrap().where((e) => !barcodes1.contains(e));
      return Ok(barcodes1.toList() + barcodes2Filtered.toList());
    } else if (barcodesRes1.isOk) {
      return Ok(barcodesRes1.unwrap());
    } else if (barcodesRes2.isOk) {
      return Ok(barcodesRes2.unwrap());
    } else {
      return Err(barcodesRes1.unwrapErr().convert());
    }
  }
}

extension _OffRestApiErrorExt on OffRestApiError {
  OffShopsManagerError convert() {
    switch (this) {
      case OffRestApiError.NETWORK:
        return OffShopsManagerError.NETWORK;
      case OffRestApiError.OTHER:
        return OffShopsManagerError.OTHER;
    }
  }
}
