import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/database_base.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/osm/osm_cached_territory.dart';
import 'package:plante/outside/map/osm/osm_road.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/sqlite/sqlite.dart';
import 'package:sqflite/sqlite_api.dart';

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
const _SHOP_CITY = 'city';
const _SHOP_ROAD = 'road';
const _SHOP_HOUSE_NUMBER = 'house_number';

const _ROAD_TABLE = 'road';
const _ROAD_TERRITORY_ID = 'territory_id';
const _ROAD_OSM_ID = 'osm_id';
const _ROAD_NAME = 'name';
const _ROAD_LAT = 'lat';
const _ROAD_LON = 'lon';

// Just a random number because I don't know what number work better.
const _BATCH_SIZE = 1000;

enum OsmCacherError {
  TERRITORY_NOT_FOUND,
}

class OsmCacher extends DatabaseBase {
  final _dbCompleter = Completer<Database>();
  Future<Database> get _db => _dbCompleter.future;

  final List<OsmCachedTerritory<OsmShop>> _cachedShops = [];
  final List<OsmCachedTerritory<OsmRoad>> _cachedRoads = [];

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

  @override
  Future<String> dbFilePath() async {
    final appDir = await getAppDir();
    return '${appDir.path}/osm_cache.sqlite';
  }

  void _initAsync([Database? db]) async {
    Log.i('OsmCacher._initAsync start');
    db ??=
        await openDB(await dbFilePath(), version: 4, onUpgrade: _onUpgradeDb);
    Log.i('OsmCacher._initAsync db loaded');

    final shopsAndTerritoriesIds = await _extractShopsWithTerritoriesIds(db);
    final roadsAndTerritoriesIds = await _extractRoadsWithTerritoriesIds(db);
    final emptyTerritories = await _extractTerritories(db);

    Log.i('OsmCacher._initAsync territories loaded');
    for (final territory in emptyTerritories) {
      final shops = shopsAndTerritoriesIds[territory.id];
      if (shops != null) {
        _cachedShops.add(territory.rebuildWith(shops));
      }
      final roads = roadsAndTerritoriesIds[territory.id];
      if (roads != null) {
        _cachedRoads.add(territory.rebuildWith(roads));
      }
    }

    _dbCompleter.complete(db);
    Log.i('OsmCacher._initAsync finish');
  }

