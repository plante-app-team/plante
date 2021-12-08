import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/database_base.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/sqlite/sqlite.dart';
import 'package:sqflite/sqlite_api.dart';

const _ID = 'id';

const _SHOP_TABLE = 'shop';
const _SHOP_WHEN_OBTAINED = 'when_obtained';
const _SHOP_OFF_ID = 'off_shop_id';
const _SHOP_COUNTRY_CODE = 'country_code';

const _BARCODE_AT_SHOP_TABLE = 'barcode_at_shop';
const _BARCODE_AT_SHOP_SHOP_ID = 'shop_id';
const _BARCODE_AT_SHOP_BARCODE = 'barcode';

@immutable
class BarcodesAtShop {
  final String shopId;
  final String countryCode;
  final DateTime whenObtained;
  final List<String> barcodes;
  const BarcodesAtShop(
      this.shopId, this.countryCode, this.whenObtained, this.barcodes);
}

class OffCacher extends DatabaseBase {
  final _dbCompleter = Completer<Database>();
  Future<Database> get _db => _dbCompleter.future;

  Future<Database> get dbForTesting {
    if (!isInTests()) {
      throw Error();
    }
    return _db;
  }

  OffCacher() {
    _initAsync();
  }

  OffCacher.withDb(Database db) {
    _initAsync(db);
  }

  @override
  Future<String> dbFilePath() async {
    final appDir = await getAppDir();
    return '${appDir.path}/off_cache.sqlite';
  }

  void _initAsync([Database? db]) async {
    Log.i('OffCacher._initAsync start');
    db ??=
        await openDB(await dbFilePath(), version: 1, onUpgrade: _onUpgradeDb);
    _dbCompleter.complete(db);
    Log.i('OffCacher._initAsync finish');
  }

  Future<void> _onUpgradeDb(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      if (oldVersion < 1) {
        await txn.execute('''CREATE TABLE $_SHOP_TABLE(
          $_ID INTEGER PRIMARY KEY,
          $_SHOP_OFF_ID TEXT,
          $_SHOP_WHEN_OBTAINED INTEGER,
          $_SHOP_COUNTRY_CODE TEXT);
        ''');
        await txn.execute('''CREATE INDEX index_shop_off_id
          ON $_SHOP_TABLE($_SHOP_OFF_ID);
        ''');
        await txn.execute('''CREATE INDEX index_shop_country
          ON $_SHOP_TABLE($_SHOP_COUNTRY_CODE);
        ''');

        await txn.execute('''CREATE TABLE $_BARCODE_AT_SHOP_TABLE(
          $_ID INTEGER PRIMARY KEY,
          $_BARCODE_AT_SHOP_SHOP_ID INTEGER,
          $_BARCODE_AT_SHOP_BARCODE TEXT,
          FOREIGN KEY ($_BARCODE_AT_SHOP_SHOP_ID) REFERENCES $_SHOP_OFF_ID ($_ID)
          );
        ''');
        await txn.execute('''CREATE INDEX index_barcode_at_shop_shop_id
          ON $_BARCODE_AT_SHOP_TABLE($_BARCODE_AT_SHOP_SHOP_ID);
        ''');
      }
    });
  }

  Future<void> deleteShopsCache(
      List<String> offShopsIds, String countryCode) async {
    final db = await _db;
    await db.transaction((txn) async {
      final ids = await _idsOf(offShopsIds, countryCode, txn);
      if (ids.isEmpty) {
        return;
      }
      final idsStr = ids.join(',');
      await txn.execute('''DELETE FROM $_BARCODE_AT_SHOP_TABLE
          WHERE $_BARCODE_AT_SHOP_SHOP_ID IN ($idsStr);''');
      await txn.execute('''DELETE FROM $_SHOP_TABLE
          WHERE $_ID IN ($idsStr);''');
    });
  }

  Future<List<int>> _idsOf(
      List<String> offShopsIds, String countryCode, Transaction txn) async {
    final shopsIdsQuestionsStr = offShopsIds.map((e) => '?').join(',');
    final queried = await txn.query(_SHOP_TABLE,
        columns: [_ID],
        where:
            '$_SHOP_COUNTRY_CODE = ? AND $_SHOP_OFF_ID in ($shopsIdsQuestionsStr)',
        whereArgs: [countryCode] + offShopsIds);
    final result = <int>[];
    for (final column in queried) {
      final id = column[_ID] as int?;
      if (id == null) {
        Log.e('Invalid $_SHOP_TABLE - no ID');
        continue;
      }
      result.add(id);
    }
    return result;
  }

  /// NOTE: old cache for a shops will be deleted
  Future<void> setBarcodes(DateTime whenObtained, String countryCode,
      String shopId, Iterable<String> barcodes) async {
    await deleteShopsCache([shopId], countryCode);

    final db = await _db;
    await db.transaction((txn) async {
      final id = await txn.insert(_SHOP_TABLE, {
        _SHOP_WHEN_OBTAINED: whenObtained.secondsSinceEpoch,
        _SHOP_OFF_ID: shopId,
        _SHOP_COUNTRY_CODE: countryCode,
      });
      for (final barcode in barcodes) {
        await txn.insert(_BARCODE_AT_SHOP_TABLE, {
          _BARCODE_AT_SHOP_SHOP_ID: id,
          _BARCODE_AT_SHOP_BARCODE: barcode,
        });
      }
    });
  }

  Future<BarcodesAtShop?> getBarcodesAtShop(
      String countryCode, String offShopId) async {
    final db = await _db;
    return await db.transaction((txn) async {
      final shopData = await txn.query(_SHOP_TABLE,
          where: '$_SHOP_OFF_ID = ? AND $_SHOP_COUNTRY_CODE = ?',
          whereArgs: [offShopId, countryCode]);
      if (shopData.isEmpty) {
        return null;
      }
      final shopId = shopData.first[_ID] as int?;
      final whenObtained = shopData.first[_SHOP_WHEN_OBTAINED] as int?;
      if (shopId == null || whenObtained == null) {
        Log.w('Invalid $_SHOP_TABLE column ${shopData.first}');
        return null;
      }

      final barcodesData = await txn.query(_BARCODE_AT_SHOP_TABLE,
          where: '$_BARCODE_AT_SHOP_SHOP_ID = ?', whereArgs: [shopId]);
      final barcodes = <String>[];
      for (final barcodeData in barcodesData) {
        final barcode = barcodeData[_BARCODE_AT_SHOP_BARCODE] as String?;
        if (barcode == null) {
          Log.w('Invalid $_BARCODE_AT_SHOP_TABLE column $barcodeData');
          continue;
        }
        barcodes.add(barcode);
      }

      return BarcodesAtShop(offShopId, countryCode,
          dateTimeFromSecondsSinceEpoch(whenObtained), barcodes);
    });
  }
}
