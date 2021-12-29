import 'dart:collection';

import 'package:openfoodfacts/model/OcrIngredientsResult.dart';
import 'package:openfoodfacts/model/Product.dart';
import 'package:openfoodfacts/model/SearchResult.dart';
import 'package:openfoodfacts/model/SendImage.dart';
import 'package:openfoodfacts/model/Status.dart';
import 'package:openfoodfacts/model/User.dart';
import 'package:openfoodfacts/utils/LanguageHelper.dart';
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart';
import 'package:openfoodfacts/utils/ProductSearchQueryConfiguration.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';

class FakeOffApi implements OffApi {
  ArgResCallback<ProductListQueryConfiguration, SearchResult?>?
      _productsListRespCallback;
  ArgResCallback<Product, Status?>? _saveProductRespCallback;

  final _saveProductCalls = <Product>[];

  // ignore: non_constant_identifier_names
  void setProductsListResponses_testing(
      ArgResCallback<ProductListQueryConfiguration, SearchResult?>? callback) {
    _productsListRespCallback = callback;
  }

  // ignore: non_constant_identifier_names
  void setProductsListResponsesSimple_testing(
      ArgResCallback<ProductListQueryConfiguration, Iterable<Product>?>?
          callback) {
    if (callback == null) {
      _productsListRespCallback = null;
      return;
    }
    _productsListRespCallback = (config) {
      final products = callback.call(config);
      return SearchResult(products: products?.toList());
    };
  }

  // ignore: non_constant_identifier_names
  void setSaveProductResponses_testing(
      ArgResCallback<Product, Status?>? callback) {
    _saveProductRespCallback = callback;
  }

  // ignore: non_constant_identifier_names
  List<Product> saveProductCalls_testing() =>
      UnmodifiableListView(_saveProductCalls);

  // ignore: non_constant_identifier_names
  void clearSaveProductsCalls_testing() => _saveProductCalls.clear();

  @override
  Future<SearchResult> getProductList(
      ProductListQueryConfiguration configuration) async {
    final resp = _productsListRespCallback?.call(configuration);
    if (resp != null) {
      return resp;
    }
    final products = configuration.barcodes.map((e) => Product(barcode: e));
    return SearchResult(products: products.toList());
  }

  @override
  Future<Status> saveProduct(User user, Product product) async {
    _saveProductCalls.add(product);
    final resp = _saveProductRespCallback?.call(product);
    if (resp != null) {
      return resp;
    }
    return Status(status: 'ok');
  }

  @override
  Future<Status> addProductImage(User user, SendImage image) {
    throw UnimplementedError('Not implemented yet');
  }

  @override
  Future<OcrIngredientsResult> extractIngredients(
      User user, String barcode, OpenFoodFactsLanguage language) {
    throw UnimplementedError('Not implemented yet');
  }

  @override
  Future<Result<List<String>, OffRestApiError>> getBarcodesVeganByIngredients(
      OffShop shop, List<String> productsCategories) {
    throw UnimplementedError('Not implemented yet');
  }

  @override
  Future<Result<List<String>, OffRestApiError>> getBarcodesVeganByLabel(
      OffShop shop) {
    throw UnimplementedError('Not implemented yet');
  }

  @override
  Future<Result<String, OffRestApiError>> getShopsJsonForCountry(
      String countryIso) {
    throw UnimplementedError('Not implemented yet');
  }

  @override
  Future<SearchResult> searchProducts(
      ProductSearchQueryConfiguration configuration) {
    throw UnimplementedError('Not implemented yet');
  }
}
