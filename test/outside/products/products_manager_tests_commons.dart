import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/model/SearchResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/requested_products_result.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/taken_products_images_storage.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';

class ProductsManagerTestCommons {
  late MockOffApi offApi;
  late MockBackend backend;
  late TakenProductsImagesStorage takenProductsImagesStorage;
  late ProductsManager productsManager;

  void setUpOffProducts(List<off.Product> products) {
    when(offApi.getProductList(any)).thenAnswer((_) async => off.SearchResult(
        page: 1,
        pageSize: products.length,
        count: products.length,
        skip: 0,
        products: products));
  }

  void setUpBackendProducts(
      Result<List<BackendProduct>, BackendError> productsRes) {
    when(backend.requestProducts(any, any)).thenAnswer((invc) async {
      if (productsRes.isErr) {
        return Err(productsRes.unwrapErr());
      }
      final products = productsRes.unwrap();
      final requestedBarcodes =
          (invc.positionalArguments[0] as List<String>).toSet();
      final passedBarcodes = products.map((e) => e.barcode).toSet();
      if (products.isNotEmpty &&
          !setEquals(requestedBarcodes, passedBarcodes)) {
        throw ArgumentError(
            'Requested and passed barcodes differ: $requestedBarcodes, $passedBarcodes');
      }
      return Ok(RequestedProductsResult(products, 0, true));
    });
  }

  ProductsManagerTestCommons._();

  static Future<ProductsManagerTestCommons> create() async {
    final result = ProductsManagerTestCommons._();
    await result._init();
    return result;
  }

  Future<void> _init() async {
    offApi = MockOffApi();
    backend = MockBackend();
    takenProductsImagesStorage = TakenProductsImagesStorage(
        fileName: 'products_manager_test_taken_images.json');
    await takenProductsImagesStorage.clearForTesting();

    productsManager = ProductsManager(
        offApi, backend, takenProductsImagesStorage, FakeAnalytics());

    when(offApi.saveProduct(any, any)).thenAnswer((_) async => off.Status());
    setUpOffProducts([off.Product(barcode: '123')]);
    when(offApi.addProductImage(any, any))
        .thenAnswer((_) async => off.Status());
    when(offApi.extractIngredients(any, any, any))
        .thenAnswer((_) async => const off.OcrIngredientsResult());

    when(backend.createUpdateProduct(any,
            vegetarianStatus: anyNamed('vegetarianStatus'),
            veganStatus: anyNamed('veganStatus'),
            changedLangs: anyNamed('changedLangs')))
        .thenAnswer((_) async => Ok(None()));
    setUpBackendProducts(Ok([BackendProduct((v) => v.barcode = '123')]));
  }

  void ensureProductIsInOFF(Product product) {
    final offProduct = off.Product.fromJson({
      'code': product.barcode,
      'product_name_ru': product.name,
      'brands_tags': product.brands?.toList() ?? [],
      'ingredients_text_ru': product.ingredientsText,
    });
    setUpOffProducts([offProduct]);
    setUpBackendProducts(Ok(const []));
  }
}
