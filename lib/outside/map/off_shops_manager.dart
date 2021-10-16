import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/retryable_lazy_operation.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';
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

  late final RetryableLazyOperation<List<OffShop>, OffShopsManagerError> _offShopsOp;
  late final RetryableLazyOperation<String, None> _countryCodeOp;

  final _offShopsProductsCache = <String, List<Product>>{};

  OffShopsManager(this._offApi, this._cameraPosStorage, this._addressObtainer, this._productsObtainer) {
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

  Future<Result<List<OffShop>, OffShopsManagerError>> _fetchOffShopsImpl() async {
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

  Future<Result<List<Product>, OffShopsManagerError>> fetchVeganProductsForShop(String shopName) async {
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
    // TODO: fetch other than page 1
    final offProductsRes = await _offApi.getVeganProductsForShop(countryCode.unwrap(), possibleOffShopID, 1);
    if (offProductsRes.isErr) {
      return Err(offProductsRes.unwrapErr().convert());
    }
    final searchResult = offProductsRes.unwrap();
    final offProducts = searchResult.products;
    if (offProducts == null) {
      Log.w('offShopManager.fetchVeganProductsForShop '
          'searchResult without products: $searchResult');
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

  String shopNameToPossibleOffShopID(String shopName) => shopName.toLowerCase().trim();
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
