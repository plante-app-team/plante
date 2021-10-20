import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/model/parameter/TagFilter.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_shared_preferences.dart';
import 'off_json_product_images_utils.dart';

void main() {
  late MockOffApi offApi;
  late LatestCameraPosStorage cameraPosStorage;
  late MockAddressObtainer addressObtainer;
  late MockProductsManager productsManager;
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

  List<off.Product> createOffProducts(
      String countryCode, List<String> barcodes) {
    return barcodes
        .map((barcode) => off.Product.fromJson({
              'code': barcode,
              'product_name_$countryCode': 'name$barcode',
              'brands_tags': ['Brand name'],
              'ingredients_text_$countryCode': 'lemon, water',
              'selected_images':
                  jsonDecode(createOffSelectedImagesJson([countryCode])),
            }))
        .toList();
  }

  setUp(() async {
    offApi = MockOffApi();
    cameraPosStorage =
        LatestCameraPosStorage(FakeSharedPreferences().asHolder());
    addressObtainer = MockAddressObtainer();
    productsManager = MockProductsManager();

    when(productsManager.inflateOffProducts(any, any)).thenAnswer((invc) async {
      final offProducts = invc.positionalArguments[0] as List<off.Product>;
      return Ok(offProducts
          .map((e) =>
              ProductLangSlice((v) => v.barcode = e.barcode).productForTests())
          .toList());
    });

    offShopsManager = OffShopsManager(
        offApi, cameraPosStorage, addressObtainer, productsManager);
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

  void _initOffShopProducts({
    required String countryCode,
    required String shopName,
    required List<off.Product>? veganIngredientsProducts,
    required List<off.Product>? veganLabelProducts,
  }) {
    final shopId = OffShopsManager.shopNameToPossibleOffShopID(shopName);

    when(offApi.searchProducts(any)).thenAnswer((invc) async {
      final conf =
          invc.positionalArguments[0] as off.ProductSearchQueryConfiguration;

      // A function which determines whether some tag with a
      // certain value is requested.
      final hasTagParamWithVal = (String tag, String val) {
        final tagsParams = conf.additionalParameters.whereType<off.TagFilter>();
        return tagsParams.any((param) =>
            param.getTagType() == tag &&
            param.getTagName() == val &&
            param.contains == true);
      };

      if (conf.cc == countryCode && hasTagParamWithVal('stores', shopId)) {
        final result = <off.Product>[];
        if (hasTagParamWithVal('labels', 'en:vegan')) {
          result.addAll(veganLabelProducts ?? const []);
        }
        if (hasTagParamWithVal('ingredients_analysis', 'en:vegan')) {
          result.addAll(veganIngredientsProducts ?? const []);
        }
        return off.SearchResult(
          page: 1,
          pageSize: result.length,
          count: result.length,
          skip: 0,
          products: result,
        );
      }

      return const off.SearchResult(
        page: 1,
        pageSize: 20,
        count: 0,
        skip: 0,
        products: [],
      );
    });
  }

  test('fetch shops', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );
    final shopsResult = await offShopsManager.fetchOffShops();
    final shops = shopsResult.unwrap();
    expect(shops, equals(someOffShops));
  });

  test('fetch shops when no camera pos', () async {
    await _initShops(
      cameraPos: null,
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
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

  test('fetch products good scenario', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    final shopName = someOffShops.first.name!;
    final products1 = createOffProducts('be', ['123', '124']);
    final products2 = createOffProducts('be', ['125', '126']);
    _initOffShopProducts(
      countryCode: 'be',
      shopName: shopName,
      veganIngredientsProducts: products1,
      veganLabelProducts: products2,
    );

    final fetchedProductsRes = await offShopsManager
        .fetchVeganProductsForShop(shopName, [LangCode.be]);
    final fetchedProducts = fetchedProductsRes.unwrap();
    expect(fetchedProducts.map((e) => e.barcode).toSet(),
        equals((products1 + products2).map((e) => e.barcode).toSet()));
  });

  test('fetch products for same shop for second time', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    final shopName = someOffShops.first.name!;
    final products = createOffProducts('be', ['123', '124']);
    _initOffShopProducts(
      countryCode: 'be',
      shopName: shopName,
      veganIngredientsProducts: products,
      veganLabelProducts: null,
    );

    final fetchedProductsRes1 = await offShopsManager
        .fetchVeganProductsForShop(shopName, [LangCode.be]);
    final fetchedProducts1 = fetchedProductsRes1.unwrap();
    // First fetch leads to network operations
    verify(offApi.searchProducts(any));
    verify(productsManager.inflateOffProducts(any, any));

    final fetchedProductsRes2 = await offShopsManager
        .fetchVeganProductsForShop(shopName, [LangCode.be]);
    final fetchedProducts2 = fetchedProductsRes2.unwrap();
    // Second fetch does not lead to network operations
    verifyNever(offApi.searchProducts(any));
    verifyNever(productsManager.inflateOffProducts(any, any));

    expect(fetchedProducts1, equals(fetchedProducts2));
  });

  test('fetch products when the shop is not present', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    final shopName1 = someOffShops.first.name!;
    final shopName2 = someOffShops.last.name!;
    _initOffShopProducts(
      countryCode: 'be',
      shopName: shopName1,
      veganIngredientsProducts: createOffProducts('be', ['123', '124']),
      veganLabelProducts: createOffProducts('be', ['125', '126']),
    );

    final fetchedProductsRes = await offShopsManager
        .fetchVeganProductsForShop(shopName2, [LangCode.be]);
    expect(fetchedProductsRes.unwrap(), isEmpty);
  });

  test('fetch products when only products with vegan label available',
      () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    final shopName = someOffShops.first.name!;
    final veganLabelProducts = createOffProducts('be', ['123', '124']);
    _initOffShopProducts(
      countryCode: 'be',
      shopName: shopName,
      veganIngredientsProducts: null,
      veganLabelProducts: veganLabelProducts,
    );

    final fetchedProductsRes = await offShopsManager
        .fetchVeganProductsForShop(shopName, [LangCode.be]);
    final fetchedProducts = fetchedProductsRes.unwrap();
    expect(fetchedProducts.map((e) => e.barcode).toSet(),
        equals(veganLabelProducts.map((e) => e.barcode).toSet()));
  });

  test('fetch products when only products with vegan ingredients available',
      () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    final shopName = someOffShops.first.name!;
    final veganIngredientsProducts = createOffProducts('be', ['123', '124']);
    _initOffShopProducts(
      countryCode: 'be',
      shopName: shopName,
      veganIngredientsProducts: veganIngredientsProducts,
      veganLabelProducts: null,
    );

    final fetchedProductsRes = await offShopsManager
        .fetchVeganProductsForShop(shopName, [LangCode.be]);
    final fetchedProducts = fetchedProductsRes.unwrap();
    expect(fetchedProducts.map((e) => e.barcode).toSet(),
        equals(veganIngredientsProducts.map((e) => e.barcode).toSet()));
  });

  test('fetch products when label- and ingredients-products overlap ',
      () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    final shopName = someOffShops.first.name!;
    final products1 = createOffProducts('be', ['123', '124']);
    final products2 = createOffProducts('be', ['123', '126']);
    _initOffShopProducts(
      countryCode: 'be',
      shopName: shopName,
      veganIngredientsProducts: products1,
      veganLabelProducts: products2,
    );

    expect(products1.first.barcode, equals(products2.first.barcode));

    final fetchedProductsRes = await offShopsManager
        .fetchVeganProductsForShop(shopName, [LangCode.be]);
    final fetchedProducts = fetchedProductsRes.unwrap();
    expect(fetchedProducts.map((e) => e.barcode).toSet(),
        equals((products1 + products2).map((e) => e.barcode).toSet()));

    expect(fetchedProducts.length, products1.length + products2.length - 1);
  });

  test('fetch products uses only needed OFF fields', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    final requestedOffFields = <off.ProductField>{};
    when(offApi.searchProducts(any)).thenAnswer((invc) async {
      final conf =
          invc.positionalArguments[0] as off.ProductSearchQueryConfiguration;
      requestedOffFields.addAll(conf.fields ?? const []);
      return const off.SearchResult(
        page: 1,
        pageSize: 20,
        count: 0,
        skip: 0,
        products: [],
      );
    });

    await offShopsManager
        .fetchVeganProductsForShop(someOffShops.first.name!, [LangCode.be]);
    expect(
        requestedOffFields, equals(ProductsManager.NEEDED_OFF_FIELDS.toSet()));
  });

  test('fetch products when could not fetch shops', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Err(OffRestApiError.OTHER), // ERROR!!!!!!!!!!!!
    );

    final shopName = someOffShops.first.name!;
    _initOffShopProducts(
      countryCode: 'be',
      shopName: shopName,
      veganIngredientsProducts: createOffProducts('be', ['123', '124']),
      veganLabelProducts: null,
    );

    final fetchedProductsRes = await offShopsManager
        .fetchVeganProductsForShop(shopName, [LangCode.be]);
    expect(fetchedProductsRes.isErr, isTrue);
  });

  test('fetch products when could not inflate OFF products', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    final shopName = someOffShops.first.name!;
    _initOffShopProducts(
      countryCode: 'be',
      shopName: shopName,
      veganIngredientsProducts: createOffProducts('be', ['123', '124']),
      veganLabelProducts: null,
    );

    when(productsManager.inflateOffProducts(any, any))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));
    final fetchedProductsRes = await offShopsManager
        .fetchVeganProductsForShop(shopName, [LangCode.be]);
    expect(fetchedProductsRes.isErr, isTrue);
  });

  test('fetch products when OFF returned null products', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    when(offApi.searchProducts(any)).thenAnswer((invc) async {
      return const off.SearchResult(
        page: null,
        pageSize: null,
        count: null,
        skip: null,
        products: null,
      );
    });

    final result = await offShopsManager
        .fetchVeganProductsForShop(someOffShops.first.name!, [LangCode.be]);
    expect(result.isErr, isTrue);
  });

  test('fetch products when OFF threw network error', () async {
    await _initShops(
      cameraPos: Coord(lat: 10, lon: 10),
      addressOfAnyCoords: Ok(OsmAddress((e) => e.countryCode = 'be')),
      offApiShops: Ok(someOffShops),
    );

    when(offApi.searchProducts(any)).thenAnswer((invc) async {
      throw const SocketException('hello there');
    });

    final result = await offShopsManager
        .fetchVeganProductsForShop(someOffShops.first.name!, [LangCode.be]);
    expect(result.isErr, isTrue);
  });
}
