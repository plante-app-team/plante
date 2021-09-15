import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_osm_cacher.dart';

class ShopsManagerTestCommons {
  late MockOsmOverpass osm;
  late MockBackend backend;
  late MockProductsObtainer productsObtainer;
  late FakeAnalytics analytics;
  late FakeOsmCacher osmCacher;
  late ShopsManager shopsManager;

  final osmId1 = '1';
  final osmId2 = '2';
  var osmShops = <OsmShop>[];
  var backendShops = <BackendShop>[];
  var fullShops = <String, Shop>{};

  final bounds = CoordsBounds(
      northeast: Coord(lat: 15.001, lon: 15.001),
      southwest: Coord(lat: 14.999, lon: 14.999));
  final farBounds = CoordsBounds(
      northeast: Coord(lat: 16.001, lon: 16.001),
      southwest: Coord(lat: 15.999, lon: 15.999));

  final rangeBackendProducts = [
    BackendProduct((e) => e.barcode = '123'),
    BackendProduct((e) => e.barcode = '124'),
    BackendProduct((e) => e.barcode = '125'),
  ];
  final rangeProducts = [
    Product((e) => e.barcode = '123'),
    Product((e) => e.barcode = '124'),
    Product((e) => e.barcode = '125'),
  ];

  ShopsManagerTestCommons() {
    osmShops = [
      OsmShop((e) => e
        ..osmId = osmId1
        ..name = 'shop1'
        ..type = 'supermarket'
        ..longitude = 15
        ..latitude = 15),
      OsmShop((e) => e
        ..osmId = osmId2
        ..name = 'shop2'
        ..type = 'convenience'
        ..longitude = 15
        ..latitude = 15),
    ];
    backendShops = [
      BackendShop((e) => e
        ..osmId = osmId1
        ..productsCount = 2),
      BackendShop((e) => e
        ..osmId = osmId2
        ..productsCount = 1),
    ];
    fullShops = {
      osmShops[0].osmId: Shop((e) => e
        ..osmShop.replace(osmShops[0])
        ..backendShop.replace(backendShops[0])),
      osmShops[1].osmId: Shop((e) => e
        ..osmShop.replace(osmShops[1])
        ..backendShop.replace(backendShops[1])),
    };

    osm = MockOsmOverpass();
    backend = MockBackend();
    productsObtainer = MockProductsObtainer();
    analytics = FakeAnalytics();
    osmCacher = FakeOsmCacher();
    shopsManager = ShopsManager(OpenStreetMap.forTesting(overpass: osm),
        backend, productsObtainer, analytics, osmCacher);

    when(backend.putProductToShop(any, any))
        .thenAnswer((_) async => Ok(None()));
    when(osm.fetchShops(any)).thenAnswer((_) async => Ok(osmShops));
    when(backend.requestShops(any)).thenAnswer((_) async => Ok(backendShops));

    when(productsObtainer.inflate(rangeBackendProducts[0]))
        .thenAnswer((_) async => Ok(rangeProducts[0]));
    when(productsObtainer.inflate(rangeBackendProducts[1]))
        .thenAnswer((_) async => Ok(rangeProducts[1]));
    when(productsObtainer.inflate(rangeBackendProducts[2]))
        .thenAnswer((_) async => Ok(rangeProducts[2]));

    when(backend.createShop(
            name: anyNamed('name'),
            coord: anyNamed('coord'),
            type: anyNamed('type')))
        .thenAnswer((_) async {
      final result = BackendShop((e) => e
        ..osmId = randInt(1, 99999).toString()
        ..productsCount = 0);
      backendShops.add(result);
      return Ok(result);
    });
  }
}
