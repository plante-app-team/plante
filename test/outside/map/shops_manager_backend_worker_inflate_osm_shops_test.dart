import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/shops_manager_backend_worker.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import 'shops_manager_backend_worker_test_commons.dart';

void main() {
  late ShopsManagerBackendWorkerTestCommons commons;
  late MockBackend backend;
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
    when(backend.requestShopsByOsmUIDs(any))
        .thenAnswer((_) async => Ok(commons.someBackendShops.values.toList()));

    verifyZeroInteractions(backend);
    final shopsRes = await shopsManagerBackendWorker
        .inflateOsmShops(commons.someOsmShops.values.toList());
    verify(backend.requestShopsByOsmUIDs(any));

    expect(shopsRes.unwrap(), commons.someShops);
  });

  test('inflateOsmShops backend error', () async {
    when(backend.requestShopsByOsmUIDs(any))
        .thenAnswer((_) async => Err(BackendError.other()));

    final shopsRes = await shopsManagerBackendWorker
        .inflateOsmShops(commons.someOsmShops.values.toList());
    expect(shopsRes.unwrapErr(), ShopsManagerError.OTHER);
  });

  test('inflateOsmShops ignores shops marked as deleted', () async {
    final someBackendShops = commons.someBackendShops.values.toList();
    expect(someBackendShops.length, greaterThan(1));
    someBackendShops[0] = someBackendShops[0].rebuild((e) => e.deleted = true);

    when(backend.requestShopsByOsmUIDs(any))
        .thenAnswer((_) async => Ok(someBackendShops));

    final shopsRes = await shopsManagerBackendWorker
        .inflateOsmShops(commons.someOsmShops.values.toList());

    expect(shopsRes.unwrap(), isNot(equals(commons.someShops)));
    final expectedShops = {...commons.someShops};
    expectedShops.remove(someBackendShops[0].osmUID);
    expect(shopsRes.unwrap(), equals(expectedShops));
  });
}
