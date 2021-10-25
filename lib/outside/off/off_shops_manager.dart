import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/cached_operation.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_list_wrapper.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

enum OffShopsManagerError {
  NETWORK,
  OTHER,
}

typedef ShopNamesAndBarcodesMap = Map<String, List<String>>;

class OffShopsManager {
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
  final OffApi _offApi;
  final LatestCameraPosStorage _cameraPosStorage;
  final AddressObtainer _addressObtainer;

  late final CachedOperation<OffShopsListWrapper, OffShopsManagerError>
      _offShopsOp;
  late final CachedOperation<String, None> _countryCodeOp;

  final ShopNamesAndBarcodesMap _offShopsProductsCache = {};

  OffShopsManager(this._offApi, this._cameraPosStorage, this._addressObtainer) {
    _offShopsOp = CachedOperation(_fetchOffShopsImpl);
    _countryCodeOp = CachedOperation(_getCountryCodeImpl);
  }

  void dispose() {
    _offShopsOp.result.then((offShops) => offShops.maybeOk()?.dispose());
  }

  Future<Result<String, None>> _getCountryCodeImpl() async {
    final cameraPos = await _cameraPosStorage.get();
    if (cameraPos == null) {
      Log.w('offShopsManager._getCountryCodeImpl: no camera pos');
      return Err(None());
    }

    final addressRes = await _addressObtainer.addressOfCoords(cameraPos);
    if (addressRes.isErr) {
      Log.w('offShopsManager._getCountryCodeImpl: '
          'could not properly initialize because of $addressRes');
      return Err(None());
    }
    final address = addressRes.unwrap();
    final countryCode = address.countryCode;
    if (countryCode == null) {
      Log.w('offShopsManager._getCountryCodeImpl: '
          'User is out of all countries! Coord: $cameraPos, addr: $address');
      return Err(None());
    }

    return Ok(countryCode);
  }

  Future<Result<List<OffShop>, OffShopsManagerError>> fetchOffShops() async {
    if (!(await enableNewestFeatures())) {
      return Ok(const []);
    }
    final shopsRes = await _offShopsOp.result;
    if (shopsRes.isErr) {
      return Err(shopsRes.unwrapErr());
    }
    return Ok(shopsRes.unwrap().shops);
  }

  Future<Result<OffShopsListWrapper, OffShopsManagerError>>
      _fetchOffShopsImpl() async {
    final countryCode = await _countryCodeOp.result;
    if (countryCode.isErr) {
      Log.w('offShopsManager.fetchOffShops - no country code, cannot fetch');
      return Err(OffShopsManagerError.OTHER);
    }

    final shopsRes = await _offApi.getShopsForLocation(countryCode.unwrap());
    if (shopsRes.isErr) {
      Log.w('offShopManager.fetchOffShop error: $shopsRes');
      return Err(shopsRes.unwrapErr().convert());
    }
    final shops = shopsRes.unwrap();
    return Ok(await OffShopsListWrapper.create(shops));
  }

  Future<Result<ShopNamesAndBarcodesMap, OffShopsManagerError>>
      fetchVeganBarcodesForShops(
          Set<String> shopsNames, List<LangCode> langs) async {
    if (!(await enableNewestFeatures())) {
      return Ok(const {});
    }
    final countryCodeRes = await _countryCodeOp.result;
    final shopsRes = await _offShopsOp.result;
    if (shopsRes.isErr) {
      return Err(shopsRes.unwrapErr());
    } else if (countryCodeRes.isErr) {
      return Err(OffShopsManagerError.OTHER);
    }
    final shopsWrapper = shopsRes.unwrap();
    final shops = await shopsWrapper.findAppropriateShopsFor(shopsNames);
    final ShopNamesAndBarcodesMap result = {};
    final countryCode = countryCodeRes.unwrap();

    for (final nameAndShop in shops.entries) {
      final name = nameAndShop.key;
      final shop = nameAndShop.value;

      final existingCache = _offShopsProductsCache[name];
      if (existingCache != null) {
        result[name] = existingCache;
      } else {
        final barcodesRes = await _queryBarcodesFor(shop, countryCode);
        if (barcodesRes.isErr) {
          return Err(barcodesRes.unwrapErr());
        }
        final barcodes = barcodesRes.unwrap();
        result[name] = barcodes;
        _offShopsProductsCache[name] = barcodes;
      }
    }
    return Ok(result);
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
