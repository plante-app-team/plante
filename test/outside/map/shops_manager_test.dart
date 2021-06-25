import 'dart:math';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:test/test.dart';

import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/map/open_street_map.dart';

import '../../fake_analytics.dart';
import 'shops_manager_test.mocks.dart';

@GenerateMocks([OpenStreetMap, Backend, ProductsManager, ShopsManagerListener])
void main() {
  late MockOpenStreetMap osm;
  late MockBackend backend;
  late MockProductsManager productsManager;
  late FakeAnalytics analytics;
  late ShopsManager shopsManager;

  final osmShops = [
    OsmShop((e) => e
      ..osmId = '1'
      ..name = 'shop1'
      ..type = 'supermarket'
      ..longitude = 15
      ..latitude = 15),
    OsmShop((e) => e
      ..osmId = '2'
      ..name = 'shop2'
      ..type = 'convenience'
      ..longitude = 15
      ..latitude = 15),
  ];
  final backendShops = [
    BackendShop((e) => e
      ..osmId = '1'
      ..productsCount = 2
    ),
    BackendShop((e) => e
      ..osmId = '2'
      ..productsCount = 1),
  ];
  final fullShops = {
    osmShops[0].osmId: Shop((e) => e
      ..osmShop.replace(osmShops[0])
      ..backendShop.replace(backendShops[0])),
    osmShops[1].osmId: Shop((e) => e
      ..osmShop.replace(osmShops[1])
      ..backendShop.replace(backendShops[1])),
  };

  const northeast = Point(15.001, 15.001);
  const southwest = Point(14.999, 14.999);
  const farNortheast = Point(16.001, 16.001);
  const farSouthwest = Point(15.999, 15.999);

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

  setUp(() async {
    osm = MockOpenStreetMap();
    backend = MockBackend();
    productsManager = MockProductsManager();
    analytics = FakeAnalytics();
    when(backend.putProductToShop(any, any)).thenAnswer((_) async => Ok(None()));
    shopsManager = ShopsManager(osm, backend, productsManager, analytics);

    when(osm.fetchShops(any, any)).thenAnswer((_) async => Ok(osmShops));
    when(backend.requestShops(any)).thenAnswer((_) async => Ok(backendShops));

    when(productsManager.inflate(rangeBackendProducts[0]))
        .thenAnswer((_) async => Ok(rangeProducts[0]));
    when(productsManager.inflate(rangeBackendProducts[1]))
        .thenAnswer((_) async => Ok(rangeProducts[1]));
    when(productsManager.inflate(rangeBackendProducts[2]))
        .thenAnswer((_) async => Ok(rangeProducts[2]));

    when(backend.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type')
    )).thenAnswer((_) async => Ok(BackendShop((e) => e
      ..osmId = randInt(1, 99999).toString()
      ..productsCount = 0)));
  });

  test('shops fetched and then cached', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1
    final shopsRes = await shopsManager.fetchShops(northeast, southwest);
    final shops = shopsRes.unwrap();
    expect(shops, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(any, any));
    verify(backend.requestShops(any));

    clearInteractions(osm);
    clearInteractions(backend);

    // Fetch #2
    final shopsRes2 = await shopsManager.fetchShops(northeast, southwest);
    final shops2 = shopsRes2.unwrap();
    expect(shops2, equals(fullShops));
    // No backends expected to be touched! Cache expected to be used!
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);
  });

  test('shops products range update changes shops cache', () async {
    // Fetch #1
    final shopsRes1 = await shopsManager.fetchShops(northeast, southwest);
    final shops1 = shopsRes1.unwrap();
    expect(shops1, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(any, any));
    verify(backend.requestShops(any));
    // Reset mocks
    clearInteractions(osm);
    clearInteractions(backend);

    // A range update
    final putRes = await shopsManager
        .putProductToShops(rangeProducts[2], [shops1.values.first]);
    expect(putRes.isOk, isTrue);

    // Fetch #2
    final shopsRes2 = await shopsManager.fetchShops(northeast, southwest);
    // Both backends expected to be NOT touched, cache expected to be used
    verifyNever(osm.fetchShops(any, any));
    verifyNever(backend.requestShops(any));

    // Ensure +1 product in productsCount
    final shops2 = shopsRes2.unwrap();
    expect(shops2, isNot(equals(shops1)));
    expect(shops2.values.first.osmId, equals(shops1.values.first.osmId));
    expect(shops2.values.first.productsCount,
        equals(shops1.values.first.productsCount + 1));
  });

  test('cache behaviour when multiple shops fetches started at the same time', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1, no await
    final shopsFuture1 = shopsManager.fetchShops(northeast, southwest);
    final shopsFuture2 = shopsManager.fetchShops(northeast, southwest);
    final shopsFuture3 = shopsManager.fetchShops(northeast, southwest);
    final shopsFuture4 = shopsManager.fetchShops(northeast, southwest);

    // Await all
    final results = await Future.wait(
        [shopsFuture1, shopsFuture2, shopsFuture3, shopsFuture4]
    );
    for (final result in results) {
      expect(result.unwrap(), equals(fullShops));
    }
    // Both backends expected to be touched exactly once
    verify(osm.fetchShops(any, any)).called(1);
    verify(backend.requestShops(any)).called(1);
  });

  test('shops fetch when cache exists but it is for another area', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1
    final shopsRes = await shopsManager.fetchShops(northeast, southwest);
    expect(shopsRes.isOk, isTrue);
    // Both backends expected to be touched
    verify(osm.fetchShops(any, any));
    verify(backend.requestShops(any));

    clearInteractions(osm);
    clearInteractions(backend);

    // Fetch #2, another area
    final shopsRes2 = await shopsManager.fetchShops(farNortheast, farSouthwest);
    expect(shopsRes2.isOk, isTrue);
    // Both backends expected to be touched again!
    // Because the requested area is too far away from the cached one
    verify(osm.fetchShops(any, any));
    verify(backend.requestShops(any));
  });

  test('multiple failed shops load attempts and 1 successful', () async {
    // First request to each will fail, the others will succeed
    var osmLoadsCount = 0;
    var backendLoadsCount = 0;
    when(osm.fetchShops(any, any)).thenAnswer((_) async {
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

    final shopsRes = await shopsManager.fetchShops(northeast, southwest);
    expect(shopsRes.isOk, isTrue);

    // First call fails, second succeeds, but backend fails then.
    // So the third call will be the final one.
    verify(osm.fetchShops(any, any)).called(3);
    // First call fails, second succeeds.
    verify(backend.requestShops(any)).called(2);
  });

  test('all shops loads failed', () async {
    when(osm.fetchShops(any, any)).thenAnswer((_) async {
      return Err(OpenStreetMapError.OTHER);
    });
    when(backend.requestShops(any)).thenAnswer((_) async {
      return Err(BackendError.other());
    });
    final shopsRes = await shopsManager.fetchShops(northeast, southwest);
    expect(shopsRes.isErr, isTrue);
  });

  test('loading network error makes only for 1 load attempt', () async {
    // First request will fail, the others would succeed.
    // Would, if not for the network error!
    var osmLoadsCount = 0;
    when(osm.fetchShops(any, any)).thenAnswer((_) async {
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

    final shopsRes = await shopsManager.fetchShops(northeast, southwest);
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));

    // First call fails with a network errors, other calls don't happen.
    verify(osm.fetchShops(any, any)).called(1);
    verifyNever(backend.requestShops(any));
  });

  test('shops products range fetch and update', () async {
    final shop = fullShops.values.first;
    // Set up the range
    // NOTE: no backendProducts[2]
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmId = shop.osmId
        ..products.addAll([rangeBackendProducts[0], rangeBackendProducts[1]])
        ..productsLastSeenUtc.addAll({
          rangeBackendProducts[0].barcode: 123456,
          rangeBackendProducts[1].barcode: 123457,
        })),
    ];
    when(backend.requestProductsAtShops(any)).thenAnswer((_) async =>
        Ok(backendProductsAtShops));

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
    verify(productsManager.inflate(any));

    clearInteractions(backend);
    clearInteractions(productsManager);

    // Second fetch
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));

    // The second fetch DID NOT send request (it used cache)
    verifyNever(backend.requestProductsAtShops(any));
    verifyNever(productsManager.inflate(any));

    // Range update
    verifyNever(backend.putProductToShop(any, any));
    final putRes = await shopsManager.putProductToShops(rangeProducts[2], [shop]);
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
    verifyNever(productsManager.inflate(any));
  });

  test('shops products range force reload', () async {
    final shop = fullShops.values.first;
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmId = shop.osmId
        ..products.addAll([rangeBackendProducts[0], rangeBackendProducts[1]])
        ..productsLastSeenUtc.addAll({
          rangeBackendProducts[0].barcode: 123456,
          rangeBackendProducts[1].barcode: 123457,
        })),
    ];
    when(backend.requestProductsAtShops(any)).thenAnswer((_) async =>
        Ok(backendProductsAtShops));

    // First fetch
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    final range1 = rangeRes1.unwrap();
    // The first fetch call did send requests
    verify(backend.requestProductsAtShops(any));
    verify(productsManager.inflate(any));

    clearInteractions(backend);
    clearInteractions(productsManager);

    // Second fetch
    final rangeRes2 = await shopsManager
        .fetchShopProductRange(shop, noCache: true);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));

    // The second fetch call again DID send requests, because was asked
    // to explicitly
    verify(backend.requestProductsAtShops(any));
    verify(productsManager.inflate(any));
  });

  test('shop creation', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1
    final initialShopsRes = await shopsManager.fetchShops(northeast, southwest);
    final initialShops = initialShopsRes.unwrap();
    expect(initialShops, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(any, any));
    verify(backend.requestShops(any));

    clearInteractions(osm);
    clearInteractions(backend);

    // Create a shop
    verifyNever(backend.createShop());
    final newShopRes = await shopsManager.createShop(
        name: 'New cool shop',
        coords: const Point<double>(15, 15),
        type: ShopType.supermarket);
    final newShop = newShopRes.unwrap();
    expect(newShop.name, equals('New cool shop'));

    // Fetch #2
    final shopsRes = await shopsManager.fetchShops(northeast, southwest);
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
    verifyNever(osm.fetchShops(any, any));
    verifyNever(backend.requestShops(any));
  });

  test('put product to shop analytics', () async {
    expect(analytics.allEvents(), equals([]));

    // Success
    await shopsManager
        .putProductToShops(rangeProducts[2], fullShops.values.toList());
    expect(analytics.allEvents().length, equals(1));
    expect(analytics.firstSentEvent('product_put_to_shop').second, equals({
      'barcode': rangeProducts[2].barcode,
      'shops': fullShops.values.toList().map((e) => e.osmId).toList().join(', '),
    }));
    analytics.clearEvents();

    // Failure
    when(backend.putProductToShop(any, any)).thenAnswer((_) async =>
        Err(BackendError.other()));
    await shopsManager
        .putProductToShops(rangeProducts[2], fullShops.values.toList());
    expect(analytics.allEvents().length, equals(1));
    expect(analytics.firstSentEvent('product_put_to_shop_failure').second, equals({
      'barcode': rangeProducts[2].barcode,
      'shops': fullShops.values.toList().map((e) => e.osmId).toList().join(', '),
    }));
    analytics.clearEvents();
  });

  test('shop creation analytics', () async {
    expect(analytics.allEvents(), equals([]));

    // Create a shop successfully
    await shopsManager.createShop(
        name: 'New cool shop',
        coords: const Point<double>(15, 16),
        type: ShopType.supermarket);
    expect(analytics.allEvents().length, equals(1));
    expect(analytics.firstSentEvent('create_shop_success').second, equals({
      'name': 'New cool shop',
      'lat': 16,
      'lon': 15,
    }));

    analytics.clearEvents();

    // Create a shop failure
    when(backend.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type')
    )).thenAnswer((_) async => Err(BackendError.other()));
    await shopsManager.createShop(
        name: 'New cool shop',
        coords: const Point<double>(15, 16),
        type: ShopType.supermarket);
    expect(analytics.allEvents().length, equals(1));
    expect(analytics.firstSentEvent('create_shop_failure').second, equals({
      'name': 'New cool shop',
      'lat': 16,
      'lon': 15,
    }));
    analytics.clearEvents();
  });

  test('returned shops are within the requested bounds', () async {
    final osmShops = [
      OsmShop((e) => e
        ..osmId = '1'
        ..name = 'shop1'
        ..longitude = 15
        ..latitude = 15),
      OsmShop((e) => e
        ..osmId = '2'
        ..name = 'shop2'
        ..longitude = 15.0001
        ..latitude = 15.0001),
    ];
    when(osm.fetchShops(any, any)).thenAnswer((_) async => Ok(osmShops));
    when(backend.requestShops(any)).thenAnswer((_) async => Ok(backendShops));

    const northeast = Point<double>(15, 15);
    const southwest = Point(14.999, 14.999);

    // First request which shall initialize instance's cache
    var shopsRes = await shopsManager.fetchShops(northeast, southwest);
    var shops = shopsRes.unwrap();
    // Only shop 1 is expected because only it is within the bounds
    expect(shops.values.map((e) => e.osmId), equals([osmShops[0].osmId]));
    // Verify cache was not used
    verify(osm.fetchShops(any, any));

    clearInteractions(osm);

    // Secind request which shall use instance's cache
    shopsRes = await shopsManager.fetchShops(northeast, southwest);
    shops = shopsRes.unwrap();
    // Again only shop 1 is expected because only it is within the bounds
    expect(shops.values.map((e) => e.osmId), equals([osmShops[0].osmId]));
    // Verify cache WAS used
    verifyNever(osm.fetchShops(any, any));
  });
}
