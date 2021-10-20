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
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

enum OffShopsManagerError {
  NETWORK,
  OTHER,
}

class OffShopsManager {
  final OffApi _offApi;
  final LatestCameraPosStorage _cameraPosStorage;
  final AddressObtainer _addressObtainer;
  final ProductsManager _productsManager;

  late final CachedOperation<List<OffShop>, OffShopsManagerError> _offShopsOp;
  late final CachedOperation<String, None> _countryCodeOp;

  final _offShopsProductsCache = <String, List<Product>>{};

  OffShopsManager(this._offApi, this._cameraPosStorage, this._addressObtainer,
      this._productsManager) {
    _offShopsOp = CachedOperation(_fetchOffShopsImpl);
    _countryCodeOp = CachedOperation(_getCountryCodeImpl);
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
    return await _offShopsOp.result;
  }

  Future<Result<List<OffShop>, OffShopsManagerError>>
      _fetchOffShopsImpl() async {
    if (!(await enableNewestFeatures())) {
      return Ok(const []);
    }

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
    return Ok(shopsRes.unwrap());
  }

  Future<Result<List<Product>, OffShopsManagerError>> fetchVeganProductsForShop(
      String shopName, List<LangCode> langs) async {
    if (!(await enableNewestFeatures())) {
      return Ok(const []);
    }
    Log.i('offShopsManager.fetchVeganProductsForShop $shopName');

    // Maybe we already have the value in cache
    final possibleOffShopID = shopNameToPossibleOffShopID(shopName);
    final existingCache = _offShopsProductsCache[possibleOffShopID];
    if (existingCache != null) {
      return Ok(existingCache);
    }

    // Let's check whether the shop has any products
    final offShopsRes = await fetchOffShops();
    if (offShopsRes.isErr) {
      Log.w('offShopManager.fetchVeganProductsForShop could not fetch shops');
      return Err(OffShopsManagerError.OTHER);
    }
    final offShops = offShopsRes.unwrap();
    if (!offShops.any((element) => element.id == possibleOffShopID)) {
      _offShopsProductsCache[possibleOffShopID] = const [];
      return Ok(const []);
    }

    // Let's fetch shop's products!
    final countryCodeRes = await _countryCodeOp.result;
    if (countryCodeRes.isErr) {
      return Ok(const []);
    }
    final offProductsRes =
        await _fetchProducts(possibleOffShopID, countryCodeRes.unwrap(), langs);
    if (offProductsRes.isErr) {
      return Err(offProductsRes.unwrapErr());
    }
    final offProducts = offProductsRes.unwrap();
    if (offProducts == null) {
      Log.w('offShopManager.fetchVeganProductsForShop '
          'searchResult without products');
      return Err(OffShopsManagerError.OTHER);
    }
    final productsRes =
        await _productsManager.inflateOffProducts(offProducts, langs);
    if (productsRes.isErr) {
      return Err(productsRes.unwrapErr().convert());
    }

    // Cache result and return it
    final products = productsRes.unwrap();
    _offShopsProductsCache[possibleOffShopID] = products;
    return Ok(products);
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
      shopName.toLowerCase().trim();
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

extension _ProductsManagerErrorExt on ProductsManagerError {
  OffShopsManagerError convert() {
    switch (this) {
      case ProductsManagerError.NETWORK_ERROR:
        return OffShopsManagerError.NETWORK;
      case ProductsManagerError.OTHER:
        return OffShopsManagerError.OTHER;
    }
  }
}
