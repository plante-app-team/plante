import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/shops_manager_impl.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/map/lat_lng_extensions.dart';
import 'package:plante/base/date_time_extensions.dart';

/// Wrapper around ShopsManagerImpl with caching and retry logic.
class ShopsManager {
  final _listeners = <ShopsManagerListener>[];
  final ShopsManagerImpl _impl;

  static const MAX_SHOPS_LOADS_ATTEMPTS = 3;
  static final _shopsLoadsAttemptsCooldown = isInTests()
      ? const Duration(milliseconds: 50)
      : const Duration(seconds: 3);

  DateTime _lastShopsLoadTime = DateTime(2000);
  bool _loadingArea = false;
  final _delayedLoadings = <VoidCallback>[];

  final _shopsCache = <String, Shop>{};
  final _loadedAreas = <LatLngBounds, List<String>>{};
  final _rangesCache = <String, ShopProductRange>{};

  int get loadedAreasCount => _loadedAreas.length;

  ShopsManager(OpenStreetMap openStreetMap, Backend backend,
      ProductsManager productsManager)
      : _impl = ShopsManagerImpl(openStreetMap, backend, productsManager);

  void addListener(ShopsManagerListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ShopsManagerListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    _listeners.forEach((listener) {
      listener.onLocalShopsChange();
    });
  }

  Future<Result<Map<String, Shop>, ShopsManagerError>> fetchShops(
      Point<double> northeast, Point<double> southwest) async {
    final completer = Completer<Result<Map<String, Shop>, ShopsManagerError>>();
    VoidCallback? callback;
    callback = () async {
      _loadingArea = true;
      try {
        final result = await _maybeLoadShops(
            LatLngBounds(
                northeast: LatLng(northeast.y, northeast.x),
                southwest: LatLng(southwest.y, southwest.x)),
            attemptNumber: 1);
        _delayedLoadings.remove(callback);
        completer.complete(result);
      } finally {
        _loadingArea = false;
      }
      if (_delayedLoadings.isNotEmpty) {
        _delayedLoadings.first.call();
      }
    };
    _delayedLoadings.add(callback);
    if (!_loadingArea) {
      _delayedLoadings.first.call();
    }
    return completer.future;
  }

  Future<Result<Map<String, Shop>, ShopsManagerError>> _maybeLoadShops(
      LatLngBounds bounds,
      {required int attemptNumber}) async {
    for (final loadedArea in _loadedAreas.keys) {
      // Already loaded
      if (loadedArea.containsBounds(bounds)) {
        final ids = _loadedAreas[loadedArea]!;
        final shops = ids
            .map((id) => _shopsCache[id]!)
            .where((shop) => bounds.containsShop(shop));
        return Ok({for (var shop in shops) shop.osmId: shop});
      }
    }

    // +-20 kms
    var boundsToLoad = bounds.center.makeSquare(20 * 1 / 111);
    if (boundsToLoad.width < bounds.width ||
        boundsToLoad.height < bounds.width) {
      Log.w('Requested bounds are unexpectedly big');
      boundsToLoad = bounds;
    }
    final timeSinceLastLoad = DateTime.now().difference(_lastShopsLoadTime);
    if (timeSinceLastLoad < _shopsLoadsAttemptsCooldown) {
      await Future.delayed(_shopsLoadsAttemptsCooldown - timeSinceLastLoad);
    }

    _lastShopsLoadTime = DateTime.now();
    final shopsResult = await _impl.fetchShops(
        Point(
            boundsToLoad.northeast.latitude, boundsToLoad.northeast.longitude),
        Point(
            boundsToLoad.southwest.latitude, boundsToLoad.southwest.longitude));

    if (shopsResult.isErr) {
      if (shopsResult.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
        return Err(shopsResult.unwrapErr());
      } else {
        if (attemptNumber >= MAX_SHOPS_LOADS_ATTEMPTS) {
          return Err(shopsResult.unwrapErr());
        }
        return _maybeLoadShops(bounds, attemptNumber: attemptNumber + 1);
      }
    }

    final shops = shopsResult.unwrap();
    _shopsCache.addAll(shops);
    _loadedAreas[boundsToLoad] =
        shops.values.map((shop) => shop.osmId).toList();
    return Ok(shops);
  }

  Future<Result<ShopProductRange, ShopsManagerError>> fetchShopProductRange(
      Shop shop,
      {bool noCache = false}) async {
    if (!noCache) {
      final cache = _rangesCache[shop.osmId];
      if (cache != null) {
        return Ok(cache);
      }
    }
    final result = await _impl.fetchShopProductRange(shop);
    if (result.isOk) {
      _rangesCache[shop.osmId] = result.unwrap();
    }
    return result;
  }

  Future<Result<None, ShopsManagerError>> putProductToShops(
      Product product, List<Shop> shops) async {
    final result = await _impl.putProductToShops(product, shops);
    if (result.isOk) {
      for (final shop in shops) {
        var rangeCache = _rangesCache[shop.osmId];
        if (rangeCache != null) {
          final now = DateTime.now().secondsSinceEpoch;
          rangeCache = rangeCache.rebuild((e) => e
            ..products.add(product)
            ..productsLastSeenSecsUtc[product.barcode] = now);
          _rangesCache[shop.osmId] = rangeCache;
        }

        var shopCache = _shopsCache[shop.osmId];
        var backendShop = shopCache?.backendShop;
        if (shopCache != null && backendShop != null) {
          backendShop = backendShop
              .rebuild((e) => e.productsCount = backendShop!.productsCount + 1);
          shopCache =
              shopCache.rebuild((e) => e.backendShop.replace(backendShop!));
          _shopsCache[shop.osmId] = shopCache;
        }
      }
      _notifyListeners();
    }
    return result;
  }

  /// Note: currently server doesn't support all shop types
  Future<Result<Shop, ShopsManagerError>> createShop(
      {required String name,
      required Point<double> coords,
      required ShopType type}) async {
    final result =
        await _impl.createShop(name: name, coords: coords, type: type);
    if (result.isOk) {
      final shop = result.unwrap();
      _shopsCache[shop.osmId] = shop;
      for (final loadedArea in _loadedAreas.keys) {
        if (loadedArea.containsShop(shop)) {
          _loadedAreas[loadedArea]!.add(shop.osmId);
        }
      }
      _notifyListeners();
    }
    return result;
  }
}
