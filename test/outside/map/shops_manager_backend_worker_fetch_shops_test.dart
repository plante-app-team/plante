import 'package:built_collection/built_collection.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/shops_in_bounds_response.dart';
import 'package:plante/outside/map/fetched_shops.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
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

  void setUpShopsResponses({
    Iterable<OsmShop> osmShops = const [],
    Iterable<BackendShop> backendShops = const [],
    Map<OsmUID, Iterable<String>> barcodes = const {},
  }) {
    when(osm.fetchShops(bounds: anyNamed('bounds')))
        .thenAnswer((_) async => Ok(osmShops.toList()));

    final shopsConverted = {
      for (final shop in backendShops) shop.osmUID.toString(): shop
    };
    final barcodesConverted = barcodes.map(
        (key, value) => MapEntry(key.toString(), BuiltList<String>(value)));
    final response = ShopsInBoundsResponse((e) => e
      ..shops.addAll(shopsConverted)
      ..barcodes.addAll(barcodesConverted));
    when(backend.requestShopsWithin(any)).thenAnswer((_) async => Ok(response));
  }

  test('fetchShops with simple bounds without preloaded data', () async {
    setUpShopsResponses(
      osmShops: someOsmShops.values,
      backendShops: someBackendShops.values,
    );

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
        FetchedShops(expectedShops, const {}, bounds, someOsmShops, bounds);

    final shopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds, planteBounds: bounds);
    final shops = shopsRes.unwrap();
    expect(shops, equals(expectedFetchResult));
  });

  test('fetchShops with preloaded data', () async {
    setUpShopsResponses(
      backendShops: someBackendShops.values,
    );
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
        FetchedShops(expectedShops, const {}, bounds, someOsmShops, bounds);

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

    setUpShopsResponses(
      osmShops: osmShops.values,
      backendShops: [someBackendShops[theOnlyExpectedShopIs]!],
    );

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
        FetchedShops(expectedShops, const {}, bounds, osmShops, bounds);

    final shopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds, planteBounds: bounds);
    final shops = shopsRes.unwrap();
    expect(shops, equals(expectedFetchResult));
  });

  test('fetchShops barcodes', () async {
    final osmUids = someOsmShops.keys.toList();
    setUpShopsResponses(
        osmShops: someOsmShops.values,
        backendShops: someBackendShops.values,
        barcodes: {
          osmUids[0]: ['123', '345'],
          osmUids[1]: ['567', '789'],
        });

    final bounds = CoordsBounds(
      southwest: Coord(lat: 0, lon: 0),
      northeast: Coord(lat: 99999, lon: 99999),
    );
    final fetchedShopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds, planteBounds: bounds);
    final fetchedShops = fetchedShopsRes.unwrap();
    expect(
        fetchedShops.shopsBarcodes,
        equals({
          osmUids[0]: ['123', '345'],
          osmUids[1]: ['567', '789'],
        }));
  });

  test('fetchShops osm error', () async {
    setUpShopsResponses(
      backendShops: someBackendShops.values,
    );
    when(osm.fetchShops(bounds: anyNamed('bounds')))
        .thenAnswer((_) async => Err(OpenStreetMapError.NETWORK));

    final bounds = CoordsBounds(
      southwest: Coord(lat: 0, lon: 0),
      northeast: Coord(lat: 99, lon: 99),
    );
    final shopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds, planteBounds: bounds);
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });

  test('fetchShops backend error', () async {
    setUpShopsResponses(
      osmShops: someOsmShops.values,
    );
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

  test('fetchShops ignores shops marked as deleted', () async {
    final deletedShop = someBackendShops.values.first.osmUID;
    someBackendShops[deletedShop] =
        someBackendShops[deletedShop]!.rebuild((e) => e.deleted = true);
    setUpShopsResponses(
      osmShops: someOsmShops.values,
      backendShops: someBackendShops.values,
    );

    final expectedShops = someOsmShops.map((key, value) => MapEntry(
        key,
        Shop((e) => e
          ..osmShop.replace(value)
          ..backendShop.replace(someBackendShops[key]!))));
    expectedShops.removeWhere((key, value) => value.osmUID == deletedShop);
    expect(expectedShops.length, equals(someOsmShops.length - 1));

    final bounds = CoordsBounds(
      southwest: Coord(lat: 0, lon: 0),
      northeast: Coord(lat: 99999, lon: 99999),
    );
    final expectedFetchResult =
        FetchedShops(expectedShops, const {}, bounds, someOsmShops, bounds);

    final shopsRes = await shopsManagerBackendWorker.fetchShops(osm,
        osmBounds: bounds, planteBounds: bounds);
    expect(shopsRes.unwrap(), equals(expectedFetchResult));
  });
}
