import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

import '../../common_mocks.mocks.dart';

class ShopsManagerBackendWorkerTestCommons {
  late MockOsmOverpass osm;
  late MockBackend backend;
  late MockProductsObtainer productsObtainer;

  final someOsmShops = {
    OsmUID.parse('1:1'): OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..name = 'shop1'
      ..type = 'supermarket'
      ..longitude = 123
      ..latitude = 321),
    OsmUID.parse('1:2'): OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:2')
      ..name = 'shop2'
      ..type = 'convenience'
      ..longitude = 124
      ..latitude = 322),
  };

  final someBackendShops = {
    OsmUID.parse('1:1'): BackendShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..productsCount = 2),
    OsmUID.parse('1:2'): BackendShop((e) => e
      ..osmUID = OsmUID.parse('1:2')
      ..productsCount = 1),
  };

  late Map<OsmUID, Shop> someShops;

  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..longitude = 11
      ..latitude = 11
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..productsCount = 2)));

  ShopsManagerBackendWorkerTestCommons() {
    someShops = {
      OsmUID.parse('1:1'): Shop((e) => e
        ..osmShop.replace(someOsmShops[OsmUID.parse('1:1')]!)
        ..backendShop.replace(someBackendShops[OsmUID.parse('1:1')]!)),
      OsmUID.parse('1:2'): Shop((e) => e
        ..osmShop.replace(someOsmShops[OsmUID.parse('1:2')]!)
        ..backendShop.replace(someBackendShops[OsmUID.parse('1:2')]!)),
    };

    osm = MockOsmOverpass();
    backend = MockBackend();
    productsObtainer = MockProductsObtainer();
  }
}
