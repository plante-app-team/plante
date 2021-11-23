import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_shared_preferences.dart';

void main() {
  late MockOffApi offApi;
  late LatestCameraPosStorage cameraPosStorage;
  late MockAddressObtainer addressObtainer;
  late OffShopsManager offShopsManager;

  final someOffShops = [
    OffShop((e) => e
      ..id = 'spar'
      ..name = 'Spar'
      ..productsCount = 2),
    OffShop((e) => e
      ..id = 'auchan'
      ..name = 'Auchan'
      ..productsCount = 2),
  ];

  setUp(() async {
    offApi = MockOffApi();
    cameraPosStorage =
        LatestCameraPosStorage(FakeSharedPreferences().asHolder());
    addressObtainer = MockAddressObtainer();

    offShopsManager =
        OffShopsManager(offApi, cameraPosStorage, addressObtainer);
  });

  tearDown(() {
    offShopsManager.dispose();
  });

  Future<void> _initShops({
    required Coord? cameraPos,
    required Result<OsmAddress, OpenStreetMapError> addressOfAnyCoords,
    required Result<List<OffShop>, OffRestApiError> offApiShops,
  }) async {
    if (cameraPos != null) {
      await cameraPosStorage.set(cameraPos);
    }

    when(addressObtainer.addressOfCoords(any))
        .thenAnswer((_) async => addressOfAnyCoords);

    final countryCode = addressOfAnyCoords.maybeOk()?.countryCode;
    if (countryCode != null) {
      when(offApi.getShopsForLocation(countryCode))
          .thenAnswer((_) async => offApiShops);
    }
  }

  void _initOffShopBarcodes({
    required String countryCode,
    Map<OffShop, List<String>> veganIngredientsBarcodes = const {},
    Map<OffShop, List<String>> veganLabelBarcodes = const {},
  }) {
    when(offApi.getBarcodesVeganByIngredients(countryCode, any, any))
        .thenAnswer((_) async => Ok(const []));
    when(offApi.getBarcodesVeganByLabel(countryCode, any))
        .thenAnswer((_) async => Ok(const []));
    for (final shop in veganIngredientsBarcodes.keys) {
      when(offApi.getBarcodesVeganByIngredients(countryCode, shop, any))
          .thenAnswer(
              (_) async => Ok(veganIngredientsBarcodes[shop] ?? const []));
    }
    for (final shop in veganLabelBarcodes.keys) {
      when(offApi.getBarcodesVeganByLabel(countryCode, shop))
          .thenAnswer((_) async => Ok(veganLabelBarcodes[shop] ?? const []));
    }
  }

  test('fetch shops', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = BELGIUM)),
      offApiShops: Ok(someOffShops),
    );
    final shopsResult = await offShopsManager.fetchOffShops();
    final shops = shopsResult.unwrap();
    expect(shops, equals(someOffShops));
  });

  test('fetch shops when no camera pos', () async {
    await _initShops(
      cameraPos: null,
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = BELGIUM)),
      offApiShops: Ok(someOffShops),
    );
    final shopsResult = await offShopsManager.fetchOffShops();
    expect(shopsResult.isErr, isTrue);
  });

  test('fetch shops when cannot obtain OSM address', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Err(OpenStreetMapError.OTHER),
      offApiShops: Ok(someOffShops),
    );
    final shopsResult = await offShopsManager.fetchOffShops();
    expect(shopsResult.isErr, isTrue);
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
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = BELGIUM)),
      offApiShops: Ok(someOffShops),
    );

    final barcodes1 = ['123', '124'];
    final barcodes2 = ['125', '126'];
    final barcodes3 = ['127', '128'];
    final barcodes4 = ['129', '130'];
    _initOffShopBarcodes(
      countryCode: BELGIUM,
      veganIngredientsBarcodes: {
        someOffShops[0]: barcodes1,
        someOffShops[1]: barcodes2,
      },
      veganLabelBarcodes: {
        someOffShops[0]: barcodes3,
        someOffShops[1]: barcodes4,
      },
    );

    final fetchedBarcodesRes = await offShopsManager.fetchVeganBarcodesForShops(
        someOffShops.map((e) => e.name!).toSet(), [LangCode.be]);
    final fetchedBarcodes = fetchedBarcodesRes.unwrap();

    final finalBarcodes1 = fetchedBarcodes[someOffShops[0].name!]!;
    final expectedBarcodes1 = barcodes1 + barcodes3;
    expect(finalBarcodes1.toSet(), equals(expectedBarcodes1.toSet()));

    final finalBarcodes2 = fetchedBarcodes[someOffShops[1].name!]!;
    final expectedBarcodes2 = barcodes2 + barcodes4;
    expect(finalBarcodes2.toSet(), equals(expectedBarcodes2.toSet()));

    expect(fetchedBarcodes.length, equals(2));
  });

  test('fetch barcodesfor same shop for second time', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = BELGIUM)),
      offApiShops: Ok(someOffShops),
    );

    final shop = someOffShops.first;
    final shopName = shop.name!;
    final barcodes = ['123', '124'];
    _initOffShopBarcodes(
      countryCode: BELGIUM,
      veganIngredientsBarcodes: {shop: barcodes},
      veganLabelBarcodes: const {},
    );

    final fetchedBarcodesRes1 = await offShopsManager
        .fetchVeganBarcodesForShops({shopName}, [LangCode.be]);
    final fetchedbarcodes1 = fetchedBarcodesRes1.unwrap();
    // First fetch leads to network operations
    verify(offApi.getBarcodesVeganByLabel(any, any));
    verify(offApi.getBarcodesVeganByIngredients(any, any, any));

    final fetchedBarcodesRes2 = await offShopsManager
        .fetchVeganBarcodesForShops({shopName}, [LangCode.be]);
    final fetchedbarcodes2 = fetchedBarcodesRes2.unwrap();
    // Second fetch does not lead to network operations
    verifyNever(offApi.getBarcodesVeganByLabel(any, any));
    verifyNever(offApi.getBarcodesVeganByIngredients(any, any, any));

    expect(fetchedbarcodes1, equals(fetchedbarcodes2));
  });

  test('fetch barcodeswhen no barcodesare available for the shop', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = BELGIUM)),
      offApiShops: Ok(someOffShops),
    );

    final shop1 = someOffShops.first;
    final shop2 = someOffShops.last;
    _initOffShopBarcodes(
      countryCode: BELGIUM,
      veganIngredientsBarcodes: {
        shop1: ['123', '124']
      },
      veganLabelBarcodes: {
        shop1: ['125', '126']
      },
    );

    final fetchedBarcodesRes = await offShopsManager
        .fetchVeganBarcodesForShops({shop2.name!}, [LangCode.be]);
    expect(fetchedBarcodesRes.unwrap()[shop2.name], isEmpty);
    expect(fetchedBarcodesRes.unwrap()[shop1.name], isNull);
  });

  test('fetch barcodeswhen only barcodeswith vegan label available', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = BELGIUM)),
      offApiShops: Ok(someOffShops),
    );

    final shop = someOffShops.first;
    final veganLabelBarcodes = ['123', '124'];
    _initOffShopBarcodes(
      countryCode: BELGIUM,
      veganIngredientsBarcodes: const {},
      veganLabelBarcodes: {shop: veganLabelBarcodes},
    );

    final fetchedBarcodesRes = await offShopsManager
        .fetchVeganBarcodesForShops({shop.name!}, [LangCode.be]);
    final fetchedBarcodes = fetchedBarcodesRes.unwrap()[shop.name!]!;
    final expectedBarcodes = veganLabelBarcodes;
    expect(fetchedBarcodes.toSet(), equals(expectedBarcodes.toSet()));
  });

  test('fetch barcodeswhen only barcodeswith vegan ingredients available',
      () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = BELGIUM)),
      offApiShops: Ok(someOffShops),
    );

    final shop = someOffShops.first;
    final veganIngredientsBarcodes = ['123', '124'];
    _initOffShopBarcodes(
      countryCode: BELGIUM,
      veganIngredientsBarcodes: {shop: veganIngredientsBarcodes},
      veganLabelBarcodes: const {},
    );

    final fetchedBarcodesRes = await offShopsManager
        .fetchVeganBarcodesForShops({shop.name!}, [LangCode.be]);
    final fetchedBarcodes = fetchedBarcodesRes.unwrap()[shop.name!]!;
    final expectedBarcodes = veganIngredientsBarcodes;
    expect(fetchedBarcodes.toSet(), equals(expectedBarcodes.toSet()));
  });

  test('fetch barcodeswhen label- and ingredients-barcodes overlap ', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = BELGIUM)),
      offApiShops: Ok(someOffShops),
    );

    final shop = someOffShops.first;
    final barcodes1 = ['123', '124'];
    final barcodes2 = ['123', '126'];
    _initOffShopBarcodes(
      countryCode: BELGIUM,
      veganIngredientsBarcodes: {shop: barcodes1},
      veganLabelBarcodes: {shop: barcodes2},
    );

    expect(barcodes1.first, equals(barcodes2.first));

    final fetchedBarcodesRes = await offShopsManager
        .fetchVeganBarcodesForShops({shop.name!}, [LangCode.be]);
    final fetchedBarcodes = fetchedBarcodesRes.unwrap()[shop.name!]!;
    expect(fetchedBarcodes.toSet(), equals((barcodes1 + barcodes2).toSet()));

    expect(fetchedBarcodes.length, barcodes1.length + barcodes2.length - 1);
  });

  test('fetch barcodes when could not fetch shops', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = BELGIUM)),
      offApiShops: Err(OffRestApiError.OTHER), // ERROR!!!!!!!!!!!!
    );

    final shop = someOffShops.first;
    _initOffShopBarcodes(
      countryCode: BELGIUM,
      veganIngredientsBarcodes: {
        shop: ['123', '124']
      },
    );

    final fetchedBarcodesRes = await offShopsManager
        .fetchVeganBarcodesForShops({shop.name!}, [LangCode.be]);
    expect(fetchedBarcodesRes.isErr, isTrue);
  });

  test('fetch barcodes for country not in allowedList', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = RUSSIA)),
      offApiShops: Ok(someOffShops),
    );

    final shop = someOffShops.first;
    _initOffShopBarcodes(
      countryCode: RUSSIA,
      veganIngredientsBarcodes: {
        shop: ['123', '124']
      },
    );

    final fetchedBarcodesRes = await offShopsManager
        .fetchVeganBarcodesForShops({shop.name!}, [LangCode.be]);
    expect(fetchedBarcodesRes.unwrap().isEmpty, isTrue);
  });
}
