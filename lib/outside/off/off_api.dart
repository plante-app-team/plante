import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/model/SearchResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart' as off;
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/off/fake_off_api.dart';
import 'package:plante/outside/off/off_shop.dart';

/// Errors caused by OFF REST API (not by the OFF Dart SDK).
enum OffRestApiError {
  NETWORK,
  OTHER,
}

/// OFF wrapper mainly needed for DI in tests
class OffApi {
  static const _REST_API_TIMEOUT = Duration(seconds: 10);
  final Settings _settings;
  final HttpClient _httpClient;
  final FakeOffApi _fakeOffApi;

  OffApi(this._settings, this._httpClient)
      : _fakeOffApi = FakeOffApi(_settings);

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

  Future<Result<List<OffShop>, OffRestApiError>> getShopsForLocation(
      String countryIso) async {
    final http.Response response;
    try {
      response = await _httpClient.get(
          Uri.parse('https://$countryIso.openfoodfacts.org/stores.json'),
          headers: {
            'user-agent': await userAgent()
          }).timeout(_REST_API_TIMEOUT);
    } on IOException catch (e) {
      Log.w('OffApi.getShopsForLocation network error', ex: e);
      return Err(OffRestApiError.NETWORK);
    } on TimeoutException catch (e) {
      Log.w('OffApi.getShopsForLocation timeout', ex: e);
      return Err(OffRestApiError.NETWORK);
    }

    if (response.statusCode != 200) {
      Log.w('OffApi.getShopsForLocation response error: $response');
      return Err(OffRestApiError.OTHER);
    }

    final resultJson = _jsonDecodeSafe(response.body);
    if (resultJson == null) {
      Log.w('OffApi.getShopsForLocation invalid JSON: ${response.body}');
      return Err(OffRestApiError.OTHER);
    }
    final shopsJson = resultJson['tags'] as List<dynamic>;
    return Ok(shopsJson.map(OffShop.fromJson).whereType<OffShop>().toList());
  }
}

Map<String, dynamic>? _jsonDecodeSafe(String str) {
  try {
    return jsonDecode(str) as Map<String, dynamic>?;
  } on FormatException catch (e) {
    Log.w("OffApi: couldn't decode safe: %str", ex: e);
    return null;
  }
}
