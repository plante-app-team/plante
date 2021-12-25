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
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_cacher.dart';
import 'package:plante/outside/map/osm/osm_overpass.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_large_local_cache_wrapper.dart';
import 'package:plante/outside/map/shops_manager_backend_worker.dart';
import 'package:plante/outside/map/shops_manager_fetch_shops_helper.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_obtainer.dart';

/// NOTE: this class is a total mess among with both
/// [ShopsManagerFetchShopsHelper] and [ShopsManagerBackendWorker].
/// They need a refactoring.
class ShopsManager {
  static const DAYS_BEFORE_PERSISTENT_CACHE_IS_OLD = 30;
  static const DAYS_BEFORE_PERSISTENT_CACHE_IS_ANCIENT = 90;
  final Analytics _analytics;
  final OsmCacher _osmCacher;
  late final ShopsManagerFetchShopsHelper _fetchShopsHelper;
  final _listeners = <ShopsManagerListener>[];
  final OpenStreetMap _osm;
  late final ShopsManagerBackendWorker _backendWorker;

  static const MAX_SHOPS_LOADS_ATTEMPTS = 2;
  // If new cache fields are added please update the [clearCache] method.
  final _slowCacheCompleter = Completer<ShopsLargeLocalCacheWrapper>();
  Future<ShopsLargeLocalCacheWrapper> get _slowCache =>
      _slowCacheCompleter.future;
  final _rangesCache = <OsmUID, ShopProductRange>{};
  final _loadedAreas = <CoordsBounds, List<OsmUID>>{};

  int get loadedAreasCount => _loadedAreas.length;

  ShopsManager(this._osm, Backend backend, ProductsObtainer productsObtainer,
      this._analytics, this._osmCacher)
      : _backendWorker = ShopsManagerBackendWorker(backend, productsObtainer) {
    _fetchShopsHelper =
        ShopsManagerFetchShopsHelper(_backendWorker, _osmCacher);
    _initAsync();
  }

  void _initAsync() async {
    _slowCacheCompleter.complete(await ShopsLargeLocalCacheWrapper.create());
  }

