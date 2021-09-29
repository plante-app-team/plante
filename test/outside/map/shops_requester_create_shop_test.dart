import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/map/shops_requester.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import 'shops_requester_test_commons.dart';

void main() {
  late ShopsRequesterTestCommons commons;
  late MockBackend backend;
  late MockProductsObtainer productsObtainer;
  late ShopsRequester shopsRequester;

  setUp(() async {
    commons = ShopsRequesterTestCommons();
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    shopsRequester = ShopsRequester(backend, productsObtainer);
  });

  test('createShop good scenario', () async {
    when(backend.createShop(
            name: anyNamed('name'),
            coord: anyNamed('coord'),
            type: anyNamed('type')))
        .thenAnswer((_) async => Ok(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:123456')
          ..productsCount = 0)));

    final result = await shopsRequester.createShop(
        name: 'Horns and Hooves',
        coord: Coord(lat: 20, lon: 10),
        type: ShopType.supermarket);
    expect(result.isOk, isTrue);

    final expectedResult = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:123456')
        ..longitude = 10
        ..latitude = 20
        ..name = 'Horns and Hooves'
        ..type = ShopType.supermarket.osmName))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:123456')
        ..productsCount = 0)));
    expect(result.unwrap(), equals(expectedResult));
  });

  test('createShop error', () async {
    when(backend.createShop(
            name: anyNamed('name'),
            coord: anyNamed('coord'),
            type: anyNamed('type')))
        .thenAnswer((_) async => Err(BackendError.other()));

    final result = await shopsRequester.createShop(
        name: 'Horns and Hooves',
        coord: Coord(lat: 20, lon: 10),
        type: ShopType.supermarket);
    // Expecting an error
    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
  });
}
