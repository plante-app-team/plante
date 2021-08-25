import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_cacher.dart';
import 'package:plante/outside/map/shops_manager_fetch_shops_helper.dart';
import 'package:plante/outside/map/shops_manager_impl.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/base/date_time_extensions.dart';

/// Wrapper around ShopsManagerImpl with caching and retry logic.
class ShopsManager {
  static const DAYS_BEFORE_PERSISTENT_CACHE_IS_OLD = 7;
  static const DAYS_BEFORE_PERSISTENT_CACHE_IS_ANCIENT = 30;
  final Analytics _analytics;
  late final ShopsManagerFetchShopsHelper _fetchShopsHelper;
  final _listeners = <ShopsManagerListener>[];
  final ShopsManagerImpl _impl;

  static const MAX_SHOPS_LOADS_ATTEMPTS = 2;
  static final _shopsLoadsAttemptsCooldown = isInTests()
      ? const Duration(milliseconds: 50)
      : const Duration(seconds: 3);

  DateTime _lastShopsLoadTime = DateTime(2000);
  bool _loadingArea = false;
  final _delayedLoadings = <VoidCallback>[];

  // If new cache fields are added please update the [clearCache] method.
  final _shopsCache = <String, Shop>{};
  final _loadedAreas = <CoordsBounds, List<String>>{};
  final _rangesCache = <String, ShopProductRange>{};

  int get loadedAreasCount => _loadedAreas.length;

  ShopsManager(OpenStreetMap openStreetMap, Backend backend,
      ProductsObtainer productsObtainer, this._analytics, OsmCacher _osmCacher)
      : _impl = ShopsManagerImpl(openStreetMap, backend, productsObtainer) {
    _fetchShopsHelper = ShopsManagerFetchShopsHelper(_impl, _osmCacher);
  }

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
      CoordsBounds bounds) async {
    final completer = Completer<Result<Map<String, Shop>, ShopsManagerError>>();
    VoidCallback? callback;
    callback = () async {
      _loadingArea = true;
      try {
        final result = await _maybeLoadShops(bounds, attemptNumber: 1);
        completer.complete(result);
        _delayedLoadings.remove(callback);
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
      CoordsBounds bounds,
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

    final timeSinceLastLoad = DateTime.now().difference(_lastShopsLoadTime);
    if (timeSinceLastLoad < _shopsLoadsAttemptsCooldown) {
      await Future.delayed(_shopsLoadsAttemptsCooldown - timeSinceLastLoad);
    }
    _lastShopsLoadTime = DateTime.now();

    final shopsFetchResult = await _fetchShopsHelper.fetchShops(
        viewPort: bounds,
        osmBoundsSizesToRequest: [100, 30],
        planteBoundsSizeToRequest: 20);
    if (shopsFetchResult.isErr) {
      if (shopsFetchResult.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
        return Err(shopsFetchResult.unwrapErr());
      } else {
        if (attemptNumber >= MAX_SHOPS_LOADS_ATTEMPTS) {
          return Err(shopsFetchResult.unwrapErr());
        }
        return _maybeLoadShops(bounds, attemptNumber: attemptNumber + 1);
      }
    }

    final fetchResult = shopsFetchResult.unwrap();
    _shopsCache.addAll(fetchResult.shops);
    final ids = fetchResult.shops.values.map((shop) => shop.osmId).toList();
    _loadedAreas[fetchResult.shopsBounds] = ids;
    final result = ids
        .map((id) => fetchResult.shops[id]!)
        .where((shop) => bounds.containsShop(shop));
    return Ok({for (var shop in result) shop.osmId: shop});
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
    final eventParam = {
      'barcode': product.barcode,
      'shops': shops.map((e) => e.osmId).join(', ')
    };
    if (result.isOk) {
      _analytics.sendEvent('product_put_to_shop', eventParam);
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
        if (shopCache != null) {
          var backendShop = shopCache.backendShop;
          if (backendShop != null) {
            backendShop = backendShop.rebuild(
                (e) => e.productsCount = backendShop!.productsCount + 1);
          } else {
            backendShop = BackendShop((e) => e
              ..osmId = shop.osmId
              ..productsCount = 1);
          }
          shopCache =
              shopCache.rebuild((e) => e.backendShop.replace(backendShop!));
          _shopsCache[shop.osmId] = shopCache;
        } else {
          Log.w('A product is put into a shop while there '
              'was no cache for the shop. Shop: $shop');
        }
      }
      _notifyListeners();
    } else {
      _analytics.sendEvent('product_put_to_shop_failure', eventParam);
    }
    return result;
  }

  Future<Result<Shop, ShopsManagerError>> createShop(
      {required String name,
      required Coord coord,
      required ShopType type}) async {
    final result = await _impl.createShop(name: name, coord: coord, type: type);
    if (result.isOk) {
      final shop = result.unwrap();
      _analytics.sendEvent('create_shop_success',
          {'name': name, 'lat': coord.lat, 'lon': coord.lon});
      _shopsCache[shop.osmId] = shop;
      for (final loadedArea in _loadedAreas.keys) {
        if (loadedArea.containsShop(shop)) {
          _loadedAreas[loadedArea]!.add(shop.osmId);
        }
      }
      _notifyListeners();
    } else {
      _analytics.sendEvent('create_shop_failure',
          {'name': name, 'lat': coord.lat, 'lon': coord.lon});
    }
    return result;
  }

  Future<void> clearCache() async {
    await _fetchShopsHelper.clearCache();
    _shopsCache.clear();
    _loadedAreas.clear();
    _rangesCache.clear();
    _notifyListeners();
  }
}

extension _BoundsExt on CoordsBounds {
  bool containsShop(Shop shop) {
    return contains(Coord(lat: shop.latitude, lon: shop.longitude));
  }
}
