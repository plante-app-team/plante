import 'package:mockito/mockito.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late MockBackend backend;
  late FakeProductsObtainer productsObtainer;
  late ShopsManager shopsManager;

  late Map<OsmUID, Shop> fullShops;

  late List<BackendProduct> rangeBackendProducts;
  late List<Product> rangeProducts;

  setUp(() async {
    commons = ShopsManagerTestCommons();
    fullShops = commons.fullShops;
    rangeBackendProducts = commons.rangeBackendProducts;
    rangeProducts = commons.rangeProducts;

    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    shopsManager = commons.shopsManager;
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
    expect(productsObtainer.inflatesBackendProductsCount, greaterThan(0));

    clearInteractions(backend);
    productsObtainer.inflatesBackendProductsCount = 0;

    // Second fetch
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));

    // The second fetch DID NOT send request (it used cache)
    verifyNever(backend.requestProductsAtShops(any));
    expect(productsObtainer.inflatesBackendProductsCount, equals(0));

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
    expect(productsObtainer.inflatesBackendProductsCount, equals(0));
  });

  test('shops products range listeners notification', () async {
    final listener = MockShopsManagerListener();
    shopsManager.addListener(listener);

    final shop = fullShops.values.first;
    // Set up the range
    // NOTE: no backendProducts[2]
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmUID = shop.osmUID
        ..products.addAll([rangeBackendProducts[0]])
        ..productsLastSeenUtc.addAll({
          rangeBackendProducts[0].barcode: 123456,
        })),
    ];
    when(backend.requestProductsAtShops(any))
        .thenAnswer((_) async => Ok(backendProductsAtShops));

    // First fetch
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    final range1 = rangeRes1.unwrap();
    // The first fetch call did send requests
    verify(backend.requestProductsAtShops(any));
    expect(productsObtainer.inflatesBackendProductsCount, greaterThan(0));
    // And listener was notified about cache update
    verify(listener.onLocalShopsChange());

    clearInteractions(backend);
    clearInteractions(listener);
    productsObtainer.inflatesBackendProductsCount = 0;

    // Second fetch
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));
    // The second fetch DID NOT send request (it used cache)
    verifyNever(backend.requestProductsAtShops(any));
    expect(productsObtainer.inflatesBackendProductsCount, equals(0));
    // And thus the listener was NOT notified
    verifyNever(listener.onLocalShopsChange());

    // Product is put to the shop
    final putRes =
        await shopsManager.putProductToShops(rangeProducts[2], [shop]);
    expect(putRes.isOk, isTrue);
    // Listener expected to be notified about cache update -
    // new product appeared!
    verify(listener.onLocalShopsChange());
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
    expect(productsObtainer.inflatesBackendProductsCount, greaterThan(0));

    clearInteractions(backend);
    productsObtainer.inflatesBackendProductsCount = 0;

    // Second fetch
    final rangeRes2 =
        await shopsManager.fetchShopProductRange(shop, noCache: true);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));

    // The second fetch call again DID send requests, because was asked
    // to explicitly
    verify(backend.requestProductsAtShops(any));
    expect(productsObtainer.inflatesBackendProductsCount, greaterThan(0));
  });
}
