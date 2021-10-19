import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_cacher.dart';
import 'package:plante/outside/map/osm_overpass.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/map/shops_manager_backend_worker.dart';
import 'package:plante/outside/map/shops_manager_fetch_shops_helper.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_obtainer.dart';

/// Wrapper around ShopsManagerImpl with caching and retry logic.
class ShopsManager {
  static const DAYS_BEFORE_PERSISTENT_CACHE_IS_OLD = 7;
  static const DAYS_BEFORE_PERSISTENT_CACHE_IS_ANCIENT = 30;
  final Analytics _analytics;
  final OsmCacher _osmCacher;
  late final ShopsManagerFetchShopsHelper _fetchShopsHelper;
  final _listeners = <ShopsManagerListener>[];
  final OpenStreetMap _osm;
  late final ShopsManagerBackendWorker _backendWorker;

  static const MAX_SHOPS_LOADS_ATTEMPTS = 2;
  // If new cache fields are added please update the [clearCache] method.
  final _shopsCache = <OsmUID, Shop>{};
  final _loadedAreas = <CoordsBounds, List<OsmUID>>{};
  final _rangesCache = <OsmUID, ShopProductRange>{};

  int get loadedAreasCount => _loadedAreas.length;

  ShopsManager(this._osm, Backend backend, ProductsObtainer productsObtainer,
      this._analytics, this._osmCacher)
      : _backendWorker = ShopsManagerBackendWorker(backend, productsObtainer) {
    _fetchShopsHelper =
        ShopsManagerFetchShopsHelper(_backendWorker, _osmCacher);
  }

  void addListener(ShopsManagerListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ShopsManagerListener listener) {
    _listeners.remove(listener);
  }

  // TODO test each notification
  void _notifyListeners() {
    _listeners.forEach((listener) {
      listener.onLocalShopsChange();
    });
  }

  Future<bool> osmShopsCacheExistFor(CoordsBounds bounds) async {
    if (_loadShopsFromCache(bounds) != null) {
      return true;
    }
    for (final territory in await _osmCacher.getCachedShops()) {
      if (territory.bounds.containsBounds(bounds)) {
        return true;
      }
    }
    return false;
  }

  Future<Result<Map<OsmUID, Shop>, ShopsManagerError>> fetchShops(
      CoordsBounds bounds) async {
    final existingCache = _loadShopsFromCache(bounds);
    if (existingCache != null) {
      return Ok(existingCache);
    }
    return await _osm.withOverpass((overpass) async =>
        await _maybeLoadShops(overpass, bounds, attemptNumber: 1));
  }

  Map<OsmUID, Shop>? _loadShopsFromCache(CoordsBounds bounds) {
    for (final loadedArea in _loadedAreas.keys) {
      // Already loaded
      if (loadedArea.containsBounds(bounds)) {
        final ids = _loadedAreas[loadedArea]!;
        final shops = ids
            .map((id) => _shopsCache[id]!)
            .where((shop) => bounds.containsShop(shop));
        return {for (var shop in shops) shop.osmUID: shop};
      }
    }
    return null;
  }

  Future<Result<Map<OsmUID, Shop>, ShopsManagerError>> _maybeLoadShops(
      OsmOverpass overpass, CoordsBounds bounds,
      {required int attemptNumber}) async {
    final existingCache = _loadShopsFromCache(bounds);
    if (existingCache != null) {
      return Ok(existingCache);
    }

    final shopsFetchResult = await _fetchShopsHelper.fetchShops(overpass,
        viewPort: bounds,
        osmBoundsSizesToRequest: [100, 91],
        planteBoundsSizeToRequest: 90);
    if (shopsFetchResult.isErr) {
      Log.w(
          'ShopsManager._maybeLoadShops err: $shopsFetchResult, attemptNumber: $attemptNumber');
      if (shopsFetchResult.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
        return Err(shopsFetchResult.unwrapErr());
      } else {
        if (attemptNumber >= MAX_SHOPS_LOADS_ATTEMPTS) {
          return Err(shopsFetchResult.unwrapErr());
        }
        return _maybeLoadShops(overpass, bounds,
            attemptNumber: attemptNumber + 1);
      }
    }

    final fetchResult = shopsFetchResult.unwrap();
    _shopsCache.addAll(fetchResult.shops);
    final ids = fetchResult.shops.values.map((shop) => shop.osmUID).toList();
    _loadedAreas[fetchResult.shopsBounds] = ids;
    final result = ids
        .map((id) => fetchResult.shops[id]!)
        .where((shop) => bounds.containsShop(shop));
    _notifyListeners();
    return Ok({for (var shop in result) shop.osmUID: shop});
  }

