import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/model/SearchResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/base.dart';
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart' as off;
import 'package:plante/base/settings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/off/fake_off_api.dart';
import 'package:plante/outside/off/off_shop.dart';

/// OFF wrapper mainly needed for DI in tests
class OffApi {
  final Settings _settings;
  final HttpClient _httpClient;
  final FakeOffApi _fakeOffApi;

  OffApi(this._settings, this._httpClient) :
    _fakeOffApi = FakeOffApi(_settings,_httpClient);

  @visibleForTesting
  HttpClient get httpClient {
    return _httpClient;
  }

  Future<off.SearchResult> getProductList(
      off.ProductListQueryConfiguration configuration) async {
    if (await _settings.testingBackends()) {
      return await _fakeOffApi.getProductList(configuration);
    }
    return await off.OpenFoodAPIClient.getProductList(null, configuration);
  }

  Future<off.Status> saveProduct(off.User user, off.Product product) async {
    if (await _settings.testingBackends()) {
      return await _fakeOffApi.saveProduct(user, product);
    }
    final result = await off.OpenFoodAPIClient.saveProduct(user, product);
    if (result.error != null) {
      Log.w('OffApi.saveProduct error: ${result.toJson()}');
    }
    return result;
  }

  Future<off.Status> addProductImage(off.User user, off.SendImage image) async {
    if (await _settings.testingBackends()) {
      return await _fakeOffApi.addProductImage(user, image);
    }
    final result = await off.OpenFoodAPIClient.addProductImage(user, image);
    if (result.error != null) {
      Log.w('OffApi.addProductImage error: ${result.toJson()}, img: $image');
    }
    return result;
  }

  Future<off.OcrIngredientsResult> extractIngredients(
      off.User user, String barcode, off.OpenFoodFactsLanguage language) async {
    if (await _settings.testingBackends()) {
      return await _fakeOffApi.extractIngredients(user, barcode, language);
    }
    final result =
        await off.OpenFoodAPIClient.extractIngredients(user, barcode, language);
    if (result.status != 0) {
      Log.w('OffApi.extractIngredients error: ${result.toJson()}');
    }
    return result;
  }

  Future<List<OffShop>> getShopsForLocation(
      String countryIso) async {
    List<OffShop> shops = [];
    final http.Response response = await _httpClient.get(
        Uri.parse('https://$countryIso.openfoodfacts.org/stores.json'),
        headers: {
          'user-agent': await userAgent()
        });
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      shops = result['tags']
          .map<OffShop>(
              (shop) => OffShop.fromJson(shop as Map<String, dynamic>))
          .toList() as List<OffShop>;
    } else {
      Log.w('OffApi.getShopsForLocation error: ${response.body}');
    }
    return shops;
  }

  Future<off.SearchResult> getVeganProductsForShop(
      String countryIso, String shop, int page) async {
    late off.SearchResult searchResult = const off.SearchResult();
    final http.Response response = await _httpClient.get(
        Uri.parse(
            'https://$countryIso.openfoodfacts.org/api/v2/search?ingredients_analysis_tags=en:vegan&stores_tags=$shop&page_size=20&page=$page'),
        headers: {
          'user-agent': await userAgent()
        });
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      searchResult = off.SearchResult.fromJson(result as Map<String, dynamic>);
      //convert product _productsConverter.convertAndCache
      //final List<Product> products = [];
      //for (final off.Product offProduct in searchResult.products!){
        //final product = _productConverter.convertAndCache(offProduct, null, [LangCode.be]);
        //products.add(product);
      //}
    } else {
      Log.w('OffApi.getProductsForShop $shop error: ${response.body}');
    }
    return searchResult;
  }
}
