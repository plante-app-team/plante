import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/fetched_shops.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  test('operator ==', () async {
    final reference = FetchedShops(
      {
        OsmUID.parse('1:1'): Shop((e) => e
          ..osmShop.replace(OsmShop((e) => e
            ..osmUID = OsmUID.parse('1:1')
            ..longitude = 11
            ..latitude = 11
            ..name = 'Spar'))),
      },
      {
        OsmUID.parse('1:1'): const ['123', '345'],
      },
      CoordsBounds(
        southwest: Coord(lat: 10, lon: 10),
        northeast: Coord(lat: 12, lon: 12),
      ),
      {
        OsmUID.parse('1:1'): OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'),
      },
      CoordsBounds(
        southwest: Coord(lat: 10, lon: 10),
        northeast: Coord(lat: 12, lon: 12),
      ),
    );

    // Equals to itself
    expect(reference, equals(reference));

    final notChanged = FetchedShops(
      reference.shops,
      reference.shopsBarcodes,
      reference.shopsBounds,
      reference.osmShops,
      reference.osmShopsBounds,
    );
    expect(reference, equals(notChanged));

    final changed1 = FetchedShops(
      {
        OsmUID.parse('1:1'): Shop((e) => e
          ..osmShop.replace(OsmShop((e) => e
            ..osmUID = OsmUID.parse('1:1')
            ..longitude = 12
            ..latitude = 12
            ..name = 'Spar'))),
      },
      reference.shopsBarcodes,
      reference.shopsBounds,
      reference.osmShops,
      reference.osmShopsBounds,
    );
    expect(reference, equals(isNot(changed1)));

    final changed2 = FetchedShops(
      reference.shops,
      {
        OsmUID.parse('1:1'): const ['123'],
      },
      reference.shopsBounds,
      reference.osmShops,
      reference.osmShopsBounds,
    );
    expect(reference, equals(isNot(changed2)));

    final changed3 = FetchedShops(
      reference.shops,
      reference.shopsBarcodes,
      CoordsBounds(
        southwest: Coord(lat: 11, lon: 10),
        northeast: Coord(lat: 12, lon: 12),
      ),
      reference.osmShops,
      reference.osmShopsBounds,
    );
    expect(reference, equals(isNot(changed3)));

    final changed4 = FetchedShops(
      reference.shops,
      reference.shopsBarcodes,
      reference.shopsBounds,
      {
        OsmUID.parse('1:1'): OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 12
          ..name = 'Spar'),
      },
      reference.osmShopsBounds,
    );
    expect(reference, equals(isNot(changed4)));

    final changed5 = FetchedShops(
      reference.shops,
      reference.shopsBarcodes,
      reference.shopsBounds,
      reference.osmShops,
      CoordsBounds(
        southwest: Coord(lat: 11, lon: 10),
        northeast: Coord(lat: 12, lon: 12),
      ),
    );
    expect(reference, equals(isNot(changed5)));
  });
}
