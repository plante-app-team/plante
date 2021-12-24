import 'package:plante/base/coord_utils.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/products/suggestions/_radius_products_suggestions_manager.dart';
import 'package:test/test.dart';

import '../../../z_fakes/fake_shops_manager.dart';

void main() {
  final shopsWithProducts = <Shop>[];
  final shopsWithNoProducts = <Shop>[];
  final shopsCenter = Coord(
    lat: 1,
    lon: 1,
  );

  late FakeShopsManager shopsManager;
  late RadiusProductsSuggestionsManager suggestionsManager;

  Shop createShop(OsmUID uid, String name, {required int productsCount}) {
    return Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = uid
        ..longitude = shopsCenter.lon
        ..latitude = shopsCenter.lat
        ..name = name))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = uid
        ..productsCount = productsCount)));
  }

  setUp(() async {
    shopsManager = FakeShopsManager();
    suggestionsManager = RadiusProductsSuggestionsManager(shopsManager);

    shopsWithProducts.clear();
    shopsWithProducts.addAll([
      createShop(OsmUID.parse('1:1'), 'Spar1', productsCount: 1),
      createShop(OsmUID.parse('1:2'), 'Spar2', productsCount: 2),
      createShop(OsmUID.parse('1:3'), 'Spar3', productsCount: 3),
    ]);
    shopsWithNoProducts.clear();
    shopsWithNoProducts.addAll([
      createShop(OsmUID.parse('1:4'), 'Spar1', productsCount: 0),
      createShop(OsmUID.parse('1:5'), 'Spar2', productsCount: 0),
      createShop(OsmUID.parse('1:6'), 'Spar3', productsCount: 0),
    ]);
  });

  test('good scenario', () async {
    shopsManager.setBarcodesCacheFor(shopsWithProducts[0], ['123', '345']);
    shopsManager.setBarcodesCacheFor(shopsWithProducts[2], ['345', '678']);

    final suggestions = await suggestionsManager.getSuggestedBarcodesByRadius(
        shopsCenter, shopsWithNoProducts);
    expect(
        suggestions,
        equals({
          shopsWithNoProducts[0]: ['123', '345'],
          shopsWithNoProducts[2]: ['345', '678'],
        }));
  });

  test('shops outside of bounds are thrown out', () async {
    const manyKms = RadiusProductsSuggestionsManager.RADIUS_KMS;
    shopsWithProducts[0] = shopsWithProducts[0].rebuildWith(
        coord: Coord(
      lat: shopsCenter.lat + kmToGrad(manyKms * 2),
      lon: shopsCenter.lon + kmToGrad(manyKms * 2),
    ));

    shopsManager.setBarcodesCacheFor(shopsWithProducts[0], ['123', '345']);
    shopsManager.setBarcodesCacheFor(shopsWithProducts[2], ['345', '678']);

    final suggestions = await suggestionsManager.getSuggestedBarcodesByRadius(
        shopsCenter, shopsWithNoProducts);
    expect(
        suggestions,
        equals({
          shopsWithNoProducts[2]: ['345', '678'],
        }));
  });

  test('barcodes from different shops with same name are merged', () async {
    shopsWithProducts[1] =
        shopsWithProducts[1].rebuildWith(name: shopsWithProducts[0].name);

    shopsManager.setBarcodesCacheFor(shopsWithProducts[0], ['123', '345']);
    shopsManager.setBarcodesCacheFor(shopsWithProducts[1], ['345', '890']);

    final suggestions = await suggestionsManager.getSuggestedBarcodesByRadius(
        shopsCenter, shopsWithNoProducts);
    // NOTE: we expect the list to have no duplicates, even though
    // some duplicates are present in the original data
    expect(
        suggestions,
        equals({
          shopsWithNoProducts[0]: ['123', '345', '890'],
        }));
  });

  test(
      'shops names with different case and whitespaces '
      'on the sides are considered same', () async {
    var newName = shopsWithProducts[0].name.toUpperCase();
    newName = ' $newName ';
    shopsWithProducts[1] = shopsWithProducts[1].rebuildWith(name: newName);

    shopsManager.setBarcodesCacheFor(shopsWithProducts[0], [
      '123',
    ]);
    shopsManager.setBarcodesCacheFor(shopsWithProducts[1], [
      '345',
    ]);

    final suggestions = await suggestionsManager.getSuggestedBarcodesByRadius(
        shopsCenter, shopsWithNoProducts);
    expect(
        suggestions,
        equals({
          shopsWithNoProducts[0]: ['123', '345'],
        }));
  });
}
