import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/fetched_shops.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/map/shops_manager_backend_worker.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import 'shops_manager_backend_worker_test_commons.dart';

void main() {
  late ShopsManagerBackendWorkerTestCommons commons;
  late MockOsmOverpass osm;
  late MockBackend backend;
  late MockProductsObtainer productsObtainer;
  late ShopsManagerBackendWorker shopsManagerBackendWorker;

  late Map<OsmUID, OsmShop> someOsmShops;
  late Map<OsmUID, BackendShop> someBackendShops;

  setUp(() async {
    commons = ShopsManagerBackendWorkerTestCommons();
    osm = commons.osm;
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    someOsmShops = commons.someOsmShops;
    someBackendShops = commons.someBackendShops;
    shopsManagerBackendWorker =
        ShopsManagerBackendWorker(backend, productsObtainer);
  });

  test('fetchShops with simple bounds without preloaded data', () async {
    when(osm.fetchShops(bounds: anyNamed('bounds')))
        .thenAnswer((_) async => Ok(someOsmShops.values.toList()));
    when(backend.requestShopsWithin(any))
        .thenAnswer((_) async => Ok(someBackendShops.values.toList()));

    final expectedShops = someOsmShops.map((key, value) => MapEntry(
        key,
        Shop((e) => e
          ..osmShop.replace(value)
          ..backendShop.replace(someBackendShops[key]!))));

    final bounds = CoordsBounds(
      southwest: Coord(lat: 0, lon: 0),
      northeast: Coord(lat: 99999, lon: 99999),
    );
    final expectedFetchResult =
        FetchedShops(expectedShops, bounds, someOsmShops, bounds);

    final shopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds, planteBounds: bounds);
    final shops = shopsRes.unwrap();
    expect(shops, equals(expectedFetchResult));
  });

  test('fetchShops with preloaded data', () async {
    when(backend.requestShopsWithin(any))
        .thenAnswer((_) async => Ok(someBackendShops.values.toList()));
    // OSM would return an error if it would be queried...
    when(osm.fetchShops(bounds: anyNamed('bounds')))
        .thenAnswer((_) async => Err(OpenStreetMapError.OTHER));

    // ...but we still expect [osmShops] to be ok! Because...
    final expectedShops = someOsmShops.map((key, value) => MapEntry(
        key,
        Shop((e) => e
          ..osmShop.replace(value)
          ..backendShop.replace(someBackendShops[key]!))));

    final bounds = CoordsBounds(
      southwest: Coord(lat: 0, lon: 0),
      northeast: Coord(lat: 99999, lon: 99999),
    );
    final expectedFetchResult =
        FetchedShops(expectedShops, bounds, someOsmShops, bounds);

    // ...Because [preloadedOsmShops] is specified
    final shopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds,
        planteBounds: bounds,
        preloadedOsmShops: someOsmShops.values);
    final shops = shopsRes.unwrap();
    expect(shops, equals(expectedFetchResult));

    // And OSM is expected to be not touched
    verifyZeroInteractions(osm);
  });

  test('fetchShops with Plante bounds smaller than OSM bounds', () async {
    // Prepare OsmShops, 1 of which will be within bounds, and others outside
    expect(someBackendShops.length, greaterThanOrEqualTo(2));
    final osmShops = <OsmUID, OsmShop>{};
    OsmUID? theOnlyExpectedShopIs;
    for (var index = 0; index < someOsmShops.values.toList().length; ++index) {
      final osmShop = someOsmShops.values.toList()[index];
      if (index == 0) {
        theOnlyExpectedShopIs = osmShop.osmUID;
        osmShops[osmShop.osmUID] = osmShop.rebuild((e) => e
          ..latitude = 10
          ..longitude = 10);
      } else {
        osmShops[osmShop.osmUID] = osmShop.rebuild((e) => e
          ..latitude = 100000
          ..longitude = 100000);
      }
    }
    when(osm.fetchShops(bounds: anyNamed('bounds')))
        .thenAnswer((_) async => Ok(osmShops.values.toList()));
    // Prepare backend shops
    when(backend.requestShopsWithin(any)).thenAnswer((_) async {
      return Ok([someBackendShops[theOnlyExpectedShopIs]!]);
    });

    final bounds = CoordsBounds(
      southwest: Coord(lat: 0, lon: 0),
      northeast: Coord(lat: 99, lon: 99),
    );
    // Only 1 shops is expected because its within the requested bounds
    final expectedShops = {
      theOnlyExpectedShopIs!: Shop((e) => e
        ..osmShop.replace(osmShops[theOnlyExpectedShopIs!]!)
        ..backendShop.replace(someBackendShops[theOnlyExpectedShopIs]!)),
    };

    final expectedFetchResult =
        FetchedShops(expectedShops, bounds, osmShops, bounds);

    final shopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds, planteBounds: bounds);
    final shops = shopsRes.unwrap();
    expect(shops, equals(expectedFetchResult));
  });

  test('fetchShops osm error', () async {
    when(osm.fetchShops(bounds: anyNamed('bounds')))
        .thenAnswer((_) async => Err(OpenStreetMapError.NETWORK));

    final backendShops = [
      BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..productsCount = 2),
      BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..productsCount = 1),
    ];
    when(backend.requestShopsWithin(any))
        .thenAnswer((_) async => Ok(backendShops));

    final bounds = CoordsBounds(
      southwest: Coord(lat: 0, lon: 0),
      northeast: Coord(lat: 99, lon: 99),
    );
    final shopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds, planteBounds: bounds);
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });

  test('fetchShops backend error', () async {
    final osmShops = [
      OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..name = 'shop1'
        ..type = 'supermarket'
        ..longitude = 123
        ..latitude = 321)
    ];
    when(osm.fetchShops(bounds: anyNamed('bounds')))
        .thenAnswer((_) async => Ok(osmShops));
    when(backend.requestShopsWithin(any))
        .thenAnswer((_) async => Err(BackendError.other()));

    final bounds = CoordsBounds(
      southwest: Coord(lat: 0, lon: 0),
      northeast: Coord(lat: 99, lon: 99),
    );
    final shopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds, planteBounds: bounds);
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.OTHER));
  });
}