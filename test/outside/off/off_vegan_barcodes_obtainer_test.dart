import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/outside/off/off_cacher.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_vegan_barcodes_obtainer.dart';
import 'package:plante/outside/off/off_vegan_barcodes_storage.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';

void main() {
  late MockOffApi offApi;
  late OffVeganBarcodesStorage storage;
  late OffVeganBarcodesObtainer obtainer;

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
  ];

  setUp(() async {
    offApi = MockOffApi();
    storage = OffVeganBarcodesStorage(OffCacher());
    obtainer = OffVeganBarcodesObtainer(offApi, storage);
  });

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

  test('obtain barcodes good scenario', () async {
    final barcodes1 = ['123', '124'];
    final barcodes2 = ['125', '126'];
    final barcodes3 = ['127', '128'];
    final barcodes4 = ['129', '130'];
    _initOffShopBarcodes(
      countryCode: CountryCode.BELGIUM,
      veganIngredientsBarcodes: {
        someOffShops[0]: barcodes1,
        someOffShops[1]: barcodes2,
      },
      veganLabelBarcodes: {
        someOffShops[0]: barcodes3,
        someOffShops[1]: barcodes4,
      },
    );

    final obtainedBarcodesRes = await obtainer.obtainVeganBarcodesForShops(
        CountryCode.BELGIUM, someOffShops);
    final obtainedBarcodes = obtainedBarcodesRes.unwrap();

    final finalBarcodes1 = obtainedBarcodes[someOffShops[0]]!;
    final expectedBarcodes1 = barcodes1 + barcodes3;
    expect(finalBarcodes1.toSet(), equals(expectedBarcodes1.toSet()));

    final finalBarcodes2 = obtainedBarcodes[someOffShops[1]]!;
    final expectedBarcodes2 = barcodes2 + barcodes4;
    expect(finalBarcodes2.toSet(), equals(expectedBarcodes2.toSet()));

    expect(obtainedBarcodes.length, equals(2));
  });

  test('obtain barcodes for same shop for second time', () async {
    final shop = someOffShops.first;
    final barcodes = ['123', '124'];
    _initOffShopBarcodes(
      countryCode: CountryCode.BELGIUM,
      veganIngredientsBarcodes: {shop: barcodes},
      veganLabelBarcodes: const {},
    );

    final obtainedBarcodesRes1 =
        await obtainer.obtainVeganBarcodesForShops(CountryCode.BELGIUM, [shop]);
    final obtainedBarcodes1 = obtainedBarcodesRes1.unwrap();
    // First fetch leads to network operations
    verify(offApi.getBarcodesVeganByLabel(any, any));
    verify(offApi.getBarcodesVeganByIngredients(any, any, any));

    final obtainedBarcodesRes2 =
        await obtainer.obtainVeganBarcodesForShops(CountryCode.BELGIUM, [shop]);
    final obtainedBarcodes2 = obtainedBarcodesRes2.unwrap();
    // Second fetch does not lead to network operations
    verifyNever(offApi.getBarcodesVeganByLabel(any, any));
    verifyNever(offApi.getBarcodesVeganByIngredients(any, any, any));

    expect(obtainedBarcodes1, equals(obtainedBarcodes2));
  });

  test('obtain barcodes when no barcodes are available for the shop', () async {
    final shop1 = someOffShops.first;
    final shop2 = someOffShops.last;
    _initOffShopBarcodes(
      countryCode: CountryCode.BELGIUM,
      veganIngredientsBarcodes: {
        shop1: ['123', '124']
      },
      veganLabelBarcodes: {
        shop1: ['125', '126']
      },
    );

    final obtainedBarcodesRes = await obtainer
        .obtainVeganBarcodesForShops(CountryCode.BELGIUM, [shop2]);
    expect(obtainedBarcodesRes.unwrap()[shop2.name], isNull);
    expect(obtainedBarcodesRes.unwrap()[shop1.name], isNull);
  });

  test(
      'when no barcodes are available for the shop, only first call causes an API request',
      () async {
    final shop1 = someOffShops.first;
    final shop2 = someOffShops.last;
    _initOffShopBarcodes(
      countryCode: CountryCode.BELGIUM,
      veganIngredientsBarcodes: {
        shop1: ['123', '124']
      },
      veganLabelBarcodes: {
        shop1: ['125', '126']
      },
    );

    var obtainedBarcodesRes = await obtainer
        .obtainVeganBarcodesForShops(CountryCode.BELGIUM, [shop2]);
    expect(obtainedBarcodesRes.unwrap()[shop2.name], isNull);
    // First fetch leads to network operations
    verify(offApi.getBarcodesVeganByLabel(any, any));
    verify(offApi.getBarcodesVeganByIngredients(any, any, any));

    obtainedBarcodesRes = await obtainer
        .obtainVeganBarcodesForShops(CountryCode.BELGIUM, [shop2]);
    expect(obtainedBarcodesRes.unwrap()[shop2.name], isNull);
    // Second fetch leads to NO network operations even though there were 0
    // barcodes after the first fetch
    verifyNever(offApi.getBarcodesVeganByLabel(any, any));
    verifyNever(offApi.getBarcodesVeganByIngredients(any, any, any));
  });

  test('obtain barcodes when only barcodes with vegan label available',
      () async {
    final shop = someOffShops.first;
    final veganLabelBarcodes = ['123', '124'];
    _initOffShopBarcodes(
      countryCode: CountryCode.BELGIUM,
      veganIngredientsBarcodes: const {},
      veganLabelBarcodes: {shop: veganLabelBarcodes},
    );

    final obtainedBarcodesRes =
        await obtainer.obtainVeganBarcodesForShops(CountryCode.BELGIUM, [shop]);
    final obtainedBarcodes = obtainedBarcodesRes.unwrap()[shop]!;
    final expectedBarcodes = veganLabelBarcodes;
    expect(obtainedBarcodes.toSet(), equals(expectedBarcodes.toSet()));
  });

  test('obtain barcodes when only barcodes with vegan ingredients available',
      () async {
    final shop = someOffShops.first;
    final veganIngredientsBarcodes = ['123', '124'];
    _initOffShopBarcodes(
      countryCode: CountryCode.BELGIUM,
      veganIngredientsBarcodes: {shop: veganIngredientsBarcodes},
      veganLabelBarcodes: const {},
    );

    final obtainedBarcodesRes =
        await obtainer.obtainVeganBarcodesForShops(CountryCode.BELGIUM, [shop]);
    final obtainedBarcodes = obtainedBarcodesRes.unwrap()[shop]!;
    final expectedBarcodes = veganIngredientsBarcodes;
    expect(obtainedBarcodes.toSet(), equals(expectedBarcodes.toSet()));
  });

  test('obtain barcodes when label- and ingredients-barcodes overlap ',
      () async {
    final shop = someOffShops.first;
    final barcodes1 = ['123', '124'];
    final barcodes2 = ['123', '126'];
    _initOffShopBarcodes(
      countryCode: CountryCode.BELGIUM,
      veganIngredientsBarcodes: {shop: barcodes1},
      veganLabelBarcodes: {shop: barcodes2},
    );

    expect(barcodes1.first, equals(barcodes2.first));

    final obtainedBarcodesRes =
        await obtainer.obtainVeganBarcodesForShops(CountryCode.BELGIUM, [shop]);
    final obtainedBarcodes = obtainedBarcodesRes.unwrap()[shop]!;
    expect(obtainedBarcodes.toSet(), equals((barcodes1 + barcodes2).toSet()));

    expect(obtainedBarcodes.length, barcodes1.length + barcodes2.length - 1);
  });
}
