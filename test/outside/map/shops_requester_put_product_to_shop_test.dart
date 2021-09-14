import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_requester.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import 'shops_requester_test_commons.dart';

void main() {
  late ShopsRequesterTestCommons commons;
  late MockOpenStreetMap osm;
  late MockBackend backend;
  late MockProductsObtainer productsObtainer;
  late ShopsRequester shopsRequester;

  setUp(() async {
    commons = ShopsRequesterTestCommons();
    osm = commons.osm;
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    shopsRequester = ShopsRequester(osm, backend, productsObtainer);
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

    when(backend.putProductToShop(any, any))
        .thenAnswer((_) async => Ok(None()));

    final result = await shopsRequester.putProductToShops(product, shops);
    expect(result.isOk, isTrue);
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
    when(backend.putProductToShop(any, any)).thenAnswer((_) async {
      calls += 1;
      if (calls >= 2) {
        return Err(BackendError.other());
      }
      return Ok(None());
    });

    final result = await shopsRequester.putProductToShops(product, shops);
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
          ..osmId = '1'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '1'
          ..productsCount = 2)))
    ];

    when(backend.putProductToShop(any, any))
        .thenAnswer((_) async => Err(BackendError.other()));

    final result = await shopsRequester.putProductToShops(product, shops);
    // Expecting an error
    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
  });
}