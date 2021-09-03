import 'package:plante/base/result.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/osm_cached_territory.dart';
import 'package:plante/outside/map/osm_cacher.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:sqflite_common/sqlite_api.dart';

class FakeOsmCacher implements OsmCacher {
  var _lastId = 0;
  final _cachedShops = <OsmCachedTerritory<OsmShop>>[];
  final _cachedRoads = <OsmCachedTerritory<OsmRoad>>[];

  @override
  Future<Database> get dbForTesting => throw UnimplementedError();

  @override
  Future<OsmCachedTerritory<OsmShop>> cacheShops(
      DateTime whenObtained, CoordsBounds bounds, List<OsmShop> shops) async {
    final result = OsmCachedTerritory(++_lastId, whenObtained, bounds, shops);
    _cachedShops.add(result);
    return result;
  }

  @override
  Future<void> deleteCachedTerritory(int territoryId) async {
    _cachedShops.removeWhere((e) => e.id == territoryId);
  }

  @override
  Future<List<OsmCachedTerritory<OsmShop>>> getCachedShops() async {
    return _cachedShops.toList(growable: false);
  }

  @override
  Future<Result<OsmCachedTerritory<OsmShop>, OsmCacherError>> addShopToCache(
      int territoryId, OsmShop shop) async {
    final territories = _cachedShops.where((e) => e.id == territoryId);
    if (territories.isEmpty) {
      return Err(OsmCacherError.TERRITORY_NOT_FOUND);
    }
    var territory = territories.first;
    _cachedShops.remove(territory);
    territory = territory.add(shop);
    _cachedShops.add(territory);
    return Ok(territory);
  }

  @override
  Future<OsmCachedTerritory<OsmRoad>> cacheRoads(DateTime whenObtained, CoordsBounds bounds, List<OsmRoad> roads) async {
    final result = OsmCachedTerritory(++_lastId, whenObtained, bounds, roads);
    _cachedRoads.add(result);
    return result;
  }

  @override
  Future<List<OsmCachedTerritory<OsmRoad>>> getCachedRoads() async {
    return _cachedRoads.toList(growable: false);
  }

  @override
  Future<Result<OsmCachedTerritory<OsmRoad>, OsmCacherError>> addRoadToCache(int territoryId, OsmRoad road) async {
    final territories = _cachedRoads.where((e) => e.id == territoryId);
    if (territories.isEmpty) {
      return Err(OsmCacherError.TERRITORY_NOT_FOUND);
    }
    var territory = territories.first;
    _cachedRoads.remove(territory);
    territory = territory.add(road);
    _cachedRoads.add(territory);
    return Ok(territory);
  }
}
