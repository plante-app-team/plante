import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/cmds/put_product_to_shop_cmd.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager_backend_worker.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_backend.dart';
import 'shops_manager_backend_worker_test_commons.dart';

void main() {
  late ShopsManagerBackendWorkerTestCommons commons;
  late FakeBackend backend;
  late MockProductsObtainer productsObtainer;
  late ShopsManagerBackendWorker shopsManagerBackendWorker;

  setUp(() async {
    commons = ShopsManagerBackendWorkerTestCommons();
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    shopsManagerBackendWorker =
        ShopsManagerBackendWorker(backend, productsObtainer);
  });

  test('putProductToShops good scenario', () async {
    final product = Product((e) => e.barcode = '123');
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar2'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..productsCount = 2)))
    ];

    backend.setResponse_testing(PUT_PRODUCT_TO_SHOP_CMD, '{}');
    expect(
        backend.getRequestsMatching_testing(PUT_PRODUCT_TO_SHOP_CMD), isEmpty);

    final result = await shopsManagerBackendWorker.putProductToShops(
        product, shops, ProductAtShopSource.MANUAL);
    expect(result.isOk, isTrue);

    final request =
        backend.getRequestsMatching_testing(PUT_PRODUCT_TO_SHOP_CMD).first;
    expect(request.url.queryParameters['source'],
        equals(ProductAtShopSource.MANUAL.persistentName));
  });

  test('putProductToShops error in the middle', () async {
    final product = Product((e) => e.barcode = '123');
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar2'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar3'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..productsCount = 2)))
    ];

    var calls = 0;
    backend.setResponseFunction_testing(PUT_PRODUCT_TO_SHOP_CMD, (req) {
      calls += 1;
      if (calls >= 2) {
        return Err(500);
      }
      return Ok('{}');
    });

    final result = await shopsManagerBackendWorker.putProductToShops(
        product, shops, ProductAtShopSource.MANUAL);
    // Expecting an error
    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
    // Expecting the third call to not happen
    expect(calls, equals(2));
  });

  test('putProductToShops all errors', () async {
    final product = Product((e) => e.barcode = '123');
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..productsCount = 2)))
    ];

    backend.setResponse_testing(PUT_PRODUCT_TO_SHOP_CMD, '', responseCode: 500);

    final result = await shopsManagerBackendWorker.putProductToShops(
        product, shops, ProductAtShopSource.MANUAL);
    // Expecting an error
    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
  });
}
