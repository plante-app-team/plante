import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/result.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/cmds/create_update_product_cmd.dart';
import 'package:plante/outside/backend/cmds/request_products_cmd.dart';
import 'package:plante/products/products_manager.dart';
import 'package:plante/products/taken_products_images_storage.dart';

import '../common_mocks.mocks.dart';
import '../z_fakes/fake_analytics.dart';
import '../z_fakes/fake_backend.dart';

class ProductsManagerTestCommons {
  late MockOffApi offApi;
  late FakeBackend backend;
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

  void setUpBackendProducts(Result<List<BackendProduct>, None> productsRes) {
    backend.setResponseFunction_testing(REQUEST_PRODUCTS_CMD, (req) {
      if (productsRes.isErr) {
        return Err(500);
      }
      final products = productsRes.unwrap();
      final requestedBarcodes = req.url.queryParametersAll['barcodes']!;
      final passedBarcodes = products.map((e) => e.barcode).toSet();
      if (products.isNotEmpty &&
          !setEquals(requestedBarcodes.toSet(), passedBarcodes)) {
        throw ArgumentError(
            'Requested and passed barcodes differ: $requestedBarcodes, $passedBarcodes');
      }
      final result = {
        'last_page': true,
        'products': products.map((e) => e.toJson()).toList()
      };
      return Ok(jsonEncode(result));
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
    backend = FakeBackend();
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

    backend.setResponse_testing(CREATE_UPDATE_PRODUCT_CMD, '{}');
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

extension FakeBackendExt on FakeBackend {
  void verifyCreateUpdateProductCall(
      {String? barcode,
      VegStatus? veganStatus,
      List<LangCode>? changedLangs,
      int? calledTimes}) {
    final requests = getRequestsMatching_testing(CREATE_UPDATE_PRODUCT_CMD);
    var callsActual = 0;

    for (final request in requests) {
      final currentBarcode = request.url.queryParameters['barcode'];
      final currentVeganStatus = request.url.queryParameters['veganStatus'];
      final langs = request.url.queryParametersAll['langs'] ?? [];
      if (barcode != null && barcode != currentBarcode) {
        continue;
      }
      if (veganStatus != null && veganStatus.name != currentVeganStatus) {
        continue;
      }
      if (changedLangs != null &&
          !listEquals(changedLangs.map((e) => e.name).toList(), langs)) {
        continue;
      }
      callsActual += 1;
    }

    final callsExpected = calledTimes ?? 1;
    if (callsExpected != callsActual) {
      throw AssertionError('Not expected number of calls '
          '(expected $callsExpected got $callsActual). \n'
          'Expected params: ${barcode ?? ''} ${veganStatus?.name ?? ''} ${changedLangs?.toString() ?? ''}\n'
          'All calls: $requests');
    }
  }
}