  Future<List<OsmCachedTerritory<None>>> _extractTerritories(
      Database db) async {
    final emptyTerritories = <OsmCachedTerritory<None>>[];

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
        final territory = OsmCachedTerritory<None>(
            territoryId,
            whenObtainedDate,
            CoordsBounds(
                southwest: Coord(lat: southwestLat, lon: southwestLon),
                northeast: Coord(lat: northeastLat, lon: northeastLon)),
            const []);
        emptyTerritories.add(territory);
      }
    }
    return emptyTerritories;
  }

  Future<void> _onUpgradeDb(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      if (oldVersion < 1) {
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
      }

      if (oldVersion < 2) {
        await txn.execute('''CREATE TABLE $_ROAD_TABLE(
          $_ID INTEGER PRIMARY KEY,
          $_ROAD_TERRITORY_ID INTEGER,
          $_ROAD_OSM_ID TEXT,
          $_ROAD_NAME TEXT,
          $_ROAD_LAT REAL,
          $_ROAD_LON REAL);
        ''');
        await txn.execute('''CREATE INDEX index_road_territory
          ON $_ROAD_TABLE($_ROAD_TERRITORY_ID);
        ''');
      }

      if (oldVersion < 3) {
        await txn.execute(
            "ALTER TABLE $_SHOP_TABLE ADD COLUMN $_SHOP_CITY TEXT DEFAULT ''");
        await txn.execute(
            "ALTER TABLE $_SHOP_TABLE ADD COLUMN $_SHOP_ROAD TEXT DEFAULT ''");
        await txn.execute(
            "ALTER TABLE $_SHOP_TABLE ADD COLUMN $_SHOP_HOUSE_NUMBER TEXT DEFAULT ''");
      }

      if (oldVersion < 4) {
        // Deleting all stored shops because osmId is replaced with OsmUID
        await txn.delete(_SHOP_TABLE);
      }
    });
  }

  Future<Map<int, List<OsmShop>>> _extractShopsWithTerritoriesIds(
      Database db) async {
    Log.i('OsmCacher shops extraction start');
    final shopsAndTerritoriesIds = <int, List<OsmShop>>{};
    for (var offset = 0; true; offset += _BATCH_SIZE) {
      final batch =
          await db.query(_SHOP_TABLE, limit: _BATCH_SIZE, offset: offset);
      if (batch.isEmpty) {
        break;
      }
      for (final column in batch) {
        final territoryId = column[_SHOP_TERRITORY_ID] as int?;
        final osmUID = column[_SHOP_OSM_ID] as String?;
        final name = column[_SHOP_NAME] as String?;
        final type = _strColumnToNullableStr(column, _SHOP_TYPE);
        final city = _strColumnToNullableStr(column, _SHOP_CITY);
        final road = _strColumnToNullableStr(column, _SHOP_ROAD);
        final houseNumber = _strColumnToNullableStr(column, _SHOP_HOUSE_NUMBER);
        final lat = column[_SHOP_LAT] as double?;
        final lon = column[_SHOP_LON] as double?;
        if (territoryId == null ||
            osmUID == null ||
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
          ..osmUID = OsmUID.parse(osmUID)
          ..name = name
          ..type = type
          ..latitude = lat
          ..longitude = lon
          ..city = city
          ..road = road
          ..houseNumber = houseNumber));
      }
    }
    final territoriesCount = shopsAndTerritoriesIds.length;
    final shopsCount = shopsAndTerritoriesIds.values
        .fold<int>(0, (prev, e) => prev + e.length);
    Log.i(
        'OsmCacher shops extraction finish, territories: $territoriesCount, shops: $shopsCount');
    return shopsAndTerritoriesIds;
  }

  String? _strColumnToNullableStr(Map<String, dynamic> column, String name) {
    final str = column[name] as String?;
    if (str != null && str.isNotEmpty) {
      return str;
    }
    return null;
  }

  Future<Map<int, List<OsmRoad>>> _extractRoadsWithTerritoriesIds(
      Database db) async {
    Log.i('OsmCacher roads extraction start');
    final roadsAndTerritoriesIds = <int, List<OsmRoad>>{};
    for (var offset = 0; true; offset += _BATCH_SIZE) {
      final batch =
          await db.query(_ROAD_TABLE, limit: _BATCH_SIZE, offset: offset);
      if (batch.isEmpty) {
        break;
      }
      for (final column in batch) {
        final territoryId = column[_ROAD_TERRITORY_ID] as int?;
        final osmId = column[_ROAD_OSM_ID] as String?;
        final name = column[_ROAD_NAME] as String?;
        final lat = column[_ROAD_LAT] as double?;
        final lon = column[_ROAD_LON] as double?;
        if (territoryId == null ||
            osmId == null ||
            name == null ||
            lat == null ||
            lon == null) {
          Log.w('Invalid $_ROAD_TABLE column $column');
          continue;
        }
        if (!roadsAndTerritoriesIds.containsKey(territoryId)) {
          roadsAndTerritoriesIds[territoryId] = [];
        }
        roadsAndTerritoriesIds[territoryId]!.add(OsmRoad((e) => e
          ..osmId = osmId
          ..name = name
          ..latitude = lat
          ..longitude = lon));
      }
    }
    final territoriesCount = roadsAndTerritoriesIds.length;
    final roadsCount = roadsAndTerritoriesIds.values
        .fold<int>(0, (prev, e) => prev + e.length);
    Log.i(
        'OsmCacher roads extraction finish, territories: $territoriesCount, roads: $roadsCount');
    return roadsAndTerritoriesIds;
  }

  Future<OsmCachedTerritory<OsmShop>> cacheShops(DateTime whenObtained,
      CoordsBounds bounds, Iterable<OsmShop> shops) async {
    return await _cacheTerritory(_SHOP_TABLE, whenObtained, bounds, shops,
        _shopColumnsValues, _cachedShops);
  }

  Future<OsmCachedTerritory<T>> _cacheTerritory<T>(
      String table,
      DateTime whenObtained,
      CoordsBounds bounds,
      Iterable<T> entities,
      _TerritoriedEntityColumnValues<T> columnsValues,
      List<OsmCachedTerritory<T>> entitiesLocalCache) async {
    final entitiesCopy = entities.toList();
    final db = await _db;
    return await db.transaction((txn) async {
      final territoryId = await txn.insert(
          _TERRITORY_TABLE, _territoryValues(whenObtained, bounds));
      for (final entity in entitiesCopy) {
        await txn.insert(table, columnsValues(territoryId, entity));
      }
      final cache = OsmCachedTerritory(
        territoryId,
        whenObtained,
        bounds,
        entitiesCopy,
      );
      entitiesLocalCache.add(cache);
      return cache;
    });
  }

  Future<List<OsmCachedTerritory<OsmShop>>> getCachedShops() async {
    await _db;
    return _cachedShops.toList(growable: false);
  }

  Future<void> deleteCachedTerritory(int territoryId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.execute('''DELETE FROM $_SHOP_TABLE
          WHERE $_SHOP_TERRITORY_ID = $territoryId;''');
      await txn.execute('''DELETE FROM $_ROAD_TABLE
          WHERE $_ROAD_TERRITORY_ID = $territoryId;''');
      await txn.execute('''DELETE FROM $_TERRITORY_TABLE
          WHERE $_ID = $territoryId;''');
    });
    _cachedShops.removeWhere((territory) => territory.id == territoryId);
    _cachedRoads.removeWhere((territory) => territory.id == territoryId);
  }

  Future<Result<OsmCachedTerritory<OsmShop>, OsmCacherError>> addShopToCache(
      int territoryId, OsmShop shop) async {
    return await _addEntityToCache(
        _SHOP_TABLE, territoryId, shop, _cachedShops, _shopColumnsValues);
  }

  Future<Result<OsmCachedTerritory<T>, OsmCacherError>> _addEntityToCache<T>(
      String table,
      int territoryId,
      T entity,
      List<OsmCachedTerritory<T>> entitiesLocalCache,
      _TerritoriedEntityColumnValues<T> columnsValues) async {
    final territories = entitiesLocalCache.where((e) => e.id == territoryId);
    if (territories.isEmpty) {
      return Err(OsmCacherError.TERRITORY_NOT_FOUND);
    }
    // Update local cache
    var territory = territories.first;
    entitiesLocalCache.remove(territory);
    territory = territory.add(entity);
    entitiesLocalCache.add(territory);

    // Update persistent cache
    final db = await _db;
    await db.insert(table, columnsValues(territoryId, entity));
    return Ok(territory);
  }

  Future<OsmCachedTerritory<OsmRoad>> cacheRoads(
      DateTime whenObtained, CoordsBounds bounds, List<OsmRoad> roads) async {
    return await _cacheTerritory(_ROAD_TABLE, whenObtained, bounds, roads,
        _roadColumnsValues, _cachedRoads);
  }

  Future<List<OsmCachedTerritory<OsmRoad>>> getCachedRoads() async {
    await _db;
    return _cachedRoads.toList(growable: false);
  }

  Future<Result<OsmCachedTerritory<OsmRoad>, OsmCacherError>> addRoadToCache(
      int territoryId, OsmRoad road) async {
    return await _addEntityToCache(
        _ROAD_TABLE, territoryId, road, _cachedRoads, _roadColumnsValues);
  }
}

