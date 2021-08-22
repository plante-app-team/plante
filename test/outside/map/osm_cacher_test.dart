import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/osm_cacher.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:test/test.dart';

void main() {
  late OsmCacher osmCacher;

  final shops = [
    OsmShop((e) => e
      ..osmId = '1'
      ..name = 'first'
      ..type = 'type1'
      ..latitude = 111.321
      ..longitude = 111.321),
    OsmShop((e) => e
      ..osmId = '2'
      ..name = 'second'
      ..type = null
      ..latitude = 222.123
      ..longitude = 222.321),
    OsmShop((e) => e
      ..osmId = '3'
      ..name = 'third'
      ..type = 'type3'
      ..latitude = 333.321
      ..longitude = 333.321),
  ];
  final dates = [
    dateTimeFromSecondsSinceEpoch(1),
    dateTimeFromSecondsSinceEpoch(2),
  ];

  setUp(() async {
    osmCacher = OsmCacher();
  });

  test('cached shops: store, delete, reload', () async {
    await osmCacher.dbForTesting;

    // Store 2 territories
    final territory1 = await osmCacher.cacheShops(
        dates[0],
        CoordsBounds(
            southwest: Coord(lat: 111, lon: 111),
            northeast: Coord(lat: 223, lon: 223)),
        [shops[0], shops[1]]);
    expect(territory1.id, greaterThan(0));
    expect(territory1.whenObtained, equals(dates[0]));
    expect(territory1.bounds.southwest, equals(Coord(lat: 111, lon: 111)));
    expect(territory1.bounds.northeast, equals(Coord(lat: 223, lon: 223)));
    expect(territory1.entities, equals([shops[0], shops[1]]));

    final territory2 = await osmCacher.cacheShops(
        dates[1],
        CoordsBounds(
            southwest: Coord(lat: 222, lon: 222),
            northeast: Coord(lat: 334, lon: 334)),
        [shops[1], shops[2]]);
    expect(territory2.id, greaterThan(territory1.id));
    expect(territory2.whenObtained, equals(dates[1]));
    expect(territory2.bounds.southwest, equals(Coord(lat: 222, lon: 222)));
    expect(territory2.bounds.northeast, equals(Coord(lat: 334, lon: 334)));
    expect(territory2.entities, equals([shops[1], shops[2]]));

    // Check the 2 territories are stored
    expect(await osmCacher.getCachedShops(), equals([territory1, territory2]));

    // Remove a territory
    await osmCacher.deleteCachedShops(territory1.id);
    expect(await osmCacher.getCachedShops(), equals([territory2]));

    // Create a second cacher with same DB,
    // verify it has same territories
    final osmCacher2 = OsmCacher.withDb(await osmCacher.dbForTesting);
    expect(await osmCacher2.getCachedShops(), equals([territory2]));
  });
}
