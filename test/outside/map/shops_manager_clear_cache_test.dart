import 'package:mockito/mockito.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/backend/cmds/shops_in_bounds_cmd.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_osm_cacher.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late MockOsmOverpass osm;
  late FakeBackend backend;
  late FakeOsmCacher osmCacher;
  late ShopsManager shopsManager;
  late CoordsBounds bounds;

  setUp(() async {
    commons = await ShopsManagerTestCommons.create();
    bounds = commons.bounds;
    osm = commons.osm;
    backend = commons.backend;
    osmCacher = commons.osmCacher;
    shopsManager = commons.shopsManager;
  });

  tearDown(() async {
    await commons.dispose();
  });

  test('clear cache', () async {
    verifyZeroInteractions(osm);
    expect(backend.getRequestsMatching_testing('.*'), isEmpty);

    // Fetch #1, which will create cache
    await shopsManager.fetchShops(bounds);
    // Persistent cache should created too
    expect(await osmCacher.getCachedShops(), isNotEmpty);

    clearInteractions(osm);
    backend.resetRequests_testing();

    // Fetch #2 will use cache and therefore won't touch backends
    await shopsManager.fetchShops(bounds);
    verifyZeroInteractions(osm);
    expect(backend.getRequestsMatching_testing('.*'), isEmpty);

    // Clear cache
    await shopsManager.clearCache();
    // Persistent cache should be cleared too
    expect(await osmCacher.getCachedShops(), isEmpty);

    // Fetch #3 is run after we cleared cache so backends
    // are expected to be touched
    await shopsManager.fetchShops(bounds);
    verify(osm.fetchShops(bounds: anyNamed('bounds')));

    expect(backend.getRequestsMatching_testing(SHOPS_IN_BOUNDS_CMD),
        isNot(isEmpty));
    // Persistent cache expected to be refilled
    expect(await osmCacher.getCachedShops(), isNotEmpty);
  });

  test('clear cache notifies listeners', () async {
    final listener = MockShopsManagerListener();
    shopsManager.addListener(listener);

    verifyZeroInteractions(listener);
    await shopsManager.clearCache();
    verify(listener.onLocalShopsChange());
  });
}
