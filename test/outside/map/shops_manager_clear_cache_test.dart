import 'package:mockito/mockito.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_osm_cacher.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late MockOsmOverpass osm;
  late MockBackend backend;
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
    verifyZeroInteractions(backend);

    // Fetch #1, which will create cache
    await shopsManager.fetchShops(bounds);
    // Persistent cache should created too
    expect(await osmCacher.getCachedShops(), isNotEmpty);

    clearInteractions(osm);
    clearInteractions(backend);

    // Fetch #2 will use cache and therefore won't touch backends
    await shopsManager.fetchShops(bounds);
    verifyZeroInteractions(osm);
    verifyZeroInteractions(backend);

    // Clear cache
    await shopsManager.clearCache();
    // Persistent cache should be cleared too
    expect(await osmCacher.getCachedShops(), isEmpty);

    // Fetch #3 is run after we cleared cache so backends
    // are expected to be touched
    await shopsManager.fetchShops(bounds);
    verify(osm.fetchShops(bounds: anyNamed('bounds')));
    verify(backend.requestShopsWithin(any));
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
