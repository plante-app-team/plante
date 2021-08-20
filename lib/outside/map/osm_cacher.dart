import 'dart:async';

import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:sqflite/sqlite_api.dart';

import 'package:plante/base/base.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/outside/map/osm_cached_territory.dart';
import 'package:plante/sqlite/sqlite.dart';

const _ID = 'id';
const _TERRITORY_TABLE = 'territory';
const _TERRITORY_WHEN_OBTAINED = 'when_obtained';
const _TERRITORY_SOUTHWEST_LAT = 'southwest_lat';
const _TERRITORY_SOUTHWEST_LON = 'southwest_lon';
const _TERRITORY_NORTHEAST_LAT = 'northeast_lat';
const _TERRITORY_NORTHEAST_LON = 'northeast_lon';
const _SHOP_TABLE = 'shop';
const _SHOP_TERRITORY_ID = 'territory_id';
const _SHOP_OSM_ID = 'osm_id';
const _SHOP_NAME = 'name';
const _SHOP_TYPE = 'type';
const _SHOP_LAT = 'lat';
const _SHOP_LON = 'lon';

// Just a random number because I don't know what number work better.
const _BATCH_SIZE = 200;

class OsmCacher {
  final _dbCompleter = Completer<Database>();
  Future<Database> get _db => _dbCompleter.future;

  final List<OsmCachedTerritory<OsmShop>> _cachedShops = [];

  Future<Database> get dbForTesting {
    if (!isInTests()) {
      throw Error();
    }
    return _db;
  }

  OsmCacher() {
    _initAsync();
  }

  OsmCacher.withDb(Database db) {
    _initAsync(db);
  }

  void _initAsync([Database? db]) async {
    if (db == null) {
      final appDir = await getAppDir();
      db = await openDB('${appDir.path}/osm_cache.sqlite',
          version: 1, onUpgrade: _onUpgradeDb);
    }

    final shopsAndTerritoriesIds = <int, List<OsmShop>>{};
    for (var offset = 0; true; offset += _BATCH_SIZE) {
      final batch =
          await db.query(_SHOP_TABLE, limit: _BATCH_SIZE, offset: offset);
      if (batch.isEmpty) {
        break;
      }
      for (final column in batch) {
        final territoryId = column[_SHOP_TERRITORY_ID] as int?;
        final osmId = column[_SHOP_OSM_ID] as String?;
        final name = column[_SHOP_NAME] as String?;
        var type = column[_SHOP_TYPE] as String?;
        if (type != null && type.isEmpty) {
          type = null;
        }
        final lat = column[_SHOP_LAT] as double?;
        final lon = column[_SHOP_LON] as double?;
        if (territoryId == null ||
            osmId == null ||
            name == null ||
            lat == null ||
            lon == null) {
          Log.w('Invalid $_SHOP_TABLE column $column');
          continue;
        }
        if (!shopsAndTerritoriesIds.containsKey(territoryId)) {
          shopsAndTerritoriesIds[territoryId] = [];
        }
        shopsAndTerritoriesIds[territoryId]!.add(OsmShop((e) => e
          ..osmId = osmId
          ..name = name
          ..type = type
          ..latitude = lat
          ..longitude = lon));
      }
    }

    for (var offset = 0; true; offset += _BATCH_SIZE) {
      final batch =
          await db.query(_TERRITORY_TABLE, limit: _BATCH_SIZE, offset: offset);
      if (batch.isEmpty) {
        break;
      }
      for (final column in batch) {
        final territoryId = column[_ID] as int?;
        final whenObtained = column[_TERRITORY_WHEN_OBTAINED] as int?;
        final northeastLat = column[_TERRITORY_NORTHEAST_LAT] as double?;
        final northeastLon = column[_TERRITORY_NORTHEAST_LON] as double?;
        final southwestLat = column[_TERRITORY_SOUTHWEST_LAT] as double?;
        final southwestLon = column[_TERRITORY_SOUTHWEST_LON] as double?;
        if (territoryId == null ||
            whenObtained == null ||
            northeastLat == null ||
            northeastLon == null ||
            southwestLat == null ||
            southwestLon == null) {
          Log.w('Invalid $_TERRITORY_TABLE column $column');
          continue;
        }
        final whenObtainedDate = dateTimeFromSecondsSinceEpoch(whenObtained);
        final territory = OsmCachedTerritory<OsmShop>(
            territoryId,
            whenObtainedDate,
            CoordsBounds(
                southwest: Coord(lat: southwestLat, lon: southwestLon),
                northeast: Coord(lat: northeastLat, lon: northeastLon)),
            shopsAndTerritoriesIds[territoryId] ?? []);
        _cachedShops.add(territory);
      }
    }

    _dbCompleter.complete(db);
  }