  Future<Result<Map<OsmUID, Shop>, ShopsManagerError>> inflateOsmShops(
      Iterable<OsmShop> shops) async {
    final loadedShops = <OsmUID, Shop>{};
    final osmShopsToLoad = <OsmShop>[];
    for (final osmShop in shops) {
      final loadedShop = _shopsCache[osmShop.osmUID];
      if (loadedShop != null) {
        loadedShops[loadedShop.osmUID] = loadedShop;
      } else {
        osmShopsToLoad.add(osmShop);
      }
    }

    if (osmShopsToLoad.isNotEmpty) {
      final inflateResult =
          await _backendWorker.inflateOsmShops(osmShopsToLoad);
      if (inflateResult.isErr) {
        Log.w('ShopsManager.inflateOsmShops err: $inflateResult');
        return inflateResult;
      }

      final inflatedShops = inflateResult.unwrap();
      loadedShops.addAll(inflatedShops);

      for (final inflatedShop in inflatedShops.values) {
        _shopsCache[inflatedShop.osmUID] = inflatedShop;
      }
      _notifyListeners();
      // NOTE: we don't put the shop into [_loadedAreas] because the
      // [_loadedAreas] field is an entire area of already loaded shops -
      // if a shop was not loaded before [inflateOsmShops], it is not expected
      // to be within any of the cached areas.
    }

    return Ok(loadedShops);
  }

  Future<Result<ShopProductRange, ShopsManagerError>> fetchShopProductRange(
      Shop shop,
      {bool noCache = false}) async {
    if (!noCache) {
      final cache = _rangesCache[shop.osmUID];
      if (cache != null) {
        return Ok(cache);
      }
    }
    final result = await _backendWorker.fetchShopProductRange(shop);
    if (result.isOk) {
      _rangesCache[shop.osmUID] = result.unwrap();
    }
    _notifyListeners();
    return result;
  }

  Future<Result<None, ShopsManagerError>> putProductToShops(
      Product product, List<Shop> shops) async {
    final result = await _backendWorker.putProductToShops(product, shops);
    final eventParam = {
      'barcode': product.barcode,
      'shops': shops.map((e) => e.osmUID).join(', ')
    };
    if (result.isOk) {
      _analytics.sendEvent('product_put_to_shop', eventParam);
      for (final shop in shops) {
        var rangeCache = _rangesCache[shop.osmUID];
        if (rangeCache != null) {
          final now = DateTime.now().secondsSinceEpoch;
          rangeCache = rangeCache.rebuild((e) => e
            ..products.add(product)
            ..productsLastSeenSecsUtc[product.barcode] = now);
          _rangesCache[shop.osmUID] = rangeCache;
        }

        var shopCache = _shopsCache[shop.osmUID];
        if (shopCache != null) {
          var backendShop = shopCache.backendShop;
          if (backendShop != null) {
            backendShop = backendShop.rebuild(
                (e) => e.productsCount = backendShop!.productsCount + 1);
          } else {
            backendShop = BackendShop((e) => e
              ..osmUID = shop.osmUID
              ..productsCount = 1);
          }
          shopCache =
              shopCache.rebuild((e) => e.backendShop.replace(backendShop!));
          _shopsCache[shop.osmUID] = shopCache;
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
    final result =
        await _backendWorker.createShop(name: name, coord: coord, type: type);
    if (result.isOk) {
      final shop = result.unwrap();
      _analytics.sendEvent('create_shop_success',
          {'name': name, 'lat': coord.lat, 'lon': coord.lon});
      _shopsCache[shop.osmUID] = shop;
      for (final loadedArea in _loadedAreas.keys) {
        if (loadedArea.containsShop(shop)) {
          _loadedAreas[loadedArea]!.add(shop.osmUID);
        }
      }
      for (final territory in await _osmCacher.getCachedShops()) {
        if (territory.bounds.containsShop(shop)) {
          unawaited(_osmCacher.addShopToCache(territory.id, shop.osmShop));
        }
      }
      _notifyListeners();
    } else {
      _analytics.sendEvent('create_shop_failure',
          {'name': name, 'lat': coord.lat, 'lon': coord.lon});
    }
    return result;
  }

  Future<Result<ProductPresenceVoteResult, ShopsManagerError>>
      productPresenceVote(Product product, Shop shop, bool positive) async {
    final result =
        await _backendWorker.productPresenceVote(product, shop, positive);
    if (result.isOk) {
      final cachedRange = _rangesCache[shop.osmUID];
      final cachedShop = _shopsCache[shop.osmUID];
      if (cachedShop == null) {
        Log.w('productPresenceVote: '
            'cachedShop is null - it is rare but possible');
      }
      if (cachedRange == null) {
        Log.e('Voting was done for a shop range which was not cached before');
        return result;
      }
      if (positive) {
        if (cachedShop != null &&
            !cachedRange.hasProductWith(product.barcode)) {
          _shopsCache[shop.osmUID] = cachedShop.rebuildWith(
              productsCount: cachedShop.productsCount + 1);
        }
        _rangesCache[shop.osmUID] = cachedRange.rebuildWithProduct(
            product, DateTime.now().secondsSinceEpoch);
        _notifyListeners();
      } else if (result.unwrap().productDeleted) {
        _rangesCache[shop.osmUID] =
            cachedRange.rebuildWithoutProduct(product.barcode);
        if (cachedShop != null) {
          _shopsCache[shop.osmUID] = cachedShop.rebuildWith(
              productsCount: cachedShop.productsCount - 1);
        }
        _notifyListeners();
      }
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