  Future<void> dispose() async {
    (await _slowCache).dispose();
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

  Future<Map<OsmUID, List<String>>> getBarcodesWithin(
      CoordsBounds bounds) async {
    return await (await _slowCache).getBarcodesWithin(bounds);
  }

  Future<Map<OsmUID, List<String>>> getBarcodesCacheFor(
      Iterable<OsmUID> uids) async {
    return await (await _slowCache).getBarcodes(uids);
  }

  Future<Map<OsmUID, Shop>> getCachedShopsFor(Iterable<OsmUID> uids) async {
    return await (await _slowCache).getShops(uids);
  }

  Future<bool> osmShopsCacheExistFor(CoordsBounds bounds) async {
    if (await _loadShopsFromCache(bounds) != null) {
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
    final existingCache = await _loadShopsFromCache(bounds);
    if (existingCache != null) {
      return Ok(existingCache);
    }
    return await _osm.withOverpass((overpass) async =>
        await _maybeLoadShops(overpass, bounds, attemptNumber: 1));
  }

  Future<Map<OsmUID, Shop>?> _loadShopsFromCache(CoordsBounds bounds) async {
    final slowCache = await _slowCache;
    for (final loadedArea in _loadedAreas.keys) {
      // Already loaded
      if (loadedArea.containsBounds(bounds)) {
        final ids = _loadedAreas[loadedArea]!;
        final shopsCache = await slowCache.getShops(ids);
        final shops =
            shopsCache.values.where((shop) => bounds.containsShop(shop));
        return {for (var shop in shops) shop.osmUID: shop};
      }
    }
    return null;
  }

  Future<Result<Map<OsmUID, Shop>, ShopsManagerError>> _maybeLoadShops(
      OsmOverpass overpass, CoordsBounds bounds,
      {required int attemptNumber}) async {
    final existingCache = await _loadShopsFromCache(bounds);
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

    final slowCache = await _slowCache;

    final fetchResult = shopsFetchResult.unwrap();
    _ensureAllShopsArePresentInOsmCache(fetchResult.shops.values);
    await slowCache.addShops(fetchResult.shops.values);
    await slowCache.addBarcodes(fetchResult.shopsBarcodes);
    final ids = fetchResult.shops.values.map((shop) => shop.osmUID).toList();
    _loadedAreas[fetchResult.shopsBounds] = ids;
    final result = ids
        .map((id) => fetchResult.shops[id]!)
        .where((shop) => bounds.containsShop(shop));
    _notifyListeners();
    return Ok({for (var shop in result) shop.osmUID: shop});
  }

  void _ensureAllShopsArePresentInOsmCache(Iterable<Shop> shops) async {
    for (final territory in await _osmCacher.getCachedShops()) {
      final territoryShopsUids =
          territory.entities.map((e) => e.osmUID).toSet();
      final shopsToInsert = <OsmUID, OsmShop>{};
      for (final shop in shops) {
        if (territory.bounds.containsShop(shop) &&
            !territoryShopsUids.contains(shop.osmUID)) {
          shopsToInsert[shop.osmUID] = shop.osmShop;
          unawaited(_osmCacher.addShopToCache(territory.id, shop.osmShop));
        }
      }
    }
  }

  Future<Result<Map<OsmUID, Shop>, ShopsManagerError>> inflateOsmShops(
      Iterable<OsmShop> shops) async {
    final slowCache = await _slowCache;

    final loadedShops = <OsmUID, Shop>{};
    final osmShopsToLoad = <OsmShop>[];
    final shopsCache = await slowCache.getShops(shops.map((e) => e.osmUID));
    for (final osmShop in shops) {
      final loadedShop = shopsCache[osmShop.osmUID];
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

      await slowCache.addShops(inflatedShops.values);
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
      final range = result.unwrap();
      _rangesCache[shop.osmUID] = range;
      final slowCache = await _slowCache;
      await slowCache.addBarcodes(
          {shop.osmUID: range.products.map((e) => e.barcode).toList()});
    }
    _notifyListeners();
    return result;
  }

  Future<Result<None, ShopsManagerError>> putProductToShops(
      Product product, List<Shop> shops, ProductAtShopSource source) async {
    final result =
        await _backendWorker.putProductToShops(product, shops, source);
    final eventParam = {
      'barcode': product.barcode,
      'shops': shops.map((e) => e.osmUID).join(', '),
    };
    if (result.isOk) {
      _analytics.sendEvent(
          _putProductToShopEventName(source, success: true), eventParam);
      final slowCache = await _slowCache;
      for (final shop in shops) {
        await slowCache.addBarcode(shop.osmUID, product.barcode);

        var rangeCache = _rangesCache[shop.osmUID];
        if (rangeCache != null) {
          final now = DateTime.now().secondsSinceEpoch;
          rangeCache = rangeCache.rebuild((e) => e
            ..products.add(product)
            ..productsLastSeenSecsUtc[product.barcode] = now);
          _rangesCache[shop.osmUID] = rangeCache;
        }

        var shopCache = await slowCache.getShop(shop.osmUID);
        if (shopCache != null) {
          shopCache =
              shopCache.rebuildWith(productsCount: shopCache.productsCount + 1);
          await slowCache.addShop(shopCache);
        } else {
          Log.w('A product is put into a shop while there '
              'was no cache for the shop. Shop: $shop');
        }
      }
      _notifyListeners();
    } else {
      _analytics.sendEvent(
          _putProductToShopEventName(source, success: false), eventParam);
    }
    return result;
  }

  String _putProductToShopEventName(ProductAtShopSource source,
      {required bool success}) {
    if (success) {
      switch (source) {
        case ProductAtShopSource.MANUAL:
          return 'product_put_to_shop';
        case ProductAtShopSource.OFF_SUGGESTION:
          return 'product_put_to_shop_off_suggestion';
        case ProductAtShopSource.RADIUS_SUGGESTION:
          return 'product_put_to_shop_radius_suggestion';
      }
    } else {
      switch (source) {
        case ProductAtShopSource.MANUAL:
          return 'product_put_to_shop_failure';
        case ProductAtShopSource.OFF_SUGGESTION:
          return 'product_put_to_shop_off_suggestion_failure';
        case ProductAtShopSource.RADIUS_SUGGESTION:
          return 'product_put_to_shop_radius_suggestion_failure';
      }
    }
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
      final slowCache = await _slowCache;
      await slowCache.addShop(shop);
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
      final slowCache = await _slowCache;
      final cachedRange = _rangesCache[shop.osmUID];
      final cachedShop = await slowCache.getShop(shop.osmUID);
      if (cachedShop == null) {
        Log.w('productPresenceVote: '
            'cachedShop is null - it is rare but possible');
      }
      if (cachedRange == null) {
        Log.e('Voting was done for a shop range which was not cached before');
        return result;
      }
      if (positive) {
        await slowCache.addBarcode(shop.osmUID, product.barcode);
        if (cachedShop != null &&
            !cachedRange.hasProductWith(product.barcode)) {
          await slowCache.addShop(cachedShop.rebuildWith(
              productsCount: cachedShop.productsCount + 1));
        }
        _rangesCache[shop.osmUID] = cachedRange.rebuildWithProduct(
            product, DateTime.now().secondsSinceEpoch);
        _notifyListeners();
      } else if (result.unwrap().productDeleted) {
        await slowCache.removeBarcode(shop.osmUID, product.barcode);
        _rangesCache[shop.osmUID] =
            cachedRange.rebuildWithoutProduct(product.barcode);
        if (cachedShop != null) {
          await slowCache.addShop(cachedShop.rebuildWith(
              productsCount: cachedShop.productsCount - 1));
        }
        _notifyListeners();
      }
    }
    return result;
  }

  Future<void> clearCache() async {
    await _fetchShopsHelper.clearCache();
    await (await _slowCache).clear();
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
