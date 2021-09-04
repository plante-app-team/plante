import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_cached_territory.dart';
import 'package:plante/outside/map/osm_cacher.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';
import 'package:plante/outside/map/osm_road.dart';

enum RoadsManagerError {
  NETWORK,
  OTHER,
}

class RoadsManager {
  // Let's assume new roads don't appear often
  static const DAYS_BEFORE_CACHE_ANCIENT = 365;
  // Let's not overload the DB with too many roads
  static const CACHED_TERRITORIES_LIMIT = 10;

  final OpenStreetMap _osm;
  final OsmCacher _cacher;
  final OsmInteractionsQueue _osmQueue;

  RoadsManager(this._osm, this._cacher, this._osmQueue);

  /// Fetches roads within the given bounds and nearby them if available.
  /// Given bounds must have sides smaller than 30km.
  Future<Result<List<OsmRoad>, RoadsManagerError>> fetchRoadsWithinAndNearby(
      CoordsBounds bounds) async {
    final territories = (await _cacher.getCachedRoads()).toList();
    territories.sort((lhs, rhs) =>
        rhs.whenObtained.millisecondsSinceEpoch -
        lhs.whenObtained.millisecondsSinceEpoch);
    _deleteExtras(territories);

    for (final territory in territories) {
      if (territory.bounds.containsBounds(bounds)) {
        return Ok(territory.entities);
      }
    }

    return _osmQueue.enqueue(() => _fetchRoadsImpl(bounds));
  }

  void _deleteExtras(List<OsmCachedTerritory<OsmRoad>> territories) {
    final deleted = <OsmCachedTerritory<OsmRoad>>{};

    for (var index = CACHED_TERRITORIES_LIMIT;
        index < territories.length;
        ++index) {
      final territory = territories[index];
      unawaited(_cacher.deleteCachedTerritory(territory.id));
      deleted.add(territory);
    }

    for (final territory in territories) {
      if (DAYS_BEFORE_CACHE_ANCIENT <
          DateTime.now().difference(territory.whenObtained).inDays) {
        unawaited(_cacher.deleteCachedTerritory(territory.id));
        deleted.add(territory);
      }
    }

    territories.removeWhere(deleted.contains);
  }

  Future<Result<List<OsmRoad>, RoadsManagerError>> _fetchRoadsImpl(
      CoordsBounds bounds) async {
    final result =
        await _osm.fetchRoads(bounds.center.makeSquare(_kmToGrad(30)));
    if (result.isOk) {
      final roads = result.unwrap();
      unawaited(_cacher.cacheRoads(DateTime.now(), bounds, roads));
      return Ok(roads);
    } else {
      return Err(_convertOsmErr(result.unwrapErr()));
    }
  }
}

double _kmToGrad(double km) {
  return km * 1 / 111;
}

RoadsManagerError _convertOsmErr(OpenStreetMapError error) {
  switch (error) {
    case OpenStreetMapError.NETWORK:
      return RoadsManagerError.NETWORK;
    case OpenStreetMapError.OTHER:
      return RoadsManagerError.OTHER;
  }
}
