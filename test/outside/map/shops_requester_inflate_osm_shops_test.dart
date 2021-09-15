import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend_error.dart';
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

  test('inflateOsmShops good scenario', () async {
    when(backend.requestShops(any))
        .thenAnswer((_) async => Ok(commons.someBackendShops.values.toList()));

    verifyZeroInteractions(backend);
    final shopsRes = await shopsRequester
        .inflateOsmShops(commons.someOsmShops.values.toList());
    verify(backend.requestShops(any));

    expect(shopsRes.unwrap(), commons.someShops);
  });

  test('inflateOsmShops backend error', () async {
    when(backend.requestShops(any))
        .thenAnswer((_) async => Err(BackendError.other()));

    final shopsRes = await shopsRequester
        .inflateOsmShops(commons.someOsmShops.values.toList());
    expect(shopsRes.unwrapErr(), ShopsManagerError.OTHER);
  });
}
