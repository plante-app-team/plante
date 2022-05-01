import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart' as off;
import 'package:plante/base/result.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/products/products_manager.dart';
import 'package:test/test.dart';

import '../common_mocks.mocks.dart';
import '../outside/off/off_json_product_images_utils.dart';
import 'products_manager_tests_commons.dart';

void main() {
  late ProductsManagerTestCommons commons;
  late MockOffApi offApi;
  late MockBackend backend;
  late ProductsManager productsManager;

  setUp(() async {
    commons = await ProductsManagerTestCommons.create();
    offApi = commons.offApi;
    backend = commons.backend;
    productsManager = commons.productsManager;
  });

  void setUpOffProducts(List<off.Product> products) {
    commons.setUpOffProducts(products);
  }

  void setUpBackendProducts(
      Result<List<BackendProduct>, BackendError> productsRes) {
    commons.setUpBackendProducts(productsRes);
  }

  test('inflate backend product', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name',
      'brands_tags': ['Brand name'],
      'ingredients_text_ru': 'lemon, water',
      'selected_images': jsonDecode(offSelectedImagesRuJson),
    });
    setUpOffProducts([offProduct]);

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    final productRes =
        await productsManager.inflate(backendProduct, [LangCode.ru]);
    final product = productRes.unwrap();

    final expectedProduct = ProductLangSlice((v) => v
          ..lang = LangCode.ru
          ..barcode = '123'
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.moderator
          ..name = 'name'
          ..brands.add('Brand name')
          ..ingredientsText = 'lemon, water'
          ..ingredientsAnalyzed.addAll([])
          ..imageFront = Uri.parse(offExpectedImageFrontRu)
          ..imageFrontThumb = Uri.parse(offExpectedImageFrontThumbRu)
          ..imageIngredients = Uri.parse(offExpectedImageIngredientsRu))
        .productForTests();
    expect(product, equals(expectedProduct));

    // We expect the backend to not be touched since
    // we already have a backend product.
    verifyNever(backend.requestProducts(any, any));
  });

  test('inflate many backend products with pagination', () async {
    const barcodes = [
      '121',
      '122',
      '123',
      '124',
      '125',
      '126',
      '127',
    ];
    final offProducts = barcodes
        .map((e) => off.Product.fromJson({
              'code': e,
              'product_name_ru': 'name$e',
              'brands_tags': ['Brand name'],
              'ingredients_text_ru': 'lemon, water',
              'selected_images': jsonDecode(offSelectedImagesRuJson),
            }))
        .toList();
    when(offApi.getProductList(any)).thenAnswer((invc) async {
      final configuration =
          invc.positionalArguments[0] as off.ProductListQueryConfiguration;
      final page = configuration.additionalParameters
          .whereType<off.PageNumber>()
          .first
          .page;
      if (page < 1) {
        throw ArgumentError('OFF pagination count starts from 1');
      }
      if (page == 1) {
        return off.SearchResult(
            page: page,
            pageSize: 3,
            count: offProducts.length,
            skip: 0,
            products: [offProducts[0], offProducts[1], offProducts[2]]);
      } else if (page == 2) {
        return off.SearchResult(
            page: page,
            pageSize: 3,
            count: offProducts.length,
            skip: 3,
            products: [offProducts[3], offProducts[4], offProducts[5]]);
      } else if (page == 3) {
        return off.SearchResult(
            page: page,
            pageSize: 3,
            count: offProducts.length,
            skip: 6,
            products: [offProducts[6]]);
      } else {
        throw Exception("Page 3 should've been the last one");
      }
    });

    final backendProducts = barcodes
        .map((e) => BackendProduct((v) => v
          ..barcode = e
          ..veganStatus = VegStatus.negative.name
          ..veganStatusSource = VegStatusSource.moderator.name))
        .toList();
    final productsRes =
        await productsManager.inflateProducts(backendProducts, [LangCode.ru]);

    final products = productsRes.unwrap();
    final expectedProducts = barcodes.map((e) => ProductLangSlice((v) => v
          ..lang = LangCode.ru
          ..barcode = e
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.moderator
          ..name = 'name$e'
          ..brands.add('Brand name')
          ..ingredientsText = 'lemon, water'
          ..imageFront = Uri.parse(offExpectedImageFrontRu)
          ..imageFrontThumb = Uri.parse(offExpectedImageFrontThumbRu)
          ..imageIngredients = Uri.parse(offExpectedImageIngredientsRu))
        .productForTests());
    expect(products.toSet(), equals(expectedProducts.toSet()));

    // We expect the backend to not be touched since
    // we already have backend products.
    verifyNever(backend.requestProducts(any, any));
  });

  test('inflate off products', () async {
    final backendProducts = [
      BackendProduct((v) => v
        ..barcode = '123'
        ..veganStatus = VegStatus.positive.name
        ..veganStatusSource = VegStatusSource.moderator.name),
      BackendProduct((v) => v
        ..barcode = '124'
        ..veganStatus = VegStatus.unknown.name
        ..veganStatusSource = VegStatusSource.community.name),
    ];
    setUpBackendProducts(Ok(backendProducts));

    final offProducts = [
      off.Product.fromJson({
        'code': '123',
        'product_name_ru': 'name',
        'brands_tags': ['Brand name'],
        'ingredients_text_ru': 'lemon, water',
      }),
      off.Product.fromJson({
        'code': '124',
        'product_name_ru': 'name2',
        'brands_tags': ['Brand name2'],
        'ingredients_text_ru': 'lemon2, water2',
      })
    ];
    final productsRes =
        await productsManager.inflateOffProducts(offProducts, [LangCode.ru]);
    final products = productsRes.unwrap();

    final expectedProducts = [
      ProductLangSlice((v) => v
        ..lang = LangCode.ru
        ..barcode = '123'
        ..veganStatus = VegStatus.positive
        ..veganStatusSource = VegStatusSource.moderator
        ..name = 'name'
        ..brands.add('Brand name')
        ..ingredientsText = 'lemon, water').productForTests(),
      ProductLangSlice((v) => v
        ..lang = LangCode.ru
        ..barcode = '124'
        ..veganStatus = VegStatus.unknown
        ..veganStatusSource = VegStatusSource.community
        ..name = 'name2'
        ..brands.add('Brand name2')
        ..ingredientsText = 'lemon2, water2').productForTests(),
    ];

    expect(products.toSet(), equals(expectedProducts.toSet()));

    // We expect OFF to not be touched since
    // we already have OFF products.
    verifyZeroInteractions(offApi);
  });
}
