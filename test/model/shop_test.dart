import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';

void main() {
  setUp(() async {});

  test('rebuilding with products count', () {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar2'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..productsCount = 2)));

    final rebuilt = shop.rebuildWith(productsCount: 100);
    final expectedShop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar2'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..productsCount = 100)));

    expect(rebuilt, equals(expectedShop));
  });

  test('rebuilding without products count', () {
    final initialShop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar2'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..productsCount = 2)));

    final rebuilt = initialShop.rebuildWith(productsCount: null);
    expect(rebuilt, equals(initialShop));
  });

  test('rebuilding with products count when there was no backend shop', () {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar2'))
      ..backendShop = null);
    expect(shop.backendShop, isNull);

    final rebuilt = shop.rebuildWith(productsCount: 100);
    expect(rebuilt.backendShop, isNotNull);

    final expectedShop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar2'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..productsCount = 100)));
    expect(rebuilt, equals(expectedShop));
  });
}
