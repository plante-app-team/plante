import 'package:mockito/mockito.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late MockBackend backend;
  late ShopsManager shopsManager;

  setUp(() async {
    commons = ShopsManagerTestCommons();

    backend = commons.backend;
    shopsManager = commons.shopsManager;
  });

  test('shops inflated and then cached', () async {
    final listener = MockShopsManagerListener();
    shopsManager.addListener(listener);

    // First inflate
    var inflateRes = await shopsManager.inflateOsmShops(commons.osmShops);
    var inflatedShops = inflateRes.unwrap();
    expect(inflatedShops, equals(commons.fullShops));
    // Backend expected to be touched
    verify(backend.requestShopsByOsmUIDs(any));
    // Listener expected to be notified about cache updated
    verify(listener.onLocalShopsChange());

    clearInteractions(backend);
    clearInteractions(listener);

    // Second inflate
    inflateRes = await shopsManager.inflateOsmShops(commons.osmShops);
    inflatedShops = inflateRes.unwrap();
    expect(inflatedShops, equals(commons.fullShops));
    // Backend expected to be NOT touched
    verifyZeroInteractions(backend);
    // Listener expected to be NOT notified
    verifyZeroInteractions(listener);
  });

  test('inflateOsmShops when all of shops are in cache', () async {
    // Force caching
    await shopsManager.fetchShops(commons.bounds);
    clearInteractions(backend);

    final inflateRes = await shopsManager.inflateOsmShops(commons.osmShops);
    final inflatedShops = inflateRes.unwrap();

    expect(inflatedShops, equals(commons.fullShops));

    // Backend is NOT expected to be requested since
    // all of the requested shops should be in cache by now
    verifyNever(backend.requestShopsByOsmUIDs(any));
  });

  test('inflateOsmShops when part of shops are in cache', () async {
    // Force caching
    await shopsManager.fetchShops(commons.bounds);
    clearInteractions(backend);

    final requestedShops = commons.osmShops.toList();
    requestedShops.add(OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:123321')
      ..name = 'new cool shop'
      ..type = 'supermarket'
      ..longitude = 15
      ..latitude = 15));

    final inflateRes = await shopsManager.inflateOsmShops(requestedShops);
    final inflatedShops = inflateRes.unwrap();

    final expectedShops = <OsmUID, Shop>{};
    expectedShops.addAll(commons.fullShops);
    expectedShops[requestedShops.last.osmUID] =
        Shop((e) => e..osmShop.replace(requestedShops.last));
    expect(inflatedShops, equals(expectedShops));

    // Backend is expected to be requested since
    // not all of the shops are in cache
    verify(backend.requestShopsByOsmUIDs(any));
  });
}
