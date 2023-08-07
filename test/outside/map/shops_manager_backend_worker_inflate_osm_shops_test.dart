import 'dart:convert';

import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/cmds/shops_by_osm_uids_cmd.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager_backend_worker.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_backend.dart';
import 'shops_manager_backend_worker_test_commons.dart';

void main() {
  late ShopsManagerBackendWorkerTestCommons commons;
  late FakeBackend backend;
  late MockProductsObtainer productsObtainer;
  late ShopsManagerBackendWorker shopsManagerBackendWorker;

  setUp(() async {
    commons = ShopsManagerBackendWorkerTestCommons();
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    shopsManagerBackendWorker =
        ShopsManagerBackendWorker(backend, productsObtainer);
  });

  test('inflateOsmShops good scenario', () async {
    backend.setResponse_testing(SHOPS_BY_OSM_UIDS_CMD,
        commons.someBackendShops._toShopsByOsmUIDsJson());

    expect(backend.getRequestsMatching_testing(SHOPS_BY_OSM_UIDS_CMD), isEmpty);
    final shopsRes = await shopsManagerBackendWorker
        .inflateOsmShops(commons.someOsmShops.values.toList());
    expect(backend.getRequestsMatching_testing(SHOPS_BY_OSM_UIDS_CMD),
        isNot(isEmpty));

    expect(shopsRes.unwrap(), commons.someShops);
  });

  test('inflateOsmShops backend error', () async {
    backend.setResponse_testing(SHOPS_BY_OSM_UIDS_CMD, '', responseCode: 500);

    final shopsRes = await shopsManagerBackendWorker
        .inflateOsmShops(commons.someOsmShops.values.toList());
    expect(shopsRes.unwrapErr(), ShopsManagerError.OTHER);
  });

  test('inflateOsmShops ignores shops marked as deleted', () async {
    final someBackendShops = commons.someBackendShops;
    expect(someBackendShops.length, greaterThan(1));
    final shop = someBackendShops.entries.first;
    someBackendShops[shop.key] =
        someBackendShops[shop.key]!.rebuild((e) => e.deleted = true);

    backend.setResponse_testing(
        SHOPS_BY_OSM_UIDS_CMD, someBackendShops._toShopsByOsmUIDsJson());

    final shopsRes = await shopsManagerBackendWorker
        .inflateOsmShops(commons.someOsmShops.values.toList());

    expect(shopsRes.unwrap(), isNot(equals(commons.someShops)));
    final expectedShops = {...commons.someShops};
    expectedShops.remove(shop.key);
    expect(shopsRes.unwrap(), equals(expectedShops));
  });
}

extension _ShopsByOsmUIDsExt on Map<OsmUID, BackendShop> {
  String _toShopsByOsmUIDsJson() {
    final convertedMap = {
      for (final pair in entries) pair.key.toString(): pair.value.toJson()
    };
    return jsonEncode({SHOPS_BY_OSM_UIDS_CMD_RESULT_FIELD: convertedMap});
  }
}
