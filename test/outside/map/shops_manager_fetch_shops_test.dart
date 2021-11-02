import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_osm_cacher.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late MockOsmOverpass osm;
  late MockBackend backend;
  late FakeOsmCacher osmCacher;
  late ShopsManager shopsManager;

  late List<OsmShop> osmShops;
  late List<BackendShop> backendShops;
  late Map<OsmUID, Shop> fullShops;

  late CoordsBounds bounds;
  late CoordsBounds farBounds;

  setUp(() async {
    commons = ShopsManagerTestCommons();
    osmShops = commons.osmShops;
    backendShops = commons.backendShops;
    fullShops = commons.fullShops;
    bounds = commons.bounds;
    farBounds = commons.farBounds;

    osm = commons.osm;
    backend = commons.backend;
    osmCacher = commons.osmCacher;
    shopsManager = commons.shopsManager;
  });

  test('shops fetched and then cached', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);
    final listener = MockShopsManagerListener();
    shopsManager.addListener(listener);

    // Fetch #1
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    expect(shops, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShopsWithin(any));
    // Listener expected to be notified about cache updated
    verify(listener.onLocalShopsChange());

    clearInteractions(osm);
    clearInteractions(backend);
    clearInteractions(listener);

    // Fetch #2
    final shopsRes2 = await shopsManager.fetchShops(bounds);
    final shops2 = shopsRes2.unwrap();
    expect(shops2, equals(fullShops));
    // No backends expected to be touched! Cache expected to be used!
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);
    // Listener expected to be NOT notified
    verifyZeroInteractions(listener);
  });

  test('cache behaviour when multiple shops fetches started at the same time',
      () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch without await
    final shopsFuture1 = shopsManager.fetchShops(bounds);
    final shopsFuture2 = shopsManager.fetchShops(bounds);
    final shopsFuture3 = shopsManager.fetchShops(bounds);
    final shopsFuture4 = shopsManager.fetchShops(bounds);

    // Await all
    final results = await Future.wait(
        [shopsFuture1, shopsFuture2, shopsFuture3, shopsFuture4]);
    for (final result in results) {
      expect(result.unwrap(), equals(fullShops));
    }
    // Both backends expected to be touched exactly once
    verify(osm.fetchShops(bounds: anyNamed('bounds'))).called(1);
    verify(backend.requestShopsWithin(any)).called(1);
  });

  test('shops fetch when cache exists but it is for another area', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1
    final shopsRes = await shopsManager.fetchShops(bounds);
    expect(shopsRes.isOk, isTrue);
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShopsWithin(any));

    clearInteractions(osm);
    clearInteractions(backend);

    // Fetch #2, another area
    final shopsRes2 = await shopsManager.fetchShops(farBounds);
    expect(shopsRes2.isOk, isTrue);
    // Both backends expected to be touched again!
    // Because the requested area is too far away from the cached one
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShopsWithin(any));
  });

  test('multiple failed shops load attempts and 1 successful', () async {
    // First request to each will fail, the others will succeed
    var osmLoadsCount = 0;
    var backendLoadsCount = 0;
    when(osm.fetchShops(bounds: anyNamed('bounds'))).thenAnswer((_) async {
      osmLoadsCount += 1;
      if (osmLoadsCount == 1) {
        return Err(OpenStreetMapError.OTHER);
      } else {
        return Ok(osmShops);
      }
    });
    when(backend.requestShopsWithin(any)).thenAnswer((_) async {
      backendLoadsCount += 1;
      if (backendLoadsCount == 1) {
        return Err(BackendError.other());
      } else {
        return Ok(backendShops);
      }
    });

    final shopsRes = await shopsManager.fetchShops(bounds);
    expect(shopsRes.isOk, isTrue);

    // First call fails, second succeeds, but backend fails then.
    // So the third call will be the final one.
    verify(osm.fetchShops(bounds: anyNamed('bounds'))).called(3);
    // First call fails, second succeeds.
    verify(backend.requestShopsWithin(any)).called(2);
  });

  test('all shops loads failed', () async {
    when(osm.fetchShops(bounds: anyNamed('bounds'))).thenAnswer((_) async {
      return Err(OpenStreetMapError.OTHER);
    });
    when(backend.requestShopsWithin(any)).thenAnswer((_) async {
      return Err(BackendError.other());
    });
    final shopsRes = await shopsManager.fetchShops(bounds);
    expect(shopsRes.isErr, isTrue);
  });

  test('loading network error makes only for 1 load attempt', () async {
    // First request will fail, the others would succeed.
    // Would, if not for the network error!
    var osmLoadsCount = 0;
    when(osm.fetchShops(bounds: anyNamed('bounds'))).thenAnswer((_) async {
      osmLoadsCount += 1;
      if (osmLoadsCount == 1) {
        return Err(OpenStreetMapError.NETWORK);
      } else {
        return Ok(osmShops);
      }
    });
    when(backend.requestShopsWithin(any)).thenAnswer((_) async {
      return Ok(backendShops);
    });

    final shopsRes = await shopsManager.fetchShops(bounds);
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));

    // First call fails with a network errors, other calls don't happen.
    verify(osm.fetchShops(bounds: anyNamed('bounds'))).called(1);
    verifyNever(backend.requestShopsWithin(any));
  });

  test('shops fetch: requested bounds sizes', () async {
    // First request to OSM will fail, the others will succeed
    var osmLoadsCount = 0;
    final osmRequestedBounds = <CoordsBounds>[];
    when(osm.fetchShops(bounds: anyNamed('bounds'))).thenAnswer((invc) async {
      final bounds =
          invc.namedArguments[const Symbol('bounds')] as CoordsBounds;
      osmRequestedBounds.add(bounds);
      osmLoadsCount += 1;
      if (osmLoadsCount == 1) {
        return Err(OpenStreetMapError.OTHER);
      } else {
        return Ok(osmShops);
      }
    });
    when(backend.requestShopsWithin(any)).thenAnswer((_) async => Ok(const []));

    final shopsRes = await shopsManager.fetchShops(bounds);
    expect(shopsRes.isOk, isTrue);

    expect(osmRequestedBounds.length, equals(2));
    // First OSM request is expected to have bigger bounds than the second
    expect(
        osmRequestedBounds[0].width, greaterThan(osmRequestedBounds[1].width));
    expect(osmRequestedBounds[0].height,
        greaterThan(osmRequestedBounds[1].height));
  });

  test('shops fetch: persistent OSM cache is fresh', () async {
    final cachedOsmShops =
        osmShops.map((e) => e.rebuild((e) => e.name = '${e.name}hello'));
    final now = DateTime.now();
    final cache = await osmCacher.cacheShops(
        now, bounds.center.makeSquare(1), cachedOsmShops);

    // Fetch
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    // Verify data from cache was used
    expect(shops.values.map((e) => e.osmShop), equals(cachedOsmShops));
    expect(shops.values.map((e) => e.osmShop), isNot(equals(osmShops)));
    // OSM expected to be not touched since fresh persistent cache exists
    verifyZeroInteractions(osm);

    // We expect the persistent cache to be unchanged
    expect(await osmCacher.getCachedShops(), equals([cache]));
  });

  test('shops fetch: persistent OSM cache is old', () async {
    // Store OLD persistent cache
    final cachedOsmShops =
        osmShops.map((e) => e.rebuild((e) => e.name = '${e.name}hello'));
    final now = DateTime.now().subtract(const Duration(
        days: ShopsManager.DAYS_BEFORE_PERSISTENT_CACHE_IS_OLD + 1));
    final oldCache = await osmCacher.cacheShops(
        now, bounds.center.makeSquare(1), cachedOsmShops);

    // Fetch
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    // Verify data from cache was NOT used
    expect(shops.values.map((e) => e.osmShop), isNot(equals(cachedOsmShops)));
    expect(shops.values.map((e) => e.osmShop), equals(osmShops));
    // OSM expected to be touched because the persistent cache is old
    verify(osm.fetchShops(bounds: anyNamed('bounds')));

    // We expect old persistent cache to be deleted and new to be saved
    final newCache = await osmCacher.getCachedShops();
    expect(newCache.length, equals(1));
    expect(newCache.first, isNot(equals(oldCache)));
  });

  test('shops fetch: persistent OSM cache is old and OSM gives errors',
      () async {
    // Store OLD persistent cache
    final cachedOsmShops =
        osmShops.map((e) => e.rebuild((e) => e.name = '${e.name}hello'));
    final now = DateTime.now().subtract(const Duration(
        days: ShopsManager.DAYS_BEFORE_PERSISTENT_CACHE_IS_OLD + 1));
    final oldCache = await osmCacher.cacheShops(
        now, bounds.center.makeSquare(1), cachedOsmShops);

    // OSM returns errors
    when(osm.fetchShops(bounds: anyNamed('bounds'))).thenAnswer((_) async {
      return Err(OpenStreetMapError.OTHER);
    });

    // Fetch
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    // Verify data from cache WAS used because OSM backend gives errors
    expect(shops.values.map((e) => e.osmShop), equals(cachedOsmShops));
    expect(shops.values.map((e) => e.osmShop), isNot(equals(osmShops)));
    // OSM expected to be touched because the persistent cache is old
    verify(osm.fetchShops(bounds: anyNamed('bounds')));

    // We expect the persistent cache to be unchanged because OSM is not responsive
    expect(await osmCacher.getCachedShops(), equals([oldCache]));
  });

  test('shops fetch: persistent OSM cache is ancient, and OSM gives errors',
      () async {
    // Store ANCIENT persistent cache
    final cachedOsmShops =
        osmShops.map((e) => e.rebuild((e) => e.name = '${e.name}hello'));
    final now = DateTime.now().subtract(const Duration(
        days: ShopsManager.DAYS_BEFORE_PERSISTENT_CACHE_IS_ANCIENT + 1));
    await osmCacher.cacheShops(
        now, bounds.center.makeSquare(1), cachedOsmShops);

    // OSM returns errors
    when(osm.fetchShops(bounds: anyNamed('bounds'))).thenAnswer((_) async {
      return Err(OpenStreetMapError.OTHER);
    });

    // Fetch
    final shopsRes = await shopsManager.fetchShops(bounds);
    // Verify data from cache WAS NOT used, even though cache exists
    // and OSM returns errors - the cache is ancient, ancient cache is not
    // acceptable.
    expect(shopsRes.unwrapErr(), ShopsManagerError.OSM_SERVERS_ERROR);

    // We expect the persistent cache to be deleted because it is ancient
    expect(await osmCacher.getCachedShops(), isEmpty);
  });

  test('returned shops are within the requested bounds', () async {
    final osmShops = [
      OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..name = 'shop1'
        ..longitude = 15
        ..latitude = 15),
      OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..name = 'shop2'
        ..longitude = 15.0001
        ..latitude = 15.0001),
    ];
    when(osm.fetchShops(bounds: anyNamed('bounds')))
        .thenAnswer((_) async => Ok(osmShops));
    when(backend.requestShopsWithin(any))
        .thenAnswer((_) async => Ok(backendShops));

    final northeast = Coord(lat: 15, lon: 15);
    final southwest = Coord(lat: 14.999, lon: 14.999);
    final bounds = CoordsBounds(southwest: southwest, northeast: northeast);

    // First request which shall initialize instance's cache
    var shopsRes = await shopsManager.fetchShops(bounds);
    var shops = shopsRes.unwrap();
    // Only shop 1 is expected because only it is within the bounds
    expect(shops.values.map((e) => e.osmUID), equals([osmShops[0].osmUID]));
    // Verify cache was not used
    verify(osm.fetchShops(bounds: anyNamed('bounds')));

    clearInteractions(osm);

    // Second request which shall use instance's cache
    shopsRes = await shopsManager.fetchShops(bounds);
    shops = shopsRes.unwrap();
    // Again only shop 1 is expected because only it is within the bounds
    expect(shops.values.map((e) => e.osmUID), equals([osmShops[0].osmUID]));
    // Verify cache WAS used
    verifyNever(osm.fetchShops(bounds: anyNamed('bounds')));
  });

  test(
      'when plante backend returns a shop which is not present in cache '
      'then it is requested from OSM', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch and cache
    var fetchedShopsRes = await shopsManager.fetchShops(bounds);
    clearInteractions(osm);
    clearInteractions(backend);
    // Ensure shops are cached
    fetchedShopsRes = await shopsManager.fetchShops(bounds);
    var fetchedShops = fetchedShopsRes.unwrap();
    expect(fetchedShops, equals(fullShops));
    // No backends expected to be touched! Cache expected to be used!
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Add a shop to backend and to OSM
    final newShopUID = OsmUID.parse('1:123321');
    backendShops.add(BackendShop((e) => e
      ..osmUID = newShopUID
      ..productsCount = 123));
    osmShops.add(OsmShop((e) => e
      ..osmUID = newShopUID
      ..name = 'New cool shop'
      ..latitude = bounds.center.lat
      ..longitude = bounds.center.lon));

    // Perform fetch with the old ShopsManager
    fetchedShopsRes = await shopsManager.fetchShops(bounds);
    fetchedShops = fetchedShopsRes.unwrap();
    // Ensure old ShopsManager knows nothing of the new shop
    expect(fetchedShops.keys, isNot(contains(newShopUID)));
    // Ensure OSM Cache knows nothing of the new shop
    var allCachedOsmShops = await osmCacher.getAllOsmShopsForTests();
    expect(allCachedOsmShops.map((e) => e.osmUID), isNot(contains(newShopUID)));
    // No backends expected to be touched! Cache expected to be used!
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Perform fetch with a new ShopsManager
    final newShopsManager = commons.createShopsManager();
    fetchedShopsRes = await newShopsManager.fetchShops(bounds);
    fetchedShops = fetchedShopsRes.unwrap();
    // Ensure new ShopsManager knows of the new shop
    expect(fetchedShops.keys, contains(newShopUID));
    // Ensure the new shop is put into OSM Cache
    allCachedOsmShops = await osmCacher.getAllOsmShopsForTests();
    expect(allCachedOsmShops.map((e) => e.osmUID), contains(newShopUID));
    // OSM backend expected to be be queried for the new shop
    verify(osm.fetchShops(osmUIDs: [newShopUID]));
  });
}
