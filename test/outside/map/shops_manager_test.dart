import 'dart:io';
import 'dart:math';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_response.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:test/test.dart';

import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/shops_manager.dart';

import 'shops_manager_test.mocks.dart';

@GenerateMocks([OpenStreetMap, Backend, ProductsManager, ShopsManagerListener])
void main() {
  late MockOpenStreetMap _osm;
  late MockBackend _backend;
  late ShopsManager _shopsManager;
  late MockProductsManager _productsManager;

  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmId = '1'
      ..longitude = 11
      ..latitude = 11
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmId = '1'
      ..productsCount = 2)));

  setUp(() async {
    _osm = MockOpenStreetMap();
    _backend = MockBackend();
    _productsManager = MockProductsManager();
    _shopsManager = ShopsManager(_osm, _backend, _productsManager);
  });

  test('fetchProductsAtShops good scenario', () async {
    final osmShops = [
      OsmShop((e) => e
        ..osmId = '1'
        ..name = 'shop1'
        ..type = 'supermarket'
        ..longitude = 123
        ..latitude = 321),
      OsmShop((e) => e
        ..osmId = '2'
        ..name = 'shop2'
        ..type = 'convenience'
        ..longitude = 124
        ..latitude = 322),
    ];
    when(_osm.fetchShops(any, any)).thenAnswer((_) async => Ok(osmShops));

    final backendShops = [
      BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 2
      ),
      BackendShop((e) => e
        ..osmId = '2'
        ..productsCount = 1),
    ];
    when(_backend.requestShops(any)).thenAnswer((_) async => Ok(backendShops));

    final expectedShops = {
      osmShops[0].osmId: Shop((e) => e
        ..osmShop.replace(osmShops[0])
        ..backendShop.replace(backendShops[0])),
      osmShops[1].osmId: Shop((e) => e
        ..osmShop.replace(osmShops[1])
        ..backendShop.replace(backendShops[1])),
    };

    final shopsRes = await _shopsManager.fetchShops(const Point(0, 0), const Point(1, 1));
    final shops = shopsRes.unwrap();
    expect(shops, equals(expectedShops));
  });

  test('fetchProductsAtShops osm error', () async {
    when(_osm.fetchShops(any, any)).thenAnswer((_) async =>
        Err(OpenStreetMapError.NETWORK));

    final backendShops = [
      BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 2
      ),
      BackendShop((e) => e
        ..osmId = '2'
        ..productsCount = 1),
    ];
    when(_backend.requestShops(any)).thenAnswer((_) async => Ok(backendShops));

    final shopsRes = await _shopsManager.fetchShops(const Point(0, 0), const Point(1, 1));
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });

  test('fetchProductsAtShops backend error', () async {
    final osmShops = [
      OsmShop((e) => e
        ..osmId = '1'
        ..name = 'shop1'
        ..type = 'supermarket'
        ..longitude = 123
        ..latitude = 321)
    ];
    when(_osm.fetchShops(any, any)).thenAnswer((_) async => Ok(osmShops));
    when(_backend.requestShops(any)).thenAnswer((_) async => Err(BackendError.other()));

    final shopsRes = await _shopsManager.fetchShops(const Point(0, 0), const Point(1, 1));
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.OTHER));
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
    when(_backend.requestProductsAtShops(any)).thenAnswer((_) async =>
        Ok(backendProductsAtShops));

    final products = [
      Product((e) => e.barcode = '123'),
      Product((e) => e.barcode = '124'),
    ];
    when(_productsManager.inflate(backendProducts[0]))
        .thenAnswer((_) async => Ok(products[0]));
    when(_productsManager.inflate(backendProducts[1]))
        .thenAnswer((_) async => Ok(products[1]));

    final result = await _shopsManager.fetchShopProductRange(aShop);
    expect(result.isOk, isTrue);

    final expectedShopProductRange = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(products)
      ..productsLastSeenSecsUtc.addEntries(
          backendProductsAtShops[0].productsLastSeenUtc.entries));
    expect(result.unwrap(), equals(expectedShopProductRange));
  });

  test('fetchShopProductRange backend error', () async {
    when(_backend.requestProductsAtShops(any)).thenAnswer((_) async =>
        Err(BackendError.fromResp(BackendResponse.fromError(
            Exception(''), Uri.parse('https://ya.ru')))));

    final result = await _shopsManager.fetchShopProductRange(aShop);

    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
  });

  test('fetchShopProductRange backend network error', () async {
    when(_backend.requestProductsAtShops(any)).thenAnswer((_) async =>
        Err(BackendError.fromResp(BackendResponse.fromError(
            const SocketException(''), Uri.parse('https://ya.ru')))));

    final result = await _shopsManager.fetchShopProductRange(aShop);

    expect(result.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });

  test('fetchShopProductRange no products', () async {
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e.osmId = aShop.osmId),
    ];
    when(_backend.requestProductsAtShops(any)).thenAnswer((_) async =>
        Ok(backendProductsAtShops));

    final result = await _shopsManager.fetchShopProductRange(aShop);
    expect(result.isOk, isTrue);

    final expectedShopProductRange = ShopProductRange((e) => e.shop.replace(aShop));
    expect(result.unwrap(), equals(expectedShopProductRange));
  });

  test('fetchShopProductRange single products manager error while inflating backend products', () async {
    final backendProducts = [
      BackendProduct((e) => e.barcode = '123'),
      BackendProduct((e) => e.barcode = '124'),
    ];
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmId = aShop.osmId
        ..products.addAll([backendProducts[0], backendProducts[1]])),
    ];
    when(_backend.requestProductsAtShops(any)).thenAnswer((_) async =>
        Ok(backendProductsAtShops));

    final products = [
      Product((e) => e.barcode = '123'),
    ];
    when(_productsManager.inflate(backendProducts[0]))
        .thenAnswer((_) async => Ok(products[0]));
    // An error here!
    when(_productsManager.inflate(backendProducts[1]))
        .thenAnswer((_) async => Err(ProductsManagerError.NETWORK_ERROR));

    final result = await _shopsManager.fetchShopProductRange(aShop);
    expect(result.isOk, isTrue);

    final expectedShopProductRange = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(products));
    // No errors expected because one of the products is received
    expect(result.unwrap(), equals(expectedShopProductRange));
  });

  test('fetchShopProductRange all products manager errors while inflating backend products', () async {
    final backendProducts = [
      BackendProduct((e) => e.barcode = '123'),
      BackendProduct((e) => e.barcode = '124'),
    ];
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmId = aShop.osmId
        ..products.addAll([backendProducts[0], backendProducts[1]])),
    ];
    when(_backend.requestProductsAtShops(any)).thenAnswer((_) async =>
        Ok(backendProductsAtShops));

    // All error here!
    when(_productsManager.inflate(backendProducts[0]))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));
    when(_productsManager.inflate(backendProducts[1]))
        .thenAnswer((_) async => Err(ProductsManagerError.NETWORK_ERROR));

    final result = await _shopsManager.fetchShopProductRange(aShop);
    // Last error received from ShopsManager is expected to be what we get here
    expect(result.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });

  test('putProductToShops good scenario', () async {
    final product = Product((e) => e.barcode = '123');
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '1'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '1'
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '2'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar2'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '2'
          ..productsCount = 2)))
    ];

    when(_backend.putProductToShop(any, any)).thenAnswer((_) async => Ok(None()));

    final listener = MockShopsManagerListener();
    when(listener.onLocalShopsChange()).thenAnswer((_) {});

    _shopsManager.addListener(listener);
    verifyNever(listener.onLocalShopsChange());

    final result = await _shopsManager.putProductToShops(product, shops);
    expect(result.isOk, isTrue);
    verify(listener.onLocalShopsChange()).called(1);
  });

  test('putProductToShops error in the middle', () async {
    final product = Product((e) => e.barcode = '123');
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '1'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '1'
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '2'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar2'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '2'
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '3'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar3'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '3'
          ..productsCount = 2)))
    ];

    var calls = 0;
    when(_backend.putProductToShop(any, any)).thenAnswer((_) async {
      calls += 1;
      if (calls >= 2) {
        return Err(BackendError.other());
      }
      return Ok(None());
    });

    final listener = MockShopsManagerListener();
    when(listener.onLocalShopsChange()).thenAnswer((_) {});

    _shopsManager.addListener(listener);
    verifyNever(listener.onLocalShopsChange());

    final result = await _shopsManager.putProductToShops(product, shops);
    // Expecting an error
    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
    // Expecting the third call to not happen
    expect(calls, equals(2));
    // Expecting the listener to be notified
    verify(listener.onLocalShopsChange()).called(1);
  });

  test('putProductToShops all errors', () async {
    final product = Product((e) => e.barcode = '123');
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '1'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '1'
          ..productsCount = 2)))
    ];

    when(_backend.putProductToShop(any, any)).thenAnswer((_) async => Err(BackendError.other()));

    final listener = MockShopsManagerListener();
    when(listener.onLocalShopsChange()).thenAnswer((_) {});

    _shopsManager.addListener(listener);
    verifyNever(listener.onLocalShopsChange());

    final result = await _shopsManager.putProductToShops(product, shops);
    // Expecting an error
    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
    // Expecting the listener to be not notified
    verifyNever(listener.onLocalShopsChange());
  });

  test('createShop good scenario', () async {
    when(_backend.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type')
    )).thenAnswer((_) async => Ok(BackendShop((e) => e
      ..osmId = '123456'
      ..productsCount = 0)));

    final listener = MockShopsManagerListener();
    when(listener.onLocalShopsChange()).thenAnswer((_) {});

    _shopsManager.addListener(listener);
    verifyNever(listener.onLocalShopsChange());

    final result = await _shopsManager.createShop(
        name: 'Horns and Hooves',
        coords: const Point<double>(10, 20),
        type: ShopType.supermarket);
    expect(result.isOk, isTrue);
    verify(listener.onLocalShopsChange()).called(1);

    final expectedResult = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '123456'
        ..longitude = 10
        ..latitude = 20
        ..name = 'Horns and Hooves'
        ..type = ShopType.supermarket.osmName))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '123456'
        ..productsCount = 0)));
    expect(result.unwrap(), equals(expectedResult));
  });

  test('createShop caches created shop', () async {
    when(_backend.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type')
    )).thenAnswer((_) async => Ok(BackendShop((e) => e
      ..osmId = '123456'
      ..productsCount = 0)));

    final result = await _shopsManager.createShop(
        name: 'Horns and Hooves',
        coords: const Point<double>(10, 20),
        type: ShopType.supermarket);
    final createdShop = result.unwrap();

    // Both OSM and backend have no shops for us
    when(_osm.fetchShops(any, any)).thenAnswer((_) async => Ok(const []));
    when(_backend.requestShops(any)).thenAnswer((_) async => Ok(const []));

    // But we expect the created shop to be cached and given to us anyways
    final shops = await _shopsManager.fetchShops(const Point(0, 0), const Point(1, 1));
    expect(shops.unwrap(), equals({ createdShop.osmId: createdShop }));
  });

  test('createShop error', () async {
    when(_backend.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type')
    )).thenAnswer((_) async => Err(BackendError.other()));

    final listener = MockShopsManagerListener();
    when(listener.onLocalShopsChange()).thenAnswer((_) {});

    _shopsManager.addListener(listener);
    verifyNever(listener.onLocalShopsChange());

    final result = await _shopsManager.createShop(
        name: 'Horns and Hooves',
        coords: const Point<double>(10, 20),
        type: ShopType.supermarket);
    // Expecting an error
    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
    // Expecting the listener to be not notified
    verifyNever(listener.onLocalShopsChange());
  });
}
