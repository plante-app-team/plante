import 'package:mockito/mockito.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/cmds/shops_by_osm_uids_cmd.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_large_local_cache_impl.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_backend.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late MockOsmOverpass osm;
  late FakeBackend backend;
  late ShopsManager shopsManager;

  late Map<OsmUID, Shop> fullShops;

  setUp(() async {
    commons = await ShopsManagerTestCommons.create();
    fullShops = commons.fullShops;

    osm = commons.osm;
    backend = commons.backend;
    shopsManager = commons.shopsManager;
  });

  tearDown(() async {
    await commons.dispose();
  });

  test('fetchShopsByUIDs when all shops already in cache', () async {
    final cache = ShopsLargeLocalCacheImpl();
    shopsManager = await commons.createShopsManager(largeCache: cache);
    await cache.addShops(fullShops.values);

    final result = await shopsManager.fetchShopsByUIDs(fullShops.keys);
    expect(result.unwrap(), equals(fullShops));

    expect(backend.getAllRequests_testing(), isEmpty);
    verifyZeroInteractions(osm);
  });

  test('fetchShopsByUIDs when no shops in cache', () async {
    final cache = ShopsLargeLocalCacheImpl();
    shopsManager = await commons.createShopsManager(largeCache: cache);

    // No shops in cache
    expect(await cache.getShops(fullShops.keys), isEmpty);

    final result = await shopsManager.fetchShopsByUIDs(fullShops.keys);
    expect(result.unwrap(), equals(fullShops));

    // Shops in cache now
    expect(await cache.getShops(fullShops.keys), equals(fullShops));

    // Servers are touched
    expect(backend.getRequestsMatching_testing(SHOPS_BY_OSM_UIDS_CMD),
        isNot(isEmpty));
    verify(osm.fetchShops(
        bounds: anyNamed('bounds'), osmUIDs: anyNamed('osmUIDs')));
  });

  test('fetchShopsByUIDs when some shops already in cache and some not',
      () async {
    final cache = ShopsLargeLocalCacheImpl();
    shopsManager = await commons.createShopsManager(largeCache: cache);

    expect(fullShops.length, greaterThan(1));
    await cache.addShop(fullShops.values.first);

    // Just one shop in cache
    expect(await cache.getShops(fullShops.keys),
        equals({fullShops.values.first.osmUID: fullShops.values.first}));

    final result = await shopsManager.fetchShopsByUIDs(fullShops.keys);
    expect(result.unwrap(), equals(fullShops));

    // All shops in cache now
    expect(await cache.getShops(fullShops.keys), equals(fullShops));

    // Servers are touched
    expect(backend.getRequestsMatching_testing(SHOPS_BY_OSM_UIDS_CMD),
        isNot(isEmpty));
    verify(osm.fetchShops(
        bounds: anyNamed('bounds'), osmUIDs: anyNamed('osmUIDs')));
  });
}
