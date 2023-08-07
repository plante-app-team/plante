import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/cmds/products_at_shops_cmd.dart';
import 'package:plante/outside/backend/cmds/put_product_to_shop_cmd.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late FakeBackend backend;
  late FakeProductsObtainer productsObtainer;
  late ShopsManager shopsManager;

  late Map<OsmUID, Shop> fullShops;

  late List<BackendProduct> rangeBackendProducts;
  late List<Product> rangeProducts;

  setUp(() async {
    commons = await ShopsManagerTestCommons.create();
    fullShops = commons.fullShops;
    rangeBackendProducts = commons.rangeBackendProducts;
    rangeProducts = commons.rangeProducts;

    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    shopsManager = commons.shopsManager;
  });

  tearDown(() async {
    await commons.dispose();
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
    backend.setResponse_testing(
        PRODUCTS_AT_SHOPS_CMD, backendProductsAtShops._toJsonResponse());

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
    expect(backend.getRequestsMatching_testing(PRODUCTS_AT_SHOPS_CMD),
        isNot(isEmpty));
    expect(productsObtainer.inflatesBackendProductsCount, greaterThan(0));

    backend.resetRequests_testing();
    productsObtainer.inflatesBackendProductsCount = 0;

    // Second fetch
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));

    // The second fetch DID NOT send request (it used cache)
    expect(backend.getRequestsMatching_testing(PRODUCTS_AT_SHOPS_CMD), isEmpty);
    expect(productsObtainer.inflatesBackendProductsCount, equals(0));

    // Range update
    expect(
        backend.getRequestsMatching_testing(PUT_PRODUCT_TO_SHOP_CMD), isEmpty);
    final putRes = await shopsManager.putProductToShops(
        rangeProducts[2], [shop], ProductAtShopSource.MANUAL);
    expect(putRes.isOk, isTrue);

    final putProductReq =
        backend.getRequestsMatching_testing(PUT_PRODUCT_TO_SHOP_CMD).first;
    expect(putProductReq.url.queryParameters['barcode'],
        equals(rangeProducts[2].barcode));
    expect(putProductReq.url.queryParameters['shopOsmUID'],
        equals(shop.osmUID.toString()));
    expect(putProductReq.url.queryParameters['source'],
        equals(ProductAtShopSource.MANUAL.persistentName));

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
    expect(backend.getRequestsMatching_testing(PRODUCTS_AT_SHOPS_CMD), isEmpty);
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
    backend.setResponse_testing(
        PRODUCTS_AT_SHOPS_CMD, backendProductsAtShops._toJsonResponse());

    // First fetch
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    final range1 = rangeRes1.unwrap();
    // The first fetch call did send requests
    expect(backend.getRequestsMatching_testing(PRODUCTS_AT_SHOPS_CMD),
        isNot(isEmpty));
    expect(productsObtainer.inflatesBackendProductsCount, greaterThan(0));
    // And listener was notified about cache update
    verify(listener.onLocalShopsChange());

    backend.resetRequests_testing();
    clearInteractions(listener);
    productsObtainer.inflatesBackendProductsCount = 0;

    // Second fetch
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));
    // The second fetch DID NOT send request (it used cache)
    expect(backend.getRequestsMatching_testing(PRODUCTS_AT_SHOPS_CMD), isEmpty);
    expect(productsObtainer.inflatesBackendProductsCount, equals(0));
    // And thus the listener was NOT notified
    verifyNever(listener.onLocalShopsChange());

    // Product is put to the shop
    final putRes = await shopsManager.putProductToShops(
        rangeProducts[2], [shop], ProductAtShopSource.MANUAL);
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
    backend.setResponse_testing(
        PRODUCTS_AT_SHOPS_CMD, backendProductsAtShops._toJsonResponse());

    // First fetch
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    final range1 = rangeRes1.unwrap();
    // The first fetch call did send requests
    expect(backend.getRequestsMatching_testing(PRODUCTS_AT_SHOPS_CMD),
        isNot(isEmpty));
    expect(productsObtainer.inflatesBackendProductsCount, greaterThan(0));

    backend.resetRequests_testing();
    productsObtainer.inflatesBackendProductsCount = 0;

    // Second fetch
    final rangeRes2 =
        await shopsManager.fetchShopProductRange(shop, noCache: true);
    final range2 = rangeRes2.unwrap();
    expect(range2, equals(range1));

    // The second fetch call again DID send requests, because was asked
    // to explicitly
    expect(backend.getRequestsMatching_testing(PRODUCTS_AT_SHOPS_CMD),
        isNot(isEmpty));
    expect(productsObtainer.inflatesBackendProductsCount, greaterThan(0));
  });
}

extension _ListProdutcsAtShop on List<BackendProductsAtShop> {
  String _toJsonResponse() {
    final map = {
      for (final value in this) value.osmUID.toString(): value.toJson()
    };
    return jsonEncode({PRODUCTS_AT_SHOPS_CMD_RESULT_FIELD: map});
  }
}
