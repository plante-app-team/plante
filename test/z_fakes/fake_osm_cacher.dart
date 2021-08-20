import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/osm_cached_territory.dart';
import 'package:plante/outside/map/osm_cacher.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:sqflite_common/sqlite_api.dart';

class FakeOsmCacher implements OsmCacher {
  var _lastId = 0;
  final _cachedShops = <OsmCachedTerritory<OsmShop>>[];

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
  Future<void> deleteCachedShops(int territoryId) async {
    _cachedShops.removeWhere((e) => e.id == territoryId);
  }

  @override
  Future<List<OsmCachedTerritory<OsmShop>>> getCachedShops() async {
    return _cachedShops.toList(growable: false);
  }
}
