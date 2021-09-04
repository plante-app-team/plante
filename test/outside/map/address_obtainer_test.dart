import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';

void main() {
  late MockOpenStreetMap osm;
  late AddressObtainer addressObtainer;

  final anAddress = OsmAddress((e) => e
    ..neighbourhood = 'Nice neighborhood'
    ..cityDistrict = 'Nice district'
    ..road = 'Broadway'
    ..houseNumber = '123');
  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmId = '1'
      ..longitude = 11
      ..latitude = 11
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmId = '1'
      ..productsCount = 2)));

  setUp(() async {
    osm = MockOpenStreetMap();
    when(osm.fetchAddress(any, any)).thenAnswer((_) async => Ok(anAddress));
    addressObtainer = AddressObtainer(osm, OsmInteractionsQueue());
  });

  test('address fetched and then cached', () async {
    verifyZeroInteractions(osm);

    // Fetch #1
    final addressRes = await addressObtainer.addressOfShop(aShop);
    final address = addressRes.unwrap();
    expect(address, equals(anAddress));
    // OSM expected to be touched
    verify(osm.fetchAddress(any, any));

    clearInteractions(osm);

    // Fetch #2
    final addressRes2 = await addressObtainer.addressOfShop(aShop);
    final address2 = addressRes2.unwrap();
    expect(address2, equals(anAddress));
    // OSM is NOT expected to be touched! Cache expected to be used!
    verifyZeroInteractions(osm);
  });

  test('cache behaviour when multiple address fetches started at the same time',
      () async {
    verifyZeroInteractions(osm);

    // Fetch without await
    final addressFuture1 = addressObtainer.addressOfShop(aShop);
    final addressFuture2 = addressObtainer.addressOfShop(aShop);
    final addressFuture3 = addressObtainer.addressOfShop(aShop);
    final addressFuture4 = addressObtainer.addressOfShop(aShop);

    // Await all
    final results = await Future.wait(
        [addressFuture1, addressFuture2, addressFuture3, addressFuture4]);
    for (final result in results) {
      expect(result.unwrap(), equals(anAddress));
    }
    // OSM expected to be touched exactly once
    verify(osm.fetchAddress(any, any)).called(1);
  });

  test('address fetch fail', () async {
    when(osm.fetchAddress(any, any))
        .thenAnswer((_) async => Err(OpenStreetMapError.OTHER));
    final addressRes = await addressObtainer.addressOfShop(aShop);
    expect(addressRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });
}
