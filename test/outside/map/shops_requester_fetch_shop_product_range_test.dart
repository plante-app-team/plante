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
import 'package:plante/outside/map/shops_requester.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import 'shops_requester_test_commons.dart';

void main() {
  late ShopsRequesterTestCommons commons;
  late MockOpenStreetMap osm;
  late MockBackend backend;
  late MockProductsObtainer productsObtainer;
  late ShopsRequester shopsRequester;

  late Shop aShop;

  setUp(() async {
    commons = ShopsRequesterTestCommons();
    osm = commons.osm;
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    aShop = commons.aShop;
    shopsRequester = ShopsRequester(osm, backend, productsObtainer);
  });

  test('fetchShopProductRange good scenario', () async {
    final backendProducts = [
      BackendProduct((e) => e.barcode = '123'),
      BackendProduct((e) => e.barcode = '124'),
    ];
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmId = aShop.osmId
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
    when(productsObtainer.inflate(backendProducts[0]))
        .thenAnswer((_) async => Ok(products[0]));
    when(productsObtainer.inflate(backendProducts[1]))
        .thenAnswer((_) async => Ok(products[1]));

    final result = await shopsRequester.fetchShopProductRange(aShop);
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

    final result = await shopsRequester.fetchShopProductRange(aShop);

    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
  });

  test('fetchShopProductRange backend network error', () async {
    when(backend.requestProductsAtShops(any)).thenAnswer((_) async => Err(
        BackendError.fromResp(BackendResponse.fromError(
            const SocketException(''), Uri.parse('https://ya.ru')))));

    final result = await shopsRequester.fetchShopProductRange(aShop);

    expect(result.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });

  test('fetchShopProductRange no products', () async {
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e.osmId = aShop.osmId),
    ];
    when(backend.requestProductsAtShops(any))
        .thenAnswer((_) async => Ok(backendProductsAtShops));

    final result = await shopsRequester.fetchShopProductRange(aShop);
    expect(result.isOk, isTrue);

    final expectedShopProductRange =
        ShopProductRange((e) => e.shop.replace(aShop));
    expect(result.unwrap(), equals(expectedShopProductRange));
  });

  test(
      'fetchShopProductRange single products manager error while inflating backend products',
      () async {
    final backendProducts = [
      BackendProduct((e) => e.barcode = '123'),
      BackendProduct((e) => e.barcode = '124'),
    ];
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmId = aShop.osmId
        ..products.addAll([backendProducts[0], backendProducts[1]])),
    ];
    when(backend.requestProductsAtShops(any))
        .thenAnswer((_) async => Ok(backendProductsAtShops));

    final products = [
      Product((e) => e.barcode = '123'),
    ];
    when(productsObtainer.inflate(backendProducts[0]))
        .thenAnswer((_) async => Ok(products[0]));
    // An error here!
    when(productsObtainer.inflate(backendProducts[1]))
        .thenAnswer((_) async => Err(ProductsManagerError.NETWORK_ERROR));

    final result = await shopsRequester.fetchShopProductRange(aShop);
    expect(result.isOk, isTrue);

    final expectedShopProductRange = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(products));
    // No errors expected because one of the products is received
    expect(result.unwrap(), equals(expectedShopProductRange));
  });

  test(
      'fetchShopProductRange all products manager errors while inflating backend products',
      () async {
    final backendProducts = [
      BackendProduct((e) => e.barcode = '123'),
      BackendProduct((e) => e.barcode = '124'),
    ];
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmId = aShop.osmId
        ..products.addAll([backendProducts[0], backendProducts[1]])),
    ];
    when(backend.requestProductsAtShops(any))
        .thenAnswer((_) async => Ok(backendProductsAtShops));

    // All error here!
    when(productsObtainer.inflate(backendProducts[0]))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));
    when(productsObtainer.inflate(backendProducts[1]))
        .thenAnswer((_) async => Err(ProductsManagerError.NETWORK_ERROR));

    final result = await shopsRequester.fetchShopProductRange(aShop);
    // Last error received from ShopsManager is expected to be what we get here
    expect(result.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });
}
