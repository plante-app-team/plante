import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_short_address.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_mobile_app_config_manager.dart';

void main() {
  late MockOsmNominatim nominatim;
  late AddressObtainer addressObtainer;

  final anAddress = OsmAddress((e) => e
    ..neighbourhood = 'Nice neighborhood'
    ..cityDistrict = 'Nice district'
    ..city = 'Nice city'
    ..road = 'Broadway'
    ..houseNumber = '123');
  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..longitude = 11
      ..latitude = 11
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..productsCount = 2)));

  setUp(() async {
    nominatim = MockOsmNominatim();
    when(nominatim.fetchAddress(any, any, langCode: anyNamed('langCode')))
        .thenAnswer((_) async => Ok(anAddress));
    addressObtainer = AddressObtainer(OpenStreetMap.forTesting(
        nominatim: nominatim, configManager: FakeMobileAppConfigManager()));
  });

  test('address fetched and then cached', () async {
    verifyZeroInteractions(nominatim);

    // Fetch #1
    final addressRes = await addressObtainer.addressOfShop(aShop);
    final address = addressRes.unwrap();
    expect(address, equals(anAddress.toShort()));
    // OSM expected to be touched
    verify(nominatim.fetchAddress(any, any));

    clearInteractions(nominatim);

    // Fetch #2
    final addressRes2 = await addressObtainer.addressOfShop(aShop);
    final address2 = addressRes2.unwrap();
    expect(address2, equals(anAddress.toShort()));
    // OSM is NOT expected to be touched! Cache expected to be used!
    verifyZeroInteractions(nominatim);
  });

  test('cache behaviour when multiple address fetches started at the same time',
      () async {
    verifyZeroInteractions(nominatim);

    // Fetch without await
    final addressFuture1 = addressObtainer.addressOfShop(aShop);
    final addressFuture2 = addressObtainer.addressOfShop(aShop);
    final addressFuture3 = addressObtainer.addressOfShop(aShop);
    final addressFuture4 = addressObtainer.addressOfShop(aShop);

    // Await all
    final results = await Future.wait(
        [addressFuture1, addressFuture2, addressFuture3, addressFuture4]);
    for (final result in results) {
      expect(result.unwrap(), equals(anAddress.toShort()));
    }
    // OSM expected to be touched exactly once
    verify(nominatim.fetchAddress(any, any)).called(1);
  });

  test('address fetch fail', () async {
    when(nominatim.fetchAddress(any, any))
        .thenAnswer((_) async => Err(OpenStreetMapError.OTHER));
    final addressRes = await addressObtainer.addressOfShop(aShop);
    expect(addressRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });

  test('if shop has a precise address then OSM not queried', () async {
    final preciseAddress = OsmShortAddress((e) => e
      ..city = 'London'
      ..road = 'Baker street'
      ..houseNumber = '221B');
    final shopWithAddress = aShop.rebuildWithAddress(preciseAddress);

    // Fetch
    final addressRes = await addressObtainer.addressOfShop(shopWithAddress);
    expect(addressRes.unwrap(), equals(preciseAddress));

    // Verify OSM was not touched
    verifyZeroInteractions(nominatim);
  });

  test('if shop has a precise address without city OSM is not queried',
      () async {
    final preciseAddress = OsmShortAddress((e) => e
      ..city = null
      ..road = 'Baker street'
      ..houseNumber = '221B');
    final shopWithAddress = aShop.rebuildWithAddress(preciseAddress);

    // Fetch
    final addressRes = await addressObtainer.addressOfShop(shopWithAddress);
    expect(addressRes.unwrap(), equals(preciseAddress));

    // Verify OSM was not touched
    verifyZeroInteractions(nominatim);
  });

  test('if shop has a precise address without road OSM _IS_ queried', () async {
    final preciseAddress = OsmShortAddress((e) => e
      ..city = 'London'
      ..road = null
      ..houseNumber = '221B');
    final shopWithAddress = aShop.rebuildWithAddress(preciseAddress);

    // Fetch
    final addressRes = await addressObtainer.addressOfShop(shopWithAddress);
    expect(addressRes.unwrap(), isNot(equals(preciseAddress)));
    expect(addressRes.unwrap(), equals(anAddress.toShort()));

    // Verify OSM _IS_ touched
    verify(nominatim.fetchAddress(any, any)).called(1);
  });

  test('if shop has a precise address without house number OSM _IS_ queried',
      () async {
    final preciseAddress = OsmShortAddress((e) => e
      ..city = 'London'
      ..road = 'Baker street'
      ..houseNumber = null);
    final shopWithAddress = aShop.rebuildWithAddress(preciseAddress);

    // Fetch
    final addressRes = await addressObtainer.addressOfShop(shopWithAddress);
    expect(addressRes.unwrap(), isNot(equals(preciseAddress)));
    expect(addressRes.unwrap(), equals(anAddress.toShort()));

    // Verify OSM _IS_ touched
    verify(nominatim.fetchAddress(any, any)).called(1);
  });

  test('fetched shop address is cached on country-code basis', () async {
    verifyZeroInteractions(nominatim);

    // Fetch #1, no cache, Nominatim is touched
    await addressObtainer.addressOfShop(aShop);
    verify(nominatim.fetchAddress(any, any, langCode: anyNamed('langCode')));

    clearInteractions(nominatim);
    // Fetch #2, cache expected, Nominatim isn't touched
    await addressObtainer.addressOfShop(aShop);
    verifyZeroInteractions(nominatim);

    // Fetch #3, with a country code - Fetch #1 behaviour expected
    await addressObtainer.addressOfShop(aShop, langCode: 'ru');
    verify(nominatim.fetchAddress(any, any, langCode: anyNamed('langCode')));

    clearInteractions(nominatim);
    // Fetch #4, with a country code - cache is expected now
    await addressObtainer.addressOfShop(aShop, langCode: 'ru');
    verifyZeroInteractions(nominatim);

    // Fetch #5, with a second country code - Fetch #1 behaviour expected
    await addressObtainer.addressOfShop(aShop, langCode: 'en');
    verify(nominatim.fetchAddress(any, any, langCode: anyNamed('langCode')));

    clearInteractions(nominatim);
    // Fetch #6, with the second country code - cache is expected now
    await addressObtainer.addressOfShop(aShop, langCode: 'en');
    verifyZeroInteractions(nominatim);
  });
}

extension _ShopExt on Shop {
  Shop rebuildWithAddress(OsmShortAddress address) {
    final osmShopUpdated = osmShop.rebuild((e) => e
      ..city = address.city
      ..road = address.road
      ..houseNumber = address.houseNumber);
    return rebuild((e) => e.osmShop.replace(osmShopUpdated));
  }
}
