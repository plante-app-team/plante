import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/cmds/put_product_to_shop_cmd.dart';
import 'package:plante/outside/backend/cmds/shops_in_bounds_cmd.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_off_geo_helper.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late MockOsmOverpass osm;
  late FakeBackend backend;
  late FakeAnalytics analytics;
  late FakeOffGeoHelper offGeoHelper;
  late ShopsManager shopsManager;

  late Map<OsmUID, Shop> fullShops;
  late CoordsBounds bounds;
  late List<Product> rangeProducts;

  setUp(() async {
    commons = await ShopsManagerTestCommons.create();
    fullShops = commons.fullShops;
    bounds = commons.bounds;
    rangeProducts = commons.rangeProducts;

    osm = commons.osm;
    backend = commons.backend;
    analytics = commons.analytics;
    offGeoHelper = commons.offGeoHelper;
    shopsManager = commons.shopsManager;
  });

  tearDown(() async {
    await commons.dispose();
  });

  test('shops products range update changes shops cache (1)', () async {
    // Fetch #1
    final shopsRes1 = await shopsManager.fetchShops(bounds);
    final shops1 = shopsRes1.unwrap();
    expect(shops1, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    expect(backend.getRequestsMatching_testing(SHOPS_IN_BOUNDS_CMD),
        isNot(isEmpty));
    // Reset mocks
    clearInteractions(osm);
    backend.resetRequests_testing();

    // A range update
    final putRes = await shopsManager.putProductToShops(
        rangeProducts[2], [shops1.values.first], ProductAtShopSource.MANUAL);
    expect(putRes.isOk, isTrue);

    // Fetch #2
    final shopsRes2 = await shopsManager.fetchShops(bounds);
    // Both backends expected to be NOT touched, cache expected to be used
    verifyNever(osm.fetchShops(bounds: anyNamed('bounds')));
    expect(backend.getRequestsMatching_testing(SHOPS_IN_BOUNDS_CMD), isEmpty);

    // Ensure +1 product in productsCount
    final shops2 = shopsRes2.unwrap();
    expect(shops2, isNot(equals(shops1)));
    expect(shops2.values.first.osmUID, equals(shops1.values.first.osmUID));
    expect(shops2.values.first.productsCount,
        equals(shops1.values.first.productsCount + 1));
  });

  test('shops products range update changes barcodes cache', () async {
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    final targetShop = shops.values.first;

    expect(
        await shopsManager.getBarcodesCacheFor([targetShop.osmUID]), isEmpty);

    // A range update
    final putRes = await shopsManager.putProductToShops(
        rangeProducts[2], [targetShop], ProductAtShopSource.MANUAL);
    expect(putRes.isOk, isTrue);

    expect(
        await shopsManager.getBarcodesCacheFor([targetShop.osmUID]),
        equals({
          targetShop.osmUID: [rangeProducts[2].barcode]
        }));
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
    backend.setResponse_testing(
        SHOPS_IN_BOUNDS_CMD,
        jsonEncode(
            commons.createShopsInBoundsResponse(shops: backendShops).toJson()));
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
    expect(backend.getRequestsMatching_testing(SHOPS_IN_BOUNDS_CMD),
        isNot(isEmpty));
    // Reset mocks
    clearInteractions(osm);
    backend.resetRequests_testing();

    // A range update
    final putRes = await shopsManager.putProductToShops(
        rangeProducts[2], [shops1.values.first], ProductAtShopSource.MANUAL);
    expect(putRes.isOk, isTrue);

    // Fetch #2
    final shopsRes2 = await shopsManager.fetchShops(bounds);
    // Both backends expected to be NOT touched, cache expected to be used
    verifyNever(osm.fetchShops(bounds: anyNamed('bounds')));
    expect(backend.getRequestsMatching_testing(SHOPS_IN_BOUNDS_CMD), isEmpty);

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

    final product = rangeProducts[2];

    final verifyEvent = (String event, ProductAtShopSource source) async {
      await shopsManager.putProductToShops(
          product, fullShops.values.toList(), source);
      expect(analytics.allEvents().length, equals(1));
      expect(
          analytics.firstSentEvent(event).second,
          equals({
            'barcode': product.barcode,
            'shops': fullShops.values
                .toList()
                .map((e) => e.osmUID)
                .toList()
                .join(', '),
          }));
      analytics.clearEvents();
    };

    // Success
    var sourceEventsMap = {
      ProductAtShopSource.MANUAL: 'product_put_to_shop',
      ProductAtShopSource.OFF_SUGGESTION: 'product_put_to_shop_off_suggestion',
      ProductAtShopSource.RADIUS_SUGGESTION:
          'product_put_to_shop_radius_suggestion',
    };
    for (final source in sourceEventsMap.keys) {
      await verifyEvent(sourceEventsMap[source]!, source);
    }

    // Failure
    backend.setResponse_testing(PUT_PRODUCT_TO_SHOP_CMD, '', responseCode: 500);
    sourceEventsMap = {
      ProductAtShopSource.MANUAL: 'product_put_to_shop_failure',
      ProductAtShopSource.OFF_SUGGESTION:
          'product_put_to_shop_off_suggestion_failure',
      ProductAtShopSource.RADIUS_SUGGESTION:
          'product_put_to_shop_radius_suggestion_failure',
    };
    for (final source in sourceEventsMap.keys) {
      await verifyEvent(sourceEventsMap[source]!, source);
    }
  });

  test('put product to shop - OFF geo help', () async {
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    final targetShop = shops.values.first;
    final targetProduct = rangeProducts[2];

    expect(offGeoHelper.addedGeodata_testing(), isEmpty);

    await shopsManager.putProductToShops(
        targetProduct, [targetShop], ProductAtShopSource.MANUAL);

    expect(
        offGeoHelper.addedGeodata_testing(),
        equals({
          targetProduct.barcode: {targetShop.osmUID}
        }));
  });

  test('when product put to shop listeners are notified', () async {
    final listener = MockShopsManagerListener();
    shopsManager.addListener(listener);

    verifyZeroInteractions(listener);
    final putRes = await shopsManager.putProductToShops(
        rangeProducts[2], [fullShops.values.first], ProductAtShopSource.MANUAL);
    expect(putRes.isOk, isTrue);
    verify(listener.onLocalShopsChange());
    verify(listener
        .onProductPutToShops(rangeProducts[2], [fullShops.values.first]));
  });
}
