import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_mobile_app_config_manager.dart';
import '../../z_fakes/fake_osm_cacher.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late MockOsmOverpass osm;
  late MockBackend backend;
  late FakeProductsObtainer productsObtainer;
  late FakeAnalytics analytics;
  late FakeOsmCacher osmCacher;
  late ShopsManager shopsManager;

  late Map<OsmUID, Shop> fullShops;
  late CoordsBounds bounds;

  setUp(() async {
    commons = await ShopsManagerTestCommons.create();
    fullShops = commons.fullShops;
    bounds = commons.bounds;

    osm = commons.osm;
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    analytics = commons.analytics;
    osmCacher = commons.osmCacher;
    shopsManager = commons.shopsManager;
  });

  tearDown(() async {
    await commons.dispose();
  });

  test('shop creation', () async {
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Fetch #1
    final initialShopsRes = await shopsManager.fetchShops(bounds);
    final initialShops = initialShopsRes.unwrap();
    expect(initialShops, equals(fullShops));
    // Both backends expected to be touched
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShopsWithin(any));

    clearInteractions(osm);
    clearInteractions(backend);

    // Create a shop
    verifyNever(backend.createShop(
        name: anyNamed('name'),
        coord: anyNamed('coord'),
        type: anyNamed('type')));
    final newShopRes = await shopsManager.createShop(
        name: 'New cool shop',
        coord: Coord(lat: 15, lon: 15),
        type: ShopType.supermarket);
    final newShop = newShopRes.unwrap();
    expect(newShop.name, equals('New cool shop'));

    // Fetch #2
    final shopsRes = await shopsManager.fetchShops(bounds);
    final shops = shopsRes.unwrap();
    // Expect new shops result to be same as the initial +1 shop
    expect(shops, isNot(equals(initialShops)));
    expect(shops.length, equals(initialShops.length + 1));
    for (final initialShop in initialShops.values) {
      expect(shops.values, contains(initialShop));
    }
    // The new shop is expected to be in the result
    expect(shops.values, contains(newShop));

    // Both backends expected to be NOT touched, cache expected to be used
    verifyNever(osm.fetchShops(bounds: anyNamed('bounds')));
    verifyNever(backend.requestShopsWithin(any));
  });

  test('shop creation adds the shop to persistent OSM cache', () async {
    // First the territory should be put into persistent cache by a fetch
    await shopsManager.fetchShops(bounds);

    // Create a shop
    final newShopRes = await shopsManager.createShop(
        name: 'New cool shop',
        coord: Coord(lat: 15, lon: 15),
        type: ShopType.supermarket);
    final newShop = newShopRes.unwrap();
    expect(newShop.name, equals('New cool shop'));

    // Expecting all previous shops + the new shop
    final expectedAllShops = Map<OsmUID, Shop>.from(fullShops);
    expectedAllShops[newShop.osmUID] = newShop;
    expect((await shopsManager.fetchShops(bounds)).unwrap(),
        equals(expectedAllShops));

    // Create a NEW shops manager with same persistent cache
    shopsManager = ShopsManager(
        OpenStreetMap.forTesting(
            overpass: osm, configManager: FakeMobileAppConfigManager()),
        backend,
        productsObtainer,
        analytics,
        osmCacher,
        commons.offGeoHelper);
    // Expecting the new shop to be in the cache
    expect((await shopsManager.fetchShops(bounds)).unwrap(),
        equals(expectedAllShops));
  });

  test('shop creation analytics', () async {
    expect(analytics.allEvents(), equals([]));

    // Create a shop successfully
    await shopsManager.createShop(
        name: 'New cool shop',
        coord: Coord(lat: 16, lon: 15),
        type: ShopType.supermarket);
    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.firstSentEvent('create_shop_success').second,
        equals({
          'name': 'New cool shop',
          'lat': 16,
          'lon': 15,
        }));

    analytics.clearEvents();

    // Create a shop failure
    when(backend.createShop(
            name: anyNamed('name'),
            coord: anyNamed('coord'),
            type: anyNamed('type')))
        .thenAnswer((_) async => Err(BackendError.other()));
    await shopsManager.createShop(
        name: 'New cool shop',
        coord: Coord(lat: 16, lon: 15),
        type: ShopType.supermarket);
    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.firstSentEvent('create_shop_failure').second,
        equals({
          'name': 'New cool shop',
          'lat': 16,
          'lon': 15,
        }));
    analytics.clearEvents();
  });

  test('shop creation notifies listeners', () async {
    final listener = MockShopsManagerListener();
    shopsManager.addListener(listener);

    verifyZeroInteractions(listener);
    final newShopRes = await shopsManager.createShop(
        name: 'New cool shop',
        coord: Coord(lat: 15, lon: 15),
        type: ShopType.supermarket);
    expect(newShopRes.isOk, isTrue);
    verify(listener.onLocalShopsChange());
    verify(listener.onShopCreated(newShopRes.unwrap()));
  });
}
