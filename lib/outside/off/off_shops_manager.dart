import 'dart:async';
import 'dart:io';

import 'package:openfoodfacts/model/parameter/TagFilter.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/base.dart';
import 'package:plante/base/cached_operation.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_list_wrapper.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

enum OffShopsManagerError {
  NETWORK,
  OTHER,
}

typedef ShopNamesAndProductsMap = Map<String, List<Product>>;

class OffShopsManager {
  final OffApi _offApi;
  final LatestCameraPosStorage _cameraPosStorage;
  final AddressObtainer _addressObtainer;
  final ProductsManager _productsManager;

  late final CachedOperation<OffShopsListWrapper, OffShopsManagerError>
      _offShopsOp;
  late final CachedOperation<String, None> _countryCodeOp;

  final _offShopsProductsCache = <String, List<Product>>{};

  OffShopsManager(this._offApi, this._cameraPosStorage, this._addressObtainer,
      this._productsManager) {
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

    Log.i('offShopManager.fetchOffShop fetch start');
    final shopsRes = await _offApi.getShopsForLocation(countryCode.unwrap());
    if (shopsRes.isErr) {
      Log.w('offShopManager.fetchOffShop error: $shopsRes');
      return Err(shopsRes.unwrapErr().convert());
    }
    Log.i('offShopManager.fetchOffShop fetch done');
    final shops = shopsRes.unwrap();
    return Ok(await OffShopsListWrapper.create(shops));
  }

  Future<Result<ShopNamesAndProductsMap, OffShopsManagerError>>
      fetchVeganProductsForShops(
          Set<String> shopsNames, List<LangCode> langs) async {
    if (!(await enableNewestFeatures())) {
      return Ok(const {});
    }
    final countryCodeRes = await _countryCodeOp.result;
    final shopsRes = await _offShopsOp.result;
    if (shopsRes.isErr || countryCodeRes.isErr) {
      return Err(shopsRes.unwrapErr());
    }
    final shopsWrapper = shopsRes.unwrap();
    final shops = await shopsWrapper.findAppropriateShopsFor(shopsNames);
    final ShopNamesAndProductsMap result = {};
    final countryCode = countryCodeRes.unwrap();

    for (final nameAndShop in shops.entries) {
      final name = nameAndShop.key;
      final shop = nameAndShop.value;

      final existingCache = _offShopsProductsCache[name];
      if (existingCache != null) {
        result[name] = existingCache;
      } else {
        final offProductsRes =
            await _fetchProducts(shop.id, countryCode, langs);
        if (offProductsRes.isErr || offProductsRes.unwrap() == null) {
          Log.w('offShopManager could not fetch for $shop: $offProductsRes');
          // No good way to handle the error because all other
          // fetches might end with a success.
          continue;
        }
        final offProducts = offProductsRes.unwrap()!;
        final productsRes =
            await _productsManager.inflateOffProducts(offProducts, langs);
        if (productsRes.isErr) {
          Log.w('offShopManager could not inflate for $shop: $productsRes');
          // No good way to handle the error because all other
          // fetches might end with a success.
          continue;
        }
        result[name] = productsRes.unwrap();
        _offShopsProductsCache[name] = productsRes.unwrap();
      }
    }
    return Ok(result);
  }

  Future<Result<List<off.Product>?, OffShopsManagerError>> _fetchProducts(
      String shopId, String countryCode, List<LangCode> langs) async {
    // TODO: fetch other than page 1

    final List<off.Product>? products1;
    final List<off.Product>? products2;
    try {
      products1 =
          await _fetchProductsWithVeganIngredients(shopId, countryCode, langs);
      products2 =
          await _fetchProductsWithVeganLabel(shopId, countryCode, langs);
    } on IOException catch (e) {
      Log.w('_fetchProducts caught exception', ex: e);
      return Err(OffShopsManagerError.NETWORK);
    }

    if (products1 != null && products2 != null) {
      final products1Barcodes = products1.map((e) => e.barcode).toSet();
      final products2Filtered =
          products2.where((p) => !products1Barcodes.contains(p.barcode));
      return Ok(products1 + products2Filtered.toList());
    } else if (products1 != null) {
      return Ok(products1);
    } else if (products2 != null) {
      return Ok(products2);
    } else {
      return Ok(null);
    }
  }

  Future<List<off.Product>?> _fetchProductsWithVeganIngredients(
      String shopId, String countryCode, List<LangCode> langs) async {
    final conf = off.ProductSearchQueryConfiguration(
        cc: countryCode,
        languages:
            langs.map((e) => off.LanguageHelper.fromJson(e.name)).toList(),
        fields: ProductsManager.NEEDED_OFF_FIELDS,
        parametersList: [
          const off.TagFilter(
              tagType: 'ingredients_analysis',
              contains: true,
              tagName: 'en:vegan'),
          off.TagFilter(tagType: 'stores', contains: true, tagName: shopId),
        ]);
    final searchResult = await _offApi.searchProducts(conf);
    return searchResult.products;
  }

  Future<List<off.Product>?> _fetchProductsWithVeganLabel(
      String shopId, String countryCode, List<LangCode> langs) async {
    final conf = off.ProductSearchQueryConfiguration(
        cc: countryCode,
        languages:
            langs.map((e) => off.LanguageHelper.fromJson(e.name)).toList(),
        fields: ProductsManager.NEEDED_OFF_FIELDS,
        parametersList: [
          const off.TagFilter(
              tagType: 'labels', contains: true, tagName: 'en:vegan'),
          off.TagFilter(tagType: 'stores', contains: true, tagName: shopId),
        ]);
    final searchResult = await _offApi.searchProducts(conf);
    return searchResult.products;
  }

  static String shopNameToPossibleOffShopID(String shopName) =>
      OffShop.shopNameToPossibleOffShopID(shopName);
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
