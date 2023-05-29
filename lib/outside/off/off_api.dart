import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart' as off;
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/off/off_shop.dart';

/// Errors caused by OFF REST API (not by the OFF Dart SDK).
enum OffRestApiError {
  NETWORK,
  OTHER,
}

/// OFF wrapper mainly needed for DI in tests
class OffApi {
  static const _REST_API_TIMEOUT = Duration(seconds: 10);
  final HttpClient _httpClient;

  OffApi(this._httpClient);

  Future<off.SearchResult> getProductList(
      off.ProductListQueryConfiguration configuration) async {
    return await off.OpenFoodAPIClient.getProductList(null, configuration);
  }

  Future<off.Status> saveProduct(off.User user, off.Product product) async {
    final result = await off.OpenFoodAPIClient.saveProduct(user, product);
    if (result.error != null) {
      Log.w('OffApi.saveProduct error: ${result.toJson()}');
    }
    return result;
  }

  Future<off.Status> addProductImage(off.User user, off.SendImage image) async {
    final result = await off.OpenFoodAPIClient.addProductImage(user, image);
    if (result.error != null) {
      Log.w('OffApi.addProductImage error: ${result.toJson()}, img: $image');
    }
    return result;
  }

  Future<off.OcrIngredientsResult> extractIngredients(
      off.User user, String barcode, off.OpenFoodFactsLanguage language) async {
    final result =
        await off.OpenFoodAPIClient.extractIngredients(user, barcode, language);
    if (result.status != 0) {
      Log.w('OffApi.extractIngredients error: ${result.toJson()}');
    }
    return result;
  }

  Future<off.SearchResult> searchProducts(
      off.ProductSearchQueryConfiguration configuration) async {
    final result =
        await off.OpenFoodAPIClient.searchProducts(null, configuration);
    if (result.products == null) {
      Log.w('OffApi.searchProducts no products in result: $result');
    }
    return result;
  }

  Future<Result<String, OffRestApiError>> getShopsJsonForCountry(
      String countryIso) async {
    countryIso = _getOffCountryCode(countryIso);
    final responseRes =
        await _get(Uri.https('$countryIso.openfoodfacts.org', 'stores.json'));
    if (responseRes.isErr) {
      return Err(responseRes.unwrapErr());
    }
    return Ok(responseRes.unwrap());
  }

  Future<Result<String, OffRestApiError>> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await _httpClient.get(uri, headers: {
        'user-agent': await userAgent()
      }).timeout(_REST_API_TIMEOUT);
    } on IOException catch (e) {
      Log.w('OffApi._get $uri network error', ex: e);
      return Err(OffRestApiError.NETWORK);
    } on TimeoutException catch (e) {
      Log.w('OffApi._get $uri timeout', ex: e);
      return Err(OffRestApiError.NETWORK);
    }

    if (response.statusCode != 200) {
      Log.w('OffApi._get $uri response error: $response');
      return Err(OffRestApiError.OTHER);
    }

    return Ok(response.body);
  }

  Future<Result<List<String>, OffRestApiError>> getBarcodesVeganByIngredients(
      OffShop shop, List<String> productsCategories) async {
    return await _searchBarcodes(shop.country, {
      'ingredients_analysis_tags': 'en:vegan',
      'stores_tags': shop.id,
      'categories_tags': productsCategories.join('|'),
      'sort_by': 'created_t',
    });
  }

  Future<Result<List<String>, OffRestApiError>> getBarcodesVeganByLabel(
      OffShop shop) async {
    return await _searchBarcodes(shop.country, {
      'labels_tags': 'en:vegan',
      'stores_tags': shop.id,
      'sort_by': 'created_t',
    });
  }

  Future<Result<List<String>, OffRestApiError>> _searchBarcodes(
      String countryCode, Map<String, String> additionalQueryParams) async {
    countryCode = _getOffCountryCode(countryCode);
    final queryParams = {
      'page_size': '1000', // We want to get ALL products
      'page': '1',
      'fields': 'code',
      ...additionalQueryParams
    };
    final uri = Uri.https(
        '$countryCode.openfoodfacts.org', 'api/v2/search', queryParams);

    final responseRes = await _get(uri);
    if (responseRes.isErr) {
      return Err(responseRes.unwrapErr());
    }
    final result = await compute(_extractBarcodes, responseRes.unwrap());
    if (result != null) {
      return Ok(result);
    } else {
      Log.w('OffApi._searchBarcodes invalid JSON: $responseRes');
      return Err(OffRestApiError.OTHER);
    }
  }

  static List<String>? _extractBarcodes(String jsonStr) {
    final result = <String>[];
    final json = jsonDecodeSafe(jsonStr);
    if (json == null) {
      return null;
    }
    for (final productJson in json['products'] as Iterable<dynamic>) {
      if (productJson is! Map<String, dynamic>) {
        continue;
      }
      if (!productJson.containsKey('code')) {
        continue;
      }
      result.add(productJson['code'].toString());
    }
    return result;
  }
}

///This method translates countryIsoCode to codes used by OFF
///@ the moment only GB
String _getOffCountryCode(String countryCode) =>
    countryCode == CountryCode.GREAT_BRITAIN
        ? CountryCode.UNITED_KINGDOM
        : countryCode;
