import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/model/SearchResult.dart' as off;
import 'package:openfoodfacts/model/parameter/Page.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart' as off;
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
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

  test('inflate backend product', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name',
      'brands_tags': ['Brand name'],
      'ingredients_text_ru': 'lemon, water',
      'selected_images': jsonDecode(commons.selectedImagesRuJson),
    });
    setUpOffProducts([offProduct]);

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive.name
      ..vegetarianStatusSource = VegStatusSource.community.name
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    final productRes =
        await productsManager.inflate(backendProduct, [LangCode.ru]);
    final product = productRes.unwrap();

    final expectedProduct = ProductLangSlice((v) => v
          ..lang = LangCode.ru
          ..barcode = '123'
          ..vegetarianStatus = VegStatus.positive
          ..vegetarianStatusSource = VegStatusSource.community
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.moderator
          ..name = 'name'
          ..brands.add('Brand name')
          ..ingredientsText = 'lemon, water'
          ..ingredientsAnalyzed.addAll([])
          ..imageFront = Uri.parse(commons.expectedImageFrontRu)
          ..imageFrontThumb = Uri.parse(commons.expectedImageFrontThumbRu)
          ..imageIngredients = Uri.parse(commons.expectedImageIngredientsRu))
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
              'selected_images': jsonDecode(commons.selectedImagesRuJson),
            }))
        .toList();
    when(offApi.getProductList(any)).thenAnswer((invc) async {
      final configuration =
          invc.positionalArguments[0] as off.ProductListQueryConfiguration;
      final page =
          configuration.additionalParameters.whereType<off.Page>().first.page;
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
          ..vegetarianStatus = VegStatus.positive.name
          ..vegetarianStatusSource = VegStatusSource.community.name
          ..veganStatus = VegStatus.negative.name
          ..veganStatusSource = VegStatusSource.moderator.name))
        .toList();
    final productsRes =
        await productsManager.inflateProducts(backendProducts, [LangCode.ru]);

    final products = productsRes.unwrap();
    final expectedProducts = barcodes.map((e) => ProductLangSlice((v) => v
          ..lang = LangCode.ru
          ..barcode = e
          ..vegetarianStatus = VegStatus.positive
          ..vegetarianStatusSource = VegStatusSource.community
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.moderator
          ..name = 'name$e'
          ..brands.add('Brand name')
          ..ingredientsText = 'lemon, water'
          ..imageFront = Uri.parse(commons.expectedImageFrontRu)
          ..imageFrontThumb = Uri.parse(commons.expectedImageFrontThumbRu)
          ..imageIngredients = Uri.parse(commons.expectedImageIngredientsRu))
        .productForTests());
    expect(products.toSet(), equals(expectedProducts.toSet()));

    // We expect the backend to not be touched since
    // we already have backend products.
    verifyNever(backend.requestProducts(any, any));
  });
}
