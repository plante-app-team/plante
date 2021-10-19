import 'dart:async';

import 'package:openfoodfacts/model/parameter/TagFilter.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/retryable_lazy_operation.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_user.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

enum OffShopsManagerError {
  NETWORK,
  OTHER,
}

// TODO: move to the 'off' folder
// TODO: test throughout
class OffShopsManager {
  final OffApi _offApi;
  final LatestCameraPosStorage _cameraPosStorage;
  final AddressObtainer _addressObtainer;
  final ProductsObtainer _productsObtainer;

  late final RetryableLazyOperation<List<OffShop>, OffShopsManagerError>
      _offShopsOp;
  late final RetryableLazyOperation<String, None> _countryCodeOp;

  final _offShopsProductsCache = <String, List<Product>>{};

  OffShopsManager(this._offApi, this._cameraPosStorage, this._addressObtainer,
      this._productsObtainer) {
    _offShopsOp = RetryableLazyOperation(_fetchOffShopsImpl);
    _countryCodeOp = RetryableLazyOperation(_getCountryCodeImpl);
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
      String shopName) async {
    if (!(await enableNewestFeatures())) {
      return Ok(const []);
    }
    Log.i('offShopsManager.fetchVeganProductsForShop $shopName');

    final countryCode = await _countryCodeOp.result;
    if (countryCode.isErr) {
      return Ok(const []);
    }

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
      return Ok(const []);
    }

    // Let's fetch shop's products!
    final offProducts = await _fetchProducts(possibleOffShopID);
    if (offProducts == null) {
      Log.w('offShopManager.fetchVeganProductsForShop '
          'searchResult without products');
      return Err(OffShopsManagerError.OTHER);
    }
    final productsRes = await _productsObtainer.inflateOffProducts(offProducts);
    if (productsRes.isErr) {
      return Err(productsRes.unwrapErr().convert());
    }

    // Cache result and return it
    final products = productsRes.unwrap();
    _offShopsProductsCache[possibleOffShopID] = products;
    return Ok(products);
  }

  Future<List<off.Product>?> _fetchProducts(String shopId) async {
    // TODO: fetch other than page 1

    final products1 = await _fetchProductsWithVeganIngredients(shopId);
    final products2 = await _fetchProductsWithVeganLabel(shopId);

    if (products1 != null && products2 != null) {
      final products1Barcodes = products1.map((e) => e.barcode).toSet();
      products2.removeWhere(
          (product) => products1Barcodes.contains(product.barcode));
    }

    if (products1 != null && products2 != null) {
      return products1 + products2;
    } else if (products1 != null) {
      return products1;
    } else if (products2 != null) {
      return products2;
    } else {
      return null;
    }
  }

  Future<List<off.Product>?> _fetchProductsWithVeganIngredients(
      String shopId) async {
    final conf = off.ProductSearchQueryConfiguration(parametersList: [
      const off.TagFilter(
          tagType: 'ingredients_analysis', contains: true, tagName: 'en:vegan'),
      off.TagFilter(tagType: 'stores', contains: true, tagName: shopId),
    ]);
    final searchResult =
        await off.OpenFoodAPIClient.searchProducts(_offUser(), conf);
    return searchResult.products;
  }

  Future<List<off.Product>?> _fetchProductsWithVeganLabel(String shopId) async {
    final conf = off.ProductSearchQueryConfiguration(parametersList: [
      const off.TagFilter(
          tagType: 'labels', contains: true, tagName: 'en:vegan'),
      off.TagFilter(tagType: 'stores', contains: true, tagName: shopId),
    ]);
    final searchResult =
        await off.OpenFoodAPIClient.searchProducts(_offUser(), conf);
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

off.User _offUser() =>
    const off.User(userId: OffUser.USERNAME, password: OffUser.PASSWORD);
