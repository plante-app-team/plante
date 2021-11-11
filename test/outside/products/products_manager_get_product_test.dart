import 'dart:convert';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/model/SearchResult.dart' as off;
import 'package:openfoodfacts/model/parameter/Page.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart' as off;
import 'package:plante/base/result.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/requested_products_result.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../off/off_json_product_images_utils.dart';
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

  test('get product when the product is on both OFF and backend', () async {
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
    setUpBackendProducts(Ok([backendProduct]));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    final expectedProduct = ProductLangSlice((v) => v
          ..lang = LangCode.ru
          ..barcode = '123'
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.moderator
          ..name = 'name'
          ..brands.add('Brand name')
          ..ingredientsText = 'lemon, water'
          ..imageFront = Uri.parse(offExpectedImageFrontRu)
          ..imageFrontThumb = Uri.parse(offExpectedImageFrontThumbRu)
          ..imageIngredients = Uri.parse(offExpectedImageIngredientsRu))
        .productForTests();
    expect(product, equals(expectedProduct));
  });

  test('get product when the product is on OFF only', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name',
      'brands_tags': ['Brand name'],
      'ingredients_text_ru': 'lemon, water',
      'selected_images': jsonDecode(offSelectedImagesRuJson),
    });
    setUpOffProducts([offProduct]);

    setUpBackendProducts(Ok(const []));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    final expectedProduct = ProductLangSlice((v) => v
          ..lang = LangCode.ru
          ..barcode = '123'
          ..veganStatus = null
          ..veganStatusSource = null
          ..name = 'name'
          ..brands.add('Brand name')
          ..ingredientsText = 'lemon, water'
          ..ingredientsAnalyzed.addAll([])
          ..imageFront = Uri.parse(offExpectedImageFrontRu)
          ..imageFrontThumb = Uri.parse(offExpectedImageFrontThumbRu)
          ..imageIngredients = Uri.parse(offExpectedImageIngredientsRu))
        .productForTests();
    expect(product, equals(expectedProduct));
  });

  test('get product when the product is on backend only', () async {
    setUpOffProducts(const []);

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    setUpBackendProducts(Ok([backendProduct]));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product, equals(null));
  });

  test('get many products with pagination', () async {
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
          ..veganStatus = VegStatus.negative.name
          ..veganStatusSource = VegStatusSource.moderator.name))
        .toList();
    var zeroBackendPageMet = false; // Plante backend pagination works from 0
    when(backend.requestProducts(any, any)).thenAnswer((invc) async {
      final page = invc.positionalArguments[1] as int;
      if (page == 0) {
        zeroBackendPageMet = true;
        return Ok(RequestedProductsResult([
          backendProducts[0],
          backendProducts[1],
          backendProducts[2],
          backendProducts[3],
        ], 0, false));
      } else if (page == 1) {
        return Ok(RequestedProductsResult([
          backendProducts[4],
          backendProducts[5],
          backendProducts[6],
        ], 1, true));
      } else {
        throw Exception("Page 2 should've been the last one");
      }
    });

    final productRes =
        await productsManager.getProducts(barcodes, [LangCode.ru]);
    expect(zeroBackendPageMet, isTrue);
    final products = productRes.unwrap();
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
  });

  test('get product when OFF throws network error', () async {
    when(offApi.getProductList(any))
        .thenAnswer((_) async => throw const SocketException(''));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    expect(productRes.unwrapErr(), equals(ProductsManagerError.NETWORK_ERROR));
  });

  test('get product when backend returns network error', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name',
      'brands_tags': ['Brand name'],
      'ingredients_text_ru': 'lemon, water',
      'selected_images': jsonDecode(offSelectedImagesRuJson),
    });
    setUpOffProducts([offProduct]);

    setUpBackendProducts(
        Err(BackendErrorKind.NETWORK_ERROR.toErrorForTesting()));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    expect(productRes.unwrapErr(), equals(ProductsManagerError.NETWORK_ERROR));
  });
}