  Future<void> _onUpgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await db.transaction((txn) async {
        await txn.execute('''CREATE TABLE $_TERRITORY_TABLE(
        $_ID INTEGER PRIMARY KEY,
        $_TERRITORY_WHEN_OBTAINED INTEGER,
        $_TERRITORY_NORTHEAST_LAT REAL,
        $_TERRITORY_NORTHEAST_LON REAL,
        $_TERRITORY_SOUTHWEST_LAT REAL,
        $_TERRITORY_SOUTHWEST_LON REAL);
      ''');
        await txn.execute('''CREATE TABLE $_SHOP_TABLE(
        $_ID INTEGER PRIMARY KEY,
        $_SHOP_TERRITORY_ID INTEGER,
        $_SHOP_OSM_ID TEXT,
        $_SHOP_NAME TEXT,
        $_SHOP_TYPE TEXT,
        $_SHOP_LAT REAL,
        $_SHOP_LON REAL);
      ''');
        await txn.execute('''CREATE INDEX index_shop_territory
        ON $_SHOP_TABLE($_SHOP_TERRITORY_ID);
      ''');
      });
    }
  }

  Future<OsmCachedTerritory<OsmShop>> cacheShops(
      DateTime whenObtained, CoordsBounds bounds, List<OsmShop> shops) async {
    final db = await _db;
    return await db.transaction((txn) async {
      final territoryValues = {
        _TERRITORY_WHEN_OBTAINED: whenObtained.secondsSinceEpoch,
        _TERRITORY_NORTHEAST_LAT: bounds.northeast.lat,
        _TERRITORY_NORTHEAST_LON: bounds.northeast.lon,
        _TERRITORY_SOUTHWEST_LAT: bounds.southwest.lat,
        _TERRITORY_SOUTHWEST_LON: bounds.southwest.lon,
      };
      final territoryId = await txn.insert(_TERRITORY_TABLE, territoryValues);
      for (final shop in shops) {
        await txn.insert(_SHOP_TABLE, shop.columnsValues(territoryId));
      }
      final cache = OsmCachedTerritory(
        territoryId,
        whenObtained,
        bounds,
        shops,
      );
      _cachedShops.add(cache);
      return cache;
    });
  }

  Future<List<OsmCachedTerritory<OsmShop>>> getCachedShops() async {
    await _db;
    return _cachedShops;
  }

  Future<void> deleteCachedShops(int territoryId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.execute('''DELETE FROM $_SHOP_TABLE
          WHERE $_SHOP_TERRITORY_ID = $territoryId;''');
      await txn.execute('''DELETE FROM $_TERRITORY_TABLE
          WHERE $_ID = $territoryId;''');
    });
    _cachedShops.removeWhere((territory) => territory.id == territoryId);
  }
}

extension _ShopExt on OsmShop {
  Map<String, dynamic> columnsValues(int territoryId) {
    return {
      _SHOP_TERRITORY_ID: territoryId,
      _SHOP_OSM_ID: osmId,
      _SHOP_NAME: name,
      _SHOP_TYPE: type ?? '',
      _SHOP_LAT: latitude,
      _SHOP_LON: longitude,
    };
  }
}
