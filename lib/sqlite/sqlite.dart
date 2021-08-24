import 'package:plante/base/base.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

typedef DatabaseCallback = dynamic Function(Database db);

Future<Database> openDB(String path,
    {int? version, OnDatabaseVersionChangeFn? onUpgrade}) async {
  if (!isInTests()) {
    return await openDatabase(path, version: version, onUpgrade: onUpgrade);
  } else {
    final rand = randInt(1, 4294967296);
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;
    return await databaseFactory.openDatabase(
        'file:$path$rand?mode=memory&cache=shared',
        options: OpenDatabaseOptions(version: version, onUpgrade: onUpgrade));
  }
}
