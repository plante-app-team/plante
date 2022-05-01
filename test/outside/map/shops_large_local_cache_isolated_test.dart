import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_large_local_cache_isolated.dart';
import 'package:test/test.dart';

void main() {
  late ShopsLargeLocalCacheIsolated cacheWrapper;

  setUp(() async {
    cacheWrapper = await ShopsLargeLocalCacheIsolated.create();
  });

  test('add and get barcodes', () async {
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:1'): ['123', '345'],
      OsmUID.parse('1:2'): ['345', '578'],
    });
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:2'): ['111'],
    });
    await cacheWrapper.addBarcode(OsmUID.parse('1:1'), '111');

    final expected = {
      OsmUID.parse('1:1'): ['123', '345', '111'],
      OsmUID.parse('1:2'): ['345', '578', '111'],
    };
    final actual = await cacheWrapper
        .getBarcodes([OsmUID.parse('1:1'), OsmUID.parse('1:2')]);
    expect(actual, equals(expected));
  });

  test('get shops containing barcodes', () async {
    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = 1
        ..latitude = 1
        ..name = 'Spar1'))));
    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 5
        ..latitude = 5
        ..name = 'Spar2'))));
    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:3')
        ..longitude = 5
        ..latitude = 5
        ..name = 'Spar3'))));
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:1'): ['123', '345'],
      OsmUID.parse('1:2'): ['345', '578'],
    });
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:1'): ['111'],
      OsmUID.parse('1:3'): ['111'],
    });

    var actual = await cacheWrapper.getShopsContainingBarcodes(
        CoordsBounds(
            southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 6, lon: 6)),
        {'111', '123'});
    var expected = {
      '111': [OsmUID.parse('1:1'), OsmUID.parse('1:3')],
      '123': [OsmUID.parse('1:1')],
    };
    expect(actual, equals(expected));

    actual = await cacheWrapper.getShopsContainingBarcodes(
        CoordsBounds(
            southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 2, lon: 2)),
        {'111', '123'});
    expected = {
      '111': [OsmUID.parse('1:1')],
      '123': [OsmUID.parse('1:1')],
    };
    expect(actual, equals(expected));
  });

  test('add duplicated barcode', () async {
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:1'): ['123', '345'],
      OsmUID.parse('1:2'): ['345', '578'],
    });
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:1'): ['345'],
    });
    await cacheWrapper.addBarcode(OsmUID.parse('1:1'), '123');
    await cacheWrapper.addBarcode(OsmUID.parse('1:2'), '345');

    final expected = {
      OsmUID.parse('1:1'): ['123', '345'],
      OsmUID.parse('1:2'): ['345', '578'],
    };
    final actual = await cacheWrapper
        .getBarcodes([OsmUID.parse('1:1'), OsmUID.parse('1:2')]);
    expect(actual, equals(expected));
  });

  test('remove barcodes', () async {
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:1'): ['123', '345'],
      OsmUID.parse('1:2'): ['123', '345'],
    });

    var expected = {
      OsmUID.parse('1:1'): ['123', '345'],
      OsmUID.parse('1:2'): ['123', '345'],
    };
    expect(
        await cacheWrapper
            .getBarcodes([OsmUID.parse('1:1'), OsmUID.parse('1:2')]),
        equals(expected));

    await cacheWrapper.removeBarcodes({
      OsmUID.parse('1:1'): ['123'],
      OsmUID.parse('1:2'): ['123', '345'],
    });

    expected = {
      OsmUID.parse('1:1'): ['345'],
    };
    expect(
        await cacheWrapper
            .getBarcodes([OsmUID.parse('1:1'), OsmUID.parse('1:2')]),
        equals(expected));

    await cacheWrapper.removeBarcode(OsmUID.parse('1:1'), '345');
    expect(
        await cacheWrapper
            .getBarcodes([OsmUID.parse('1:1'), OsmUID.parse('1:2')]),
        isEmpty);
  });

  test('remove barcodes and then get shops containing them', () async {
    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = 1
        ..latitude = 1
        ..name = 'Spar1'))));
    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 5
        ..latitude = 5
        ..name = 'Spar2'))));
    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:3')
        ..longitude = 5
        ..latitude = 5
        ..name = 'Spar3'))));
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:1'): ['123', '345'],
      OsmUID.parse('1:2'): ['345', '578'],
    });
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:1'): ['111'],
      OsmUID.parse('1:3'): ['111'],
    });

    var actual = await cacheWrapper.getShopsContainingBarcodes(
        CoordsBounds(
            southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 6, lon: 6)),
        {'111', '123'});
    var expected = {
      '111': [OsmUID.parse('1:1'), OsmUID.parse('1:3')],
      '123': [OsmUID.parse('1:1')],
    };
    expect(actual, equals(expected));

    await cacheWrapper.removeBarcodes({
      OsmUID.parse('1:1'): ['123'],
    });

    actual = await cacheWrapper.getShopsContainingBarcodes(
        CoordsBounds(
            southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 6, lon: 6)),
        {'111', '123'});
    expected = {
      '111': [OsmUID.parse('1:1'), OsmUID.parse('1:3')],
    };
    expect(actual, equals(expected));
  });

  test('add and get shops', () async {
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar1'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar2'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar3'))),
    ];

    await cacheWrapper.addShops([shops[0], shops[1]]);
    await cacheWrapper.addShop(shops[2]);

    final uids = shops.map((e) => e.osmUID);
    final shopsMap = {for (final shop in shops) shop.osmUID: shop};
    expect(await cacheWrapper.getShops(uids), equals(shopsMap));
  });

  test('overwrite shops', () async {
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar1'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar2'))),
    ];
    await cacheWrapper.addShops(shops);

    // Overwrite
    final changedShop = shops[0].rebuildWith(name: 'new name');
    await cacheWrapper.addShop(changedShop);

    final uids = shops.map((e) => e.osmUID);
    final actualShops = (await cacheWrapper.getShops(uids)).values.toSet();
    expect(actualShops, isNot(equals(shops.toSet())));
    expect(actualShops, equals({changedShop, shops[1]}));
  });

  test('get barcodes within', () async {
    final bounds = Coord(lat: 11, lon: 11).makeSquare(5);
    await cacheWrapper.addBarcodes({
      OsmUID.parse('1:1'): ['123', '345'],
      OsmUID.parse('1:2'): ['345', '578'],
    });
    expect(await cacheWrapper.getBarcodesWithin(bounds), isEmpty);

    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar1'))));
    expect(await cacheWrapper.getBarcodesWithin(bounds), {
      OsmUID.parse('1:1'): ['123', '345']
    });

    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar2'))));
    expect(await cacheWrapper.getBarcodesWithin(bounds), {
      OsmUID.parse('1:1'): ['123', '345'],
      OsmUID.parse('1:2'): ['345', '578'],
    });
  });

  test('clear', () async {
    final uids = [
      OsmUID.parse('1:1'),
      OsmUID.parse('1:2'),
    ];
    await cacheWrapper.addBarcodes({
      uids[0]: ['123', '345'],
      uids[1]: ['345', '578'],
    });
    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = uids[0]
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar1'))));
    await cacheWrapper.addShop(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = uids[1]
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar2'))));

    expect(await cacheWrapper.getBarcodes(uids), isNotEmpty);
    expect(await cacheWrapper.getShops(uids), isNotEmpty);
    expect(
        await cacheWrapper.getShopsContainingBarcodes(
            CoordsBounds(
                southwest: Coord(lat: 10, lon: 10),
                northeast: Coord(lat: 12, lon: 12)),
            {'123', '345', '578'}),
        isNotEmpty);

    await cacheWrapper.clear();

    expect(await cacheWrapper.getBarcodes(uids), isEmpty);
    expect(await cacheWrapper.getShops(uids), isEmpty);
    expect(
        await cacheWrapper.getShopsContainingBarcodes(
            CoordsBounds(
                southwest: Coord(lat: 10, lon: 10),
                northeast: Coord(lat: 12, lon: 12)),
            {'123', '345', '578'}),
        isEmpty);
  });
}
