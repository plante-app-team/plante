import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/fetched_shops.dart';
import 'package:plante/outside/map/osm_cached_territory.dart';
import 'package:plante/outside/map/osm_cacher.dart';
import 'package:plante/outside/map/osm_overpass.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_backend_worker.dart';
import 'package:plante/outside/map/shops_manager_types.dart';

// Extracted from ShopsManager logic of shops fetching
class ShopsManagerFetchShopsHelper {
  final ShopsManagerBackendWorker _shopsManagerBackendWorker;
  final OsmCacher _osmCacher;

  ShopsManagerFetchShopsHelper(
      this._shopsManagerBackendWorker, this._osmCacher);

  /// [osmBoundsSizesToRequest] - list of bounds sizes which will be requested
  /// from OSM servers if OSM cache is missing.
  /// [planteBoundsSizeToRequest] - bounds size for the Plante backend. Should
  /// be smaller than OSM bounds because the Plante backend is OK with
  /// many consequent requests and caching its results is not good since
  /// they might change rapidly.
  ///
  /// Bounds sizes are in kilometers.
  ///
  /// First size will be requested if cache is missing.
  /// Seconds size will be requested if first size request has failed.
  /// Third is the same as the second, and fourth, and so on.
  Future<Result<FetchedShops, ShopsManagerError>> fetchShops(
      OsmOverpass overpass,
      {required CoordsBounds viewPort,
      required List<double> osmBoundsSizesToRequest,
      required double planteBoundsSizeToRequest}) async {
    if (osmBoundsSizesToRequest.isEmpty) {
      throw ArgumentError('boundsSizesToRequest must not be empty');
    }
    if (osmBoundsSizesToRequest
        .where((e) => e < planteBoundsSizeToRequest)
        .isNotEmpty) {
      throw ArgumentError(
          'All requested OSM bounds must be greater than Plante bounds');
    }

    // NOTE: we intentionally search for OSM territory which contains
    // only [viewPort], not entire [planteShopsBounds].
    final osmCachedTerritory = await _obtainCachedOsmShops(viewPort);
    Result<FetchedShops, ShopsManagerError>? fetchResult;
    final planteShopsBounds =
        viewPort.center.makeSquare(kmToGrad(planteBoundsSizeToRequest));

    // At first let's try to use cached OSM territory
    if (osmCachedTerritory != null && !_isOld(osmCachedTerritory)) {
      fetchResult = await _shopsManagerBackendWorker.fetchShops(overpass,
          osmBounds: osmCachedTerritory.bounds,
          planteBounds: planteShopsBounds,
          preloadedOsmShops: osmCachedTerritory.entities);
      Log.i('OSM shops from cache are used');
      return fetchResult;
    }

    // If we're here, it means OSM cache doesn't exist or is old -
    // let's try to query both OSM and Plante servers
    CoordsBounds? osmBounds;
    for (final osmBoundsSize in osmBoundsSizesToRequest) {
      osmBounds = viewPort.center.makeSquare(kmToGrad(osmBoundsSize));
      fetchResult = await _shopsManagerBackendWorker.fetchShops(
        overpass,
        osmBounds: osmBounds,
        planteBounds: planteShopsBounds,
        preloadedOsmShops: null,
      );
      if (fetchResult.isOk) {
        _cacheOsmShops(fetchResult.unwrap());
        if (osmCachedTerritory != null && _isOld(osmCachedTerritory)) {
          // We just cached a fresh OSM territory so let's delete the old one
          _deleteOsmShopsCache(osmCachedTerritory);
        }
        return fetchResult;
      } else if (fetchResult.unwrapErr() !=
          ShopsManagerError.OSM_SERVERS_ERROR) {
        return fetchResult;
      }
    }

    // If we're here, that means we've faced OSM_SERVERS_ERROR.
    // Let's use cached territory even if it's old, or.. or return the error
    // if there's no cache.
    if (osmCachedTerritory != null) {
      fetchResult = await _shopsManagerBackendWorker.fetchShops(overpass,
          osmBounds: osmCachedTerritory.bounds,
          planteBounds: planteShopsBounds,
          preloadedOsmShops: osmCachedTerritory.entities);
      Log.i('OSM shops from old cache are used');
      return fetchResult;
    }
    return fetchResult!;
  }

  Future<OsmCachedTerritory<OsmShop>?> _obtainCachedOsmShops(
      CoordsBounds bounds) async {
    final cachedTerritories = await _osmCacher.getCachedShops();
    for (final cachedTerritory in cachedTerritories) {
      if (_isAncient(cachedTerritory)) {
        _deleteOsmShopsCache(cachedTerritory);
        continue;
      }
      if (cachedTerritory.bounds.containsBounds(bounds)) {
        return cachedTerritory;
      }
    }
    return null;
  }

  void _cacheOsmShops(FetchedShops fetchedShops) async {
    await _osmCacher.cacheShops(DateTime.now(), fetchedShops.osmShopsBounds,
        fetchedShops.osmShops.values.toList());
  }

  void _deleteOsmShopsCache(
      OsmCachedTerritory<OsmShop> osmCachedTerritory) async {
    await _osmCacher.deleteCachedTerritory(osmCachedTerritory.id);
  }

  bool _isOld(OsmCachedTerritory territory) {
    return ShopsManager.DAYS_BEFORE_PERSISTENT_CACHE_IS_OLD <
        DateTime.now().difference(territory.whenObtained).inDays;
  }

  bool _isAncient(OsmCachedTerritory territory) {
    return ShopsManager.DAYS_BEFORE_PERSISTENT_CACHE_IS_ANCIENT <
        DateTime.now().difference(territory.whenObtained).inDays;
  }

  Future<void> clearCache() async {
    for (final territory in await _osmCacher.getCachedShops()) {
      await _osmCacher.deleteCachedTerritory(territory.id);
    }
  }
}
