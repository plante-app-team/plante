import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late MockOsmOverpass osm;
  late MockBackend backend;
  late FakeAnalytics analytics;
  late ShopsManager shopsManager;

  late Map<OsmUID, Shop> fullShops;
  late CoordsBounds bounds;
  late List<Product> rangeProducts;

  setUp(() async {
    commons = ShopsManagerTestCommons();
    fullShops = commons.fullShops;
    bounds = commons.bounds;
    rangeProducts = commons.rangeProducts;

    osm = commons.osm;
    backend = commons.backend;
    analytics = commons.analytics;
    shopsManager = commons.shopsManager;
  });

  test('shops products range update changes shops cache', () async {
    // Fetch #1
    final shopsRes1 = await shopsManager.fetchShops(bounds);
    final shops1 = shopsRes1.unwrap();
    expect(shops1, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShopsWithin(any));
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
    verifyNever(backend.requestShopsWithin(any));

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
    when(backend.requestShopsWithin(any))
        .thenAnswer((_) async => Ok(backendShops));
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
    verify(backend.requestShopsWithin(any));
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
    verifyNever(backend.requestShopsWithin(any));

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
}
