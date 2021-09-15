import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';

import '../../common_mocks.mocks.dart';

class ShopsRequesterTestCommons {
  late MockOsmOverpass osm;
  late MockBackend backend;
  late MockProductsObtainer productsObtainer;

  final someOsmShops = {
    '1': OsmShop((e) => e
      ..osmId = '1'
      ..name = 'shop1'
      ..type = 'supermarket'
      ..longitude = 123
      ..latitude = 321),
    '2': OsmShop((e) => e
      ..osmId = '2'
      ..name = 'shop2'
      ..type = 'convenience'
      ..longitude = 124
      ..latitude = 322),
  };

  final someBackendShops = {
    '1': BackendShop((e) => e
      ..osmId = '1'
      ..productsCount = 2),
    '2': BackendShop((e) => e
      ..osmId = '2'
      ..productsCount = 1),
  };

  late Map<String, Shop> someShops;

  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmId = '1'
      ..longitude = 11
      ..latitude = 11
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmId = '1'
      ..productsCount = 2)));

  ShopsRequesterTestCommons() {
    someShops = {
      '1': Shop((e) => e
        ..osmShop.replace(someOsmShops['1']!)
        ..backendShop.replace(someBackendShops['1']!)),
      '2': Shop((e) => e
        ..osmShop.replace(someOsmShops['2']!)
        ..backendShop.replace(someBackendShops['2']!)),
    };

    osm = MockOsmOverpass();
    backend = MockBackend();
    productsObtainer = MockProductsObtainer();
  }
}
