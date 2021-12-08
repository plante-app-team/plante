import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/database_base.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/sqlite/sqlite.dart';
import 'package:sqflite/sqlite_api.dart';

const _ID = 'id';

const _PRODUCT_AT_SHOP_PROPERTY_TABLE = 'product_at_shop_property';
const _PRODUCT_AT_SHOP_PROPERTY_WHEN_SET = 'when_set';
const _PRODUCT_AT_SHOP_PROPERTY_TYPE_CODE = 'type_code';
const _PRODUCT_AT_SHOP_PROPERTY_SHOP_UID = 'shop_uid';
const _PRODUCT_AT_SHOP_PROPERTY_BARCODE = 'barcode';
const _PRODUCT_AT_SHOP_PROPERTY_PROPERTY_INT_VAL = 'property_int_val';

class MapExtraPropertiesCacher extends DatabaseBase {
  final _dbCompleter = Completer<Database>();
  Future<Database> get _db => _dbCompleter.future;

  Future<Database> get dbForTesting {
    if (!isInTests()) {
      throw Error();
    }
    return _db;
  }

  MapExtraPropertiesCacher() {
    _initAsync();
  }

  MapExtraPropertiesCacher.withDb(Database db) {
    _initAsync(db);
  }

  @override
  Future<String> dbFilePath() async {
    final appDir = await getAppDir();
    return '${appDir.path}/map_extra_properties_cache.sqlite';
  }

  void _initAsync([Database? db]) async {
    Log.i('MapExtraPropertiesCacher._initAsync start');
    db ??=
        await openDB(await dbFilePath(), version: 1, onUpgrade: _onUpgradeDb);
    _dbCompleter.complete(db);
    Log.i('MapExtraPropertiesCacher._initAsync finish');
  }

  Future<void> _onUpgradeDb(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      if (oldVersion < 1) {
        const productTable = _PRODUCT_AT_SHOP_PROPERTY_TABLE;
        await txn.execute('''CREATE TABLE $productTable(
          $_ID INTEGER PRIMARY KEY,
          $_PRODUCT_AT_SHOP_PROPERTY_WHEN_SET INTEGER,
          $_PRODUCT_AT_SHOP_PROPERTY_TYPE_CODE INTEGER,
          $_PRODUCT_AT_SHOP_PROPERTY_SHOP_UID TEXT,
          $_PRODUCT_AT_SHOP_PROPERTY_BARCODE TEXT,
          $_PRODUCT_AT_SHOP_PROPERTY_PROPERTY_INT_VAL INTEGER);
        ''');
        await txn.execute('''CREATE INDEX index_${productTable}_property_id
          ON $productTable($_PRODUCT_AT_SHOP_PROPERTY_TYPE_CODE);
        ''');
        await txn.execute('''CREATE INDEX index_${productTable}_shop_uid
          ON $productTable($_PRODUCT_AT_SHOP_PROPERTY_SHOP_UID);
        ''');
        await txn.execute('''CREATE INDEX index_${productTable}_barcode
          ON $productTable($_PRODUCT_AT_SHOP_PROPERTY_BARCODE);
        ''');
      }
    });
  }

  /// NOTE: old cache for a shops will be deleted
  Future<void> setProductAtShopProperty(
      ProductAtShopExtraProperty property) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _deleteProperty(
          txn, property.type, property.osmUID, property.barcode);

      if (property.intVal != null) {
        await txn.insert(_PRODUCT_AT_SHOP_PROPERTY_TABLE, {
          _PRODUCT_AT_SHOP_PROPERTY_WHEN_SET: property.whenSetSecsSinceEpoch,
          _PRODUCT_AT_SHOP_PROPERTY_TYPE_CODE: property.typeCode,
          _PRODUCT_AT_SHOP_PROPERTY_SHOP_UID: property.osmUID.toString(),
          _PRODUCT_AT_SHOP_PROPERTY_BARCODE: property.barcode,
          _PRODUCT_AT_SHOP_PROPERTY_PROPERTY_INT_VAL: property.intVal,
        });
      }
    });
  }

  Future<void> _deleteProperty(
      Transaction txn,
      ProductAtShopExtraPropertyType type,
      OsmUID shopUID,
      String barcode) async {
    await txn.delete(_PRODUCT_AT_SHOP_PROPERTY_TABLE,
        where: '$_PRODUCT_AT_SHOP_PROPERTY_TYPE_CODE = ? AND '
            '$_PRODUCT_AT_SHOP_PROPERTY_SHOP_UID = ? AND '
            '$_PRODUCT_AT_SHOP_PROPERTY_BARCODE = ?',
        whereArgs: [type.persistentCode, shopUID.toString(), barcode]);
  }

  Future<void> deleteProductAtShopProperty(ProductAtShopExtraPropertyType type,
      OsmUID shopUID, String barcode) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _deleteProperty(txn, type, shopUID, barcode);
    });
  }

  Future<List<ProductAtShopExtraProperty>> getProductsAtShopProperties(
      OsmUID shopUID) async {
    final db = await _db;
    return await db.transaction((txn) async {
      final propertiesData = await txn.query(_PRODUCT_AT_SHOP_PROPERTY_TABLE,
          where: '$_PRODUCT_AT_SHOP_PROPERTY_SHOP_UID = ?',
          whereArgs: [shopUID.toString()]);
      return _extractProductAtShopProperties(propertiesData);
    });
  }

  Future<List<ProductAtShopExtraProperty>>
      getAllProductsAtShopProperties() async {
    final db = await _db;
    return await db.transaction((txn) async {
      final propertiesData = await txn.query(_PRODUCT_AT_SHOP_PROPERTY_TABLE);
      return _extractProductAtShopProperties(propertiesData);
    });
  }

  List<ProductAtShopExtraProperty> _extractProductAtShopProperties(
      List<Map<String, Object?>> propertiesData) {
    final result = <ProductAtShopExtraProperty>[];
    for (final data in propertiesData) {
      final whenSet = data[_PRODUCT_AT_SHOP_PROPERTY_WHEN_SET] as int?;
      final typeCode = data[_PRODUCT_AT_SHOP_PROPERTY_TYPE_CODE] as int?;
      final barcode = data[_PRODUCT_AT_SHOP_PROPERTY_BARCODE] as String?;
      final intVal = data[_PRODUCT_AT_SHOP_PROPERTY_PROPERTY_INT_VAL] as int?;
      final osmUIDStr = data[_PRODUCT_AT_SHOP_PROPERTY_SHOP_UID] as String?;
      final osmUID = OsmUID.parseSafe(osmUIDStr ?? '');

      if (whenSet == null ||
          typeCode == null ||
          barcode == null ||
          osmUID == null) {
        Log.w('Invalid $_PRODUCT_AT_SHOP_PROPERTY_TABLE column $data');
        continue;
      }

      result.add(ProductAtShopExtraProperty.create(
          type: createProductAtShopExtraPropertyTypeFromCode(typeCode),
          whenSet: dateTimeFromSecondsSinceEpoch(whenSet),
          barcode: barcode,
          osmUID: osmUID,
          intVal: intVal));
    }
    return result;
  }
}
