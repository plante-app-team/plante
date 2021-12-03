import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_list_obtainer.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_off_shops_list_obtainer.dart';
import '../../z_fakes/fake_off_vegan_barcodes_obtainer.dart';
import '../../z_fakes/fake_shared_preferences.dart';

// ignore_for_file: cancel_subscriptions

void main() {
  late FakeOffVeganBarcodesObtainer barcodesObtainer;
  late FakeOffShopsListObtainer offShopsListObtainer;
  late LatestCameraPosStorage cameraPosStorage;
  late MockAddressObtainer addressObtainer;
  late OffShopsManager offShopsManager;

  final someOffShops = [
    OffShop((e) => e
      ..id = 'spar'
      ..name = 'Spar'
      ..productsCount = 2
      ..country = CountryCode.BELGIUM),
    OffShop((e) => e
      ..id = 'auchan'
      ..name = 'Auchan'
      ..productsCount = 2
      ..country = CountryCode.BELGIUM),
    OffShop((e) => e
      ..id = 'aldi'
      ..name = 'Aldi'
      ..productsCount = 20
      ..country = CountryCode.BELGIUM),
  ];

  setUp(() async {
    barcodesObtainer = FakeOffVeganBarcodesObtainer();
    offShopsListObtainer = FakeOffShopsListObtainer();
    cameraPosStorage =
        LatestCameraPosStorage(FakeSharedPreferences().asHolder());
    addressObtainer = MockAddressObtainer();

    offShopsManager = OffShopsManager(barcodesObtainer, offShopsListObtainer,
        cameraPosStorage, addressObtainer);
  });

  tearDown(() {
    offShopsManager.dispose();
  });

  Future<void> _initShops({
    required Coord? cameraPos,
    required Result<OsmAddress, OpenStreetMapError> addressOfAnyCoords,
    required Result<List<OffShop>, OffShopsListObtainerError> offApiShops,
  }) async {
    if (cameraPos != null) {
      await cameraPosStorage.set(cameraPos);
    }

    when(addressObtainer.addressOfCoords(any))
        .thenAnswer((_) async => addressOfAnyCoords);

    final countryCode = addressOfAnyCoords.maybeOk()?.countryCode;
    if (countryCode != null) {
      offShopsListObtainer.setShopsForCountry(countryCode, offApiShops);
    }
  }

  void _initOffShopBarcodes(
    Map<OffShop, List<String>?> barcodes,
  ) {
    for (final entry in barcodes.entries) {
      barcodesObtainer.setBarcodes(entry.key, entry.value);
    }
  }

  test('fetch shops', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords:
          Ok(OsmAddress((e) => e.countryCode = CountryCode.BELGIUM)),
      offApiShops: Ok(someOffShops),
    );
    final shopsResult = await offShopsManager.fetchOffShops();
    final shops = shopsResult.unwrap();
    expect(shops, equals(someOffShops));
  });

  test('fetch shops when no camera pos', () async {
    await _initShops(
      cameraPos: null,
      addressOfAnyCoords:
          Ok(OsmAddress((e) => e.countryCode = CountryCode.BELGIUM)),
      offApiShops: Ok(someOffShops),
    );
    final shopsResult = await offShopsManager.fetchOffShops();
    expect(shopsResult.isErr, isTrue);
  });

  test('fetch shops when cannot obtain OSM address', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Err(OpenStreetMapError.OTHER),
      offApiShops: Ok(const []),
    );
    final shopsResult = await offShopsManager.fetchOffShops();
    expect(shopsResult.isErr, isTrue);
  });

  test('do not fetch shops when country not in enabled list', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords:
          Ok(OsmAddress((e) => e.countryCode = CountryCode.RUSSIA)),
      offApiShops: Ok(const []),
    );
    final shopsResult = await offShopsManager.fetchOffShops();
    expect(shopsResult.isOk, isTrue);
    expect(shopsResult.unwrap().isEmpty, isTrue);
  });

  test('fetch shops when address does not have country code', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = null)),
      offApiShops: Ok(someOffShops),
    );
    final shopsResult = await offShopsManager.fetchOffShops();
    expect(shopsResult.isErr, isTrue);
  });

  test('fetch barcodes good scenario', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords:
          Ok(OsmAddress((e) => e.countryCode = CountryCode.BELGIUM)),
      offApiShops: Ok(someOffShops),
    );

    final barcodes1 = ['123', '124'];
    final barcodes2 = ['125', '126'];
    _initOffShopBarcodes(
      {
        someOffShops[0]: barcodes1,
        someOffShops[1]: barcodes2,
      },
    );

    final fetchedBarcodesRes = await offShopsManager
        .fetchVeganBarcodesMap(someOffShops.map((e) => e.name!).toSet());
    final fetchedBarcodes = fetchedBarcodesRes.unwrap();

    final finalBarcodes1 = fetchedBarcodes[someOffShops[0].name!]!;
    expect(finalBarcodes1.toSet(), equals(barcodes1.toSet()));

    final finalBarcodes2 = fetchedBarcodes[someOffShops[1].name!]!;
    expect(finalBarcodes2.toSet(), equals(barcodes2.toSet()));

    final finalBarcodes3 = fetchedBarcodes[someOffShops[2].name!];
    expect(finalBarcodes3, isNull);

    expect(fetchedBarcodes.length, equals(2));
  });

  test('fetch barcodes when could not fetch shops', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords:
          Ok(OsmAddress((e) => e.countryCode = CountryCode.BELGIUM)),
      offApiShops: Err(OffShopsListObtainerError.OTHER), // ERROR!!!!!!!!!!!!
    );

    final shop = someOffShops.first;
    _initOffShopBarcodes(
      {
        shop: ['123', '124']
      },
    );

    final fetchedBarcodesRes =
        await offShopsManager.fetchVeganBarcodesMap({shop.name!});
    expect(fetchedBarcodesRes.isErr, isTrue);
  });

  test('fetch barcodes for country not in allowedList', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords:
          Ok(OsmAddress((e) => e.countryCode = CountryCode.RUSSIA)),
      offApiShops: Ok(someOffShops),
    );

    final shop = someOffShops.first;
    _initOffShopBarcodes(
      {
        shop: ['123', '124']
      },
    );

    final fetchedBarcodesRes =
        await offShopsManager.fetchVeganBarcodesMap({shop.name!});
    expect(fetchedBarcodesRes.isOk, isTrue);
    expect(fetchedBarcodesRes.unwrap().isEmpty, isTrue);
  });

  test('fetch barcodes can be canceled', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords:
          Ok(OsmAddress((e) => e.countryCode = CountryCode.BELGIUM)),
      offApiShops: Ok(someOffShops),
    );
    _initOffShopBarcodes(
      {
        someOffShops[0]: ['123', '124'],
        someOffShops[1]: ['125', '126'],
      },
    );

    var stream = offShopsManager
        .fetchVeganBarcodes(someOffShops.map((e) => e.name!).toSet())
        .asBroadcastStream();
    var calls = 0;
    StreamSubscription? subs;
    subs = stream.listen((event) {
      // Cancel the stream on first event
      subs!.cancel();
      calls += 1;
    });

    // Let's exhaust the stream
    await for (final _ in stream) {}
    // And check calls count
    expect(calls, equals(1));

    // Now let's do it all again, this time without
    // cancellation.

    stream = offShopsManager
        .fetchVeganBarcodes(someOffShops.map((e) => e.name!).toSet())
        .asBroadcastStream();
    calls = 0;
    subs = stream.listen((event) {
      calls += 1;
    });
    // Let's exhaust the stream
    await for (final _ in stream) {}
    // And check calls count
    expect(calls, equals(2));
  });

  test('fetch barcodes - shops with more products have a priority', () async {
    final shops = someOffShops.take(2).toList();
    shops[0] = shops[0].rebuild((e) => e.productsCount = 100000);
    shops[1] = shops[1].rebuild((e) => e.productsCount = 10);

    final initTest = () async {
      await _initShops(
        cameraPos: Coord(lat: 10, lon: 10),
        addressOfAnyCoords:
            Ok(OsmAddress((e) => e.countryCode = CountryCode.BELGIUM)),
        offApiShops: Ok(shops),
      );
      _initOffShopBarcodes(
        {
          shops[0]: ['123', '124'],
          shops[1]: ['125', '126'],
        },
      );
      // Old [offShopsManager] will have cache, we don't want cache
      offShopsManager.dispose();
      offShopsManager = OffShopsManager(barcodesObtainer, offShopsListObtainer,
          cameraPosStorage, addressObtainer);
    };
    await initTest();

    var retrievedShopsResults = <String>[];
    var stream =
        offShopsManager.fetchVeganBarcodes(shops.map((e) => e.name!).toSet());
    await for (final pair in stream) {
      retrievedShopsResults.add(pair.unwrap().first);
    }
    // Verify order
    expect(retrievedShopsResults, equals([shops[0].name, shops[1].name]));

    // Reorder products counts
    final count0 = shops[0].productsCount;
    final count1 = shops[1].productsCount;
    shops[0] = shops[0].rebuild((e) => e.productsCount = count1);
    shops[1] = shops[1].rebuild((e) => e.productsCount = count0);

    // Oh, let's do it again!
    await initTest();

    retrievedShopsResults = <String>[];
    stream =
        offShopsManager.fetchVeganBarcodes(shops.map((e) => e.name!).toSet());
    await for (final pair in stream) {
      retrievedShopsResults.add(pair.unwrap().first);
    }
    // Verify different order
    expect(retrievedShopsResults, equals([shops[1].name, shops[0].name]));
  });
}