typedef _TerritoriedEntityColumnValues<T> = Map<String, dynamic> Function(
    int territoryId, T entity);

Map<String, dynamic> _territoryValues(
    DateTime whenObtained, CoordsBounds bounds) {
  return {
    _TERRITORY_WHEN_OBTAINED: whenObtained.secondsSinceEpoch,
    _TERRITORY_NORTHEAST_LAT: bounds.northeast.lat,
    _TERRITORY_NORTHEAST_LON: bounds.northeast.lon,
    _TERRITORY_SOUTHWEST_LAT: bounds.southwest.lat,
    _TERRITORY_SOUTHWEST_LON: bounds.southwest.lon,
  };
}

Map<String, dynamic> _shopColumnsValues(int territoryId, OsmShop shop) {
  return {
    _SHOP_TERRITORY_ID: territoryId,
    _SHOP_OSM_ID: shop.osmUID.toString(),
    _SHOP_NAME: shop.name,
    _SHOP_TYPE: shop.type ?? '',
    _SHOP_LAT: shop.latitude,
    _SHOP_LON: shop.longitude,
    _SHOP_CITY: shop.city ?? '',
    _SHOP_ROAD: shop.road ?? '',
    _SHOP_HOUSE_NUMBER: shop.houseNumber ?? '',
  };
}

Map<String, dynamic> _roadColumnsValues(int territoryId, OsmRoad road) {
  return {
    _ROAD_TERRITORY_ID: territoryId,
    _ROAD_OSM_ID: road.osmId,
    _ROAD_NAME: road.name,
    _ROAD_LAT: road.latitude,
    _ROAD_LON: road.longitude,
  };
}
