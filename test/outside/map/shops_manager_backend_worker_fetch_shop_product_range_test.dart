import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_response.dart';
import 'package:plante/outside/map/shops_manager_backend_worker.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import 'shops_manager_backend_worker_test_commons.dart';

void main() {
  late ShopsManagerBackendWorkerTestCommons commons;
  late MockBackend backend;
  late MockProductsObtainer productsObtainer;
  late ShopsManagerBackendWorker shopsManagerBackendWorker;

  late Shop aShop;

  setUp(() async {
    commons = ShopsManagerBackendWorkerTestCommons();
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    aShop = commons.aShop;
    shopsManagerBackendWorker =
        ShopsManagerBackendWorker(backend, productsObtainer);
  });

  test('fetchShopProductRange good scenario', () async {
    final backendProducts = [
      BackendProduct((e) => e.barcode = '123'),
      BackendProduct((e) => e.barcode = '124'),
    ];
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmUID = aShop.osmUID
        ..products.addAll([backendProducts[0], backendProducts[1]])
        ..productsLastSeenUtc.addAll({
          backendProducts[0].barcode: 123456,
          backendProducts[1].barcode: 123457,
        })),
    ];
    when(backend.requestProductsAtShops(any))
        .thenAnswer((_) async => Ok(backendProductsAtShops));

    final products = [
      Product((e) => e.barcode = '123'),
      Product((e) => e.barcode = '124'),
    ];
    when(productsObtainer.inflateProducts(any))
        .thenAnswer((_) async => Ok(products));

    final result = await shopsManagerBackendWorker.fetchShopProductRange(aShop);
    expect(result.isOk, isTrue);

    final expectedShopProductRange = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(products)
      ..productsLastSeenSecsUtc
          .addEntries(backendProductsAtShops[0].productsLastSeenUtc.entries));
    expect(result.unwrap(), equals(expectedShopProductRange));
  });

  test('fetchShopProductRange backend error', () async {
    when(backend.requestProductsAtShops(any)).thenAnswer((_) async => Err(
        BackendError.fromResp(BackendResponse.fromError(
            Exception(''), Uri.parse('https://ya.ru')))));

    final result = await shopsManagerBackendWorker.fetchShopProductRange(aShop);

    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
  });

  test('fetchShopProductRange backend network error', () async {
    when(backend.requestProductsAtShops(any)).thenAnswer((_) async => Err(
        BackendError.fromResp(BackendResponse.fromError(
            const SocketException(''), Uri.parse('https://ya.ru')))));

    final result = await shopsManagerBackendWorker.fetchShopProductRange(aShop);

    expect(result.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });

  test('fetchShopProductRange no products', () async {
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e.osmUID = aShop.osmUID),
    ];
    when(backend.requestProductsAtShops(any))
        .thenAnswer((_) async => Ok(backendProductsAtShops));

    final result = await shopsManagerBackendWorker.fetchShopProductRange(aShop);
    expect(result.isOk, isTrue);

    final expectedShopProductRange =
        ShopProductRange((e) => e.shop.replace(aShop));
    expect(result.unwrap(), equals(expectedShopProductRange));
  });

  test(
      'fetchShopProductRange product manager error while inflating backend products',
      () async {
    final backendProducts = [
      BackendProduct((e) => e.barcode = '123'),
      BackendProduct((e) => e.barcode = '124'),
    ];
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmUID = aShop.osmUID
        ..products.addAll([backendProducts[0], backendProducts[1]])),
    ];
    when(backend.requestProductsAtShops(any))
        .thenAnswer((_) async => Ok(backendProductsAtShops));

    // All error here!
    when(productsObtainer.inflateProducts(any))
        .thenAnswer((_) async => Err(ProductsObtainerError.NETWORK));

    final result = await shopsManagerBackendWorker.fetchShopProductRange(aShop);
    // Last error received from ShopsManager is expected to be what we get here
    expect(result.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });
}
