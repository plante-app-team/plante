import 'package:mockito/mockito.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_mobile_app_config_manager.dart';
import '../../z_fakes/fake_osm_cacher.dart';
import 'shops_manager_test_commons.dart';

// TODO: please try to decouple tests in this file into many smaller files
void main() {
  late ShopsManagerTestCommons commons;
  late MockOsmOverpass osm;
  late MockBackend backend;
  late MockProductsObtainer productsObtainer;
  late FakeAnalytics analytics;
  late FakeOsmCacher osmCacher;
  late ShopsManager shopsManager;

  late List<OsmShop> osmShops;
  late List<BackendShop> backendShops;
  late Map<OsmUID, Shop> fullShops;

  late CoordsBounds bounds;
  late CoordsBounds farBounds;

  late List<BackendProduct> rangeBackendProducts;
  late List<Product> rangeProducts;

  setUp(() async {
    commons = ShopsManagerTestCommons();
    osmShops = commons.osmShops;
    backendShops = commons.backendShops;
    fullShops = commons.fullShops;
    bounds = commons.bounds;
    farBounds = commons.farBounds;
    rangeProducts = commons.rangeProducts;
    rangeBackendProducts = commons.rangeBackendProducts;

    osm = commons.osm;
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    analytics = commons.analytics;
    osmCacher = commons.osmCacher;
    shopsManager = commons.shopsManager;
  });

  test('shops fetched and then cached', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    expect(shops, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShops(any));

    clearInteractions(osm);
    clearInteractions(backend);

    // Fetch #2
    final shopsRes2 = await shopsManager.fetchShops(bounds);
    final shops2 = shopsRes2.unwrap();
    expect(shops2, equals(fullShops));
    // No backends expected to be touched! Cache expected to be used!
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);
  });

  test('shops products range update changes shops cache', () async {
    // Fetch #1
    final shopsRes1 = await shopsManager.fetchShops(bounds);
    final shops1 = shopsRes1.unwrap();
    expect(shops1, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShops(any));
    // Reset mocks
    clearInteractions(osm);
    clearInteractions(backend);

    // A range update
    final putRes = await shopsManager
        .putProductToShops(rangeProducts[2], [shops1.values.first]);
    expect(putRes.isOk, isTrue);

    // Fetch #2
    final shopsRes2 = await shopsManager.fetchShops(bounds);
    // Both backends expected to be NOT touched, cache expected to be used
    verifyNever(osm.fetchShops(bounds: anyNamed('bounds')));
    verifyNever(backend.requestShops(any));

    // Ensure +1 product in productsCount
    final shops2 = shopsRes2.unwrap();
    expect(shops2, isNot(equals(shops1)));
    expect(shops2.values.first.osmUID, equals(shops1.values.first.osmUID));
    expect(shops2.values.first.productsCount,
        equals(shops1.values.first.productsCount + 1));
  });

  test(
      'shops products range update changes shops cache when '
      'the shop had no backend shop before', () async {
    final osmShops = [
      OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..name = 'shop1'
        ..type = 'supermarket'
        ..longitude = 15
        ..latitude = 15),
    ];
    final backendShops = <BackendShop>[];
    when(osm.fetchShops(bounds: anyNamed('bounds')))
        .thenAnswer((_) async => Ok(osmShops));
    when(backend.requestShops(any)).thenAnswer((_) async => Ok(backendShops));
    final fullShops = {
      osmShops[0].osmUID: Shop((e) => e..osmShop.replace(osmShops[0])),
    };

    // Fetch #1
    final shopsRes1 = await shopsManager.fetchShops(bounds);
    final shops1 = shopsRes1.unwrap();
    expect(shops1, equals(fullShops));
    expect(shops1.values.first.backendShop, isNull);
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShops(any));
    // Reset mocks
    clearInteractions(osm);
    clearInteractions(backend);

    // A range update
    final putRes = await shopsManager
        .putProductToShops(rangeProducts[2], [shops1.values.first]);
    expect(putRes.isOk, isTrue);

    // Fetch #2
    final shopsRes2 = await shopsManager.fetchShops(bounds);
    // Both backends expected to be NOT touched, cache expected to be used
    verifyNever(osm.fetchShops(bounds: anyNamed('bounds')));
    verifyNever(backend.requestShops(any));

    // Ensure a BackendShop is now created even though it didn't exist before
    final shops2 = shopsRes2.unwrap();
    expect(shops2, isNot(equals(shops1)));
    expect(shops2.values.first.osmUID, equals(shops1.values.first.osmUID));
    expect(shops2.values.first.backendShop, isNotNull);
    expect(
        shops2.values.first.backendShop,
        equals(BackendShop((e) => e
          ..osmUID = shops1.values.first.osmUID
          ..productsCount = 1)));
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
    verify(backend.requestShops(any)).called(1);
  });

  test('shops fetch when cache exists but it is for another area', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1
    final shopsRes = await shopsManager.fetchShops(bounds);
    expect(shopsRes.isOk, isTrue);
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShops(any));

    clearInteractions(osm);
    clearInteractions(backend);

    // Fetch #2, another area
    final shopsRes2 = await shopsManager.fetchShops(farBounds);
    expect(shopsRes2.isOk, isTrue);
    // Both backends expected to be touched again!
    // Because the requested area is too far away from the cached one
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShops(any));
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
    when(backend.requestShops(any)).thenAnswer((_) async {
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
    verify(backend.requestShops(any)).called(2);
  });

  test('all shops loads failed', () async {
    when(osm.fetchShops(bounds: anyNamed('bounds'))).thenAnswer((_) async {
      return Err(OpenStreetMapError.OTHER);
    });
    when(backend.requestShops(any)).thenAnswer((_) async {
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
    when(backend.requestShops(any)).thenAnswer((_) async {
      return Ok(backendShops);
    });

    final shopsRes = await shopsManager.fetchShops(bounds);
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));

    // First call fails with a network errors, other calls don't happen.
    verify(osm.fetchShops(bounds: anyNamed('bounds'))).called(1);
    verifyNever(backend.requestShops(any));
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
    when(backend.requestShops(any)).thenAnswer((_) async => Ok(const []));

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
    // Store persistent cache
    final osmShopsInPersistentCacheShops = [
      osmShops.first,
    ];
    final shopsCreatedFromCache = {
      osmShops.first.osmUID: fullShops[osmShops.first.osmUID]
    };
    final now = DateTime.now();
    final cache = await osmCacher.cacheShops(
        now, bounds.center.makeSquare(1), osmShopsInPersistentCacheShops);

    // Fetch
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    // Verify data from cache was used
    expect(shops, equals(shopsCreatedFromCache));
    expect(shops, isNot(equals(fullShops)));
    // OSM expected to be not touched since fresh persistent cache exists
    verifyZeroInteractions(osm);

    // We expect the persistent cache to be unchanged
    expect(await osmCacher.getCachedShops(), equals([cache]));
  });

  test('shops fetch: persistent OSM cache is old', () async {
    // Store OLD persistent cache
    final osmShopsInPersistentCacheShops = [
      osmShops.first,
    ];
    final shopsCreatedFromCache = {
      osmShops.first.osmUID: fullShops[osmShops.first.osmUID]
    };
    final now = DateTime.now().subtract(const Duration(
        days: ShopsManager.DAYS_BEFORE_PERSISTENT_CACHE_IS_OLD + 1));
    final oldCache = await osmCacher.cacheShops(
        now, bounds.center.makeSquare(1), osmShopsInPersistentCacheShops);

    // Fetch
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    // Verify data from cache was NOT used
    expect(shops, isNot(equals(shopsCreatedFromCache)));
    expect(shops, equals(fullShops));
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
    final osmShopsInPersistentCacheShops = [
      osmShops.first,
    ];
    final shopsCreatedFromCache = {
      osmShops.first.osmUID: fullShops[osmShops.first.osmUID]
    };
    final now = DateTime.now().subtract(const Duration(
        days: ShopsManager.DAYS_BEFORE_PERSISTENT_CACHE_IS_OLD + 1));
    final oldCache = await osmCacher.cacheShops(
        now, bounds.center.makeSquare(1), osmShopsInPersistentCacheShops);

    // OSM returns errors
    when(osm.fetchShops(bounds: anyNamed('bounds'))).thenAnswer((_) async {
      return Err(OpenStreetMapError.OTHER);
    });

    // Fetch
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    // Verify data from cache WAS used because OSM backend gives errors
    expect(shops, equals(shopsCreatedFromCache));
    expect(shops, isNot(equals(fullShops)));
    // OSM expected to be touched because the persistent cache is old
    verify(osm.fetchShops(bounds: anyNamed('bounds')));

    // We expect the persistent cache to be unchanged because OSM is not responsive
    expect(await osmCacher.getCachedShops(), equals([oldCache]));
  });

  test('shops fetch: persistent OSM cache is ancient, and OSM gives errors',
      () async {
    // Store ANCIENT persistent cache
    final osmShopsInPersistentCacheShops = [
      osmShops.first,
    ];
    final now = DateTime.now().subtract(const Duration(
        days: ShopsManager.DAYS_BEFORE_PERSISTENT_CACHE_IS_ANCIENT + 1));
    await osmCacher.cacheShops(
        now, bounds.center.makeSquare(1), osmShopsInPersistentCacheShops);

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

  test('shops products range fetch and update', () async {
    final shop = fullShops.values.first;
    // Set up the range
    // NOTE: no backendProducts[2]
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmUID = shop.osmUID
        ..products.addAll([rangeBackendProducts[0], rangeBackendProducts[1]])
        ..productsLastSeenUtc.addAll({
          rangeBackendProducts[0].barcode: 123456,
          rangeBackendProducts[1].barcode: 123457,
        })),
    ];
    when(backend.requestProductsAtShops(any))
        .thenAnswer((_) async => Ok(backendProductsAtShops));

    // First fetch
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    final range1 = rangeRes1.unwrap();
    expect(range1.products.length, equals(2));
    expect(range1.products[0], equals(rangeProducts[0]));
    expect(range1.products[1], equals(rangeProducts[1]));
    expect(range1.shop, equals(shop));
    expect(range1.lastSeenSecs(rangeProducts[0]), equals(123456));
    expect(range1.lastSeenSecs(rangeProducts[1]), equals(123457));

    // The first fetch call did send requests
    verify(backend.requestProductsAtShops(any));
    verify(productsObtainer.inflateProducts(any));
    verifyNever(productsObtainer.inflate(any));

    clearInteractions(backend);
    clearInteractions(productsObtainer);

    // Second fetch
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));

    // The second fetch DID NOT send request (it used cache)
    verifyNever(backend.requestProductsAtShops(any));
    verifyNever(productsObtainer.inflateProducts(any));
    verifyNever(productsObtainer.inflate(any));

    // Range update
    verifyNever(backend.putProductToShop(any, any));
    final putRes =
        await shopsManager.putProductToShops(rangeProducts[2], [shop]);
    expect(putRes.isOk, isTrue);
    verify(backend.putProductToShop(any, any));

    // Third fetch
    final rangeRes3 = await shopsManager.fetchShopProductRange(shop);
    final range3 = rangeRes3.unwrap();
    expect(range3, isNot(equals(range2)));
    expect(range3.products.length, equals(3));
    expect(range3.products, equals(rangeProducts));
    expect(range3.shop, equals(shop));
    expect(range3.lastSeenSecs(rangeProducts[0]), equals(123456));
    expect(range3.lastSeenSecs(rangeProducts[1]), equals(123457));
    // Added less than 10 secs ago
    final now = DateTime.now().secondsSinceEpoch;
    expect(now - range3.lastSeenSecs(rangeProducts[2]), lessThan(10));

    // The third fetch DID NOT send request (it used updated cache)
    verifyNever(backend.requestProductsAtShops(any));
    verifyNever(productsObtainer.inflate(any));
    verifyNever(productsObtainer.inflateProducts(any));
  });

  test('shops products range force reload', () async {
    final shop = fullShops.values.first;
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmUID = shop.osmUID
        ..products.addAll([rangeBackendProducts[0], rangeBackendProducts[1]])
        ..productsLastSeenUtc.addAll({
          rangeBackendProducts[0].barcode: 123456,
          rangeBackendProducts[1].barcode: 123457,
        })),
    ];
    when(backend.requestProductsAtShops(any))
        .thenAnswer((_) async => Ok(backendProductsAtShops));

    // First fetch
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    final range1 = rangeRes1.unwrap();
    // The first fetch call did send requests
    verify(backend.requestProductsAtShops(any));
    verifyNever(productsObtainer.inflate(any));
    verify(productsObtainer.inflateProducts(any));

    clearInteractions(backend);
    clearInteractions(productsObtainer);

    // Second fetch
    final rangeRes2 =
        await shopsManager.fetchShopProductRange(shop, noCache: true);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));

    // The second fetch call again DID send requests, because was asked
    // to explicitly
    verify(backend.requestProductsAtShops(any));
    verifyNever(productsObtainer.inflate(any));
    verify(productsObtainer.inflateProducts(any));
  });

  test('shop creation', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1
    final initialShopsRes = await shopsManager.fetchShops(bounds);
    final initialShops = initialShopsRes.unwrap();
    expect(initialShops, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShops(any));

    clearInteractions(osm);
    clearInteractions(backend);

    // Create a shop
    verifyNever(backend.createShop());
    final newShopRes = await shopsManager.createShop(
        name: 'New cool shop',
        coord: Coord(lat: 15, lon: 15),
        type: ShopType.supermarket);
    final newShop = newShopRes.unwrap();
    expect(newShop.name, equals('New cool shop'));

    // Fetch #2
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    // Expect new shops result to be same as the initial +1 shop
    expect(shops, isNot(equals(initialShops)));
    expect(shops.length, equals(initialShops.length + 1));
    for (final initialShop in initialShops.values) {
      expect(shops.values, contains(initialShop));
    }
    // The new shop is expected to be in the result
    expect(shops.values, contains(newShop));

    // Both backends expected to be NOT touched, cache expected to be used
    verifyNever(osm.fetchShops(bounds: anyNamed('bounds')));
    verifyNever(backend.requestShops(any));
  });

  test('shop creation adds the shop to persistent OSM cache', () async {
    // First the territory should be put into persistent cache by a fetch
    await shopsManager.fetchShops(bounds);

    // Create a shop
    final newShopRes = await shopsManager.createShop(
        name: 'New cool shop',
        coord: Coord(lat: 15, lon: 15),
        type: ShopType.supermarket);
    final newShop = newShopRes.unwrap();
    expect(newShop.name, equals('New cool shop'));

    // Expecting all previous shops + the new shop
    final expectedAllShops = Map.from(fullShops);
    expectedAllShops[newShop.osmUID] = newShop;
    expect((await shopsManager.fetchShops(bounds)).unwrap(),
        equals(expectedAllShops));

    // Create a NEW shops manager with same persistent cache
    shopsManager = ShopsManager(
        OpenStreetMap.forTesting(
            overpass: osm, configManager: FakeMobileAppConfigManager()),
        backend,
        productsObtainer,
        analytics,
        osmCacher);
    // Expecting the new shop to be in the cache
    expect((await shopsManager.fetchShops(bounds)).unwrap(),
        equals(expectedAllShops));
  });

  test('put product to shop analytics', () async {
    expect(analytics.allEvents(), equals([]));

    // Success
    await shopsManager.putProductToShops(
        rangeProducts[2], fullShops.values.toList());
    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.firstSentEvent('product_put_to_shop').second,
        equals({
          'barcode': rangeProducts[2].barcode,
          'shops': fullShops.values
              .toList()
              .map((e) => e.osmUID)
              .toList()
              .join(', '),
        }));
    analytics.clearEvents();

    // Failure
    when(backend.putProductToShop(any, any))
        .thenAnswer((_) async => Err(BackendError.other()));
    await shopsManager.putProductToShops(
        rangeProducts[2], fullShops.values.toList());
    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.firstSentEvent('product_put_to_shop_failure').second,
        equals({
          'barcode': rangeProducts[2].barcode,
          'shops': fullShops.values
              .toList()
              .map((e) => e.osmUID)
              .toList()
              .join(', '),
        }));
    analytics.clearEvents();
  });

  test('shop creation analytics', () async {
    expect(analytics.allEvents(), equals([]));

    // Create a shop successfully
    await shopsManager.createShop(
        name: 'New cool shop',
        coord: Coord(lat: 16, lon: 15),
        type: ShopType.supermarket);
    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.firstSentEvent('create_shop_success').second,
        equals({
          'name': 'New cool shop',
          'lat': 16,
          'lon': 15,
        }));

    analytics.clearEvents();

    // Create a shop failure
    when(backend.createShop(
            name: anyNamed('name'),
            coord: anyNamed('coord'),
            type: anyNamed('type')))
        .thenAnswer((_) async => Err(BackendError.other()));
    await shopsManager.createShop(
        name: 'New cool shop',
        coord: Coord(lat: 16, lon: 15),
        type: ShopType.supermarket);
    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.firstSentEvent('create_shop_failure').second,
        equals({
          'name': 'New cool shop',
          'lat': 16,
          'lon': 15,
        }));
    analytics.clearEvents();
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
    when(backend.requestShops(any)).thenAnswer((_) async => Ok(backendShops));

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

  test('clear cache', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1, which will create cache
    await shopsManager.fetchShops(bounds);
    // Persistent cache should created too
    expect(await osmCacher.getCachedShops(), isNotEmpty);

    clearInteractions(osm);
    clearInteractions(backend);

    // Fetch #2 will use cache and therefore won't touch backends
    await shopsManager.fetchShops(bounds);
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Clear cache
    await shopsManager.clearCache();
    // Persistent cache should be cleared too
    expect(await osmCacher.getCachedShops(), isEmpty);

    // Fetch #3 is run after we cleared cache so backends
    // are expected to be touched
    await shopsManager.fetchShops(bounds);
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShops(any));
    // Persistent cache expected to be refilled
    expect(await osmCacher.getCachedShops(), isNotEmpty);
  });

  test('clear cache notifies listeners', () async {
    final listener = MockShopsManagerListener();
    shopsManager.addListener(listener);

    verifyZeroInteractions(listener);
    await shopsManager.clearCache();
    verify(listener.onLocalShopsChange());
  });
}
