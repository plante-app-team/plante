import 'dart:convert';
import 'dart:io';

import 'package:plante/base/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/base/device_info.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_response.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/model/gender.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';

const BACKEND_ADDRESS = 'planteapp.com';

const PREF_BACKEND_CLIENT_TOKEN = 'BACKEND_CLIENT_TOKEN';

class BackendObserver {
  void onBackendError(BackendError error) {}
}

class Backend {
  final UserParamsController _userParamsController;
  final HttpClient _http;
  final Settings _settings;

  final _observers = <BackendObserver>[];

  Backend(this._userParamsController, this._http, this._settings);

  void addObserver(BackendObserver observer) => _observers.add(observer);
  void removeObserver(BackendObserver observer) => _observers.remove(observer);

  Future<bool> isLoggedIn() async {
    final userParams = await _userParamsController.getUserParams();
    return userParams?.backendClientToken != null;
  }

  Future<Result<UserParams, BackendError>> loginOrRegister(
      String googleIdToken) async {
    if (await isLoggedIn()) {
      final userParams = await _userParamsController.getUserParams();
      return Ok(userParams!);
    }

    // Register

    final deviceId = (await DeviceInfo.get()).deviceID;
    var response = await _backendGet('register_user/',
        {'googleIdToken': googleIdToken, 'deviceId': deviceId});
    if (response.isError) {
      return Err(_errFromResp(response));
    }

    var json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }

    if (!_isError(json)) {
      final userParams = UserParams.fromJson(json)!;
      Log.i('Backend: user registered: ${userParams.toString()}');
      return Ok(userParams);
    }
    if (_errFromJson(json).errorKind != BackendErrorKind.ALREADY_REGISTERED) {
      return Err(_errFromJson(json));
    }

    // Login

    response = await _backendGet(
        'login_user/', {'googleIdToken': googleIdToken, 'deviceId': deviceId});
    if (response.isError) {
      return Err(_errFromResp(response));
    }

    json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }

    if (!_isError(json)) {
      final userParams = UserParams.fromJson(json)!;
      Log.i('Backend: user logged in: ${userParams.toString()}');
      return Ok(userParams);
    } else {
      return Err(_errFromJson(json));
    }
  }

  Future<Result<bool, BackendError>> updateUserParams(UserParams userParams,
      {String? backendClientTokenOverride}) async {
    final params = <String, String>{};
    if (userParams.name != null && userParams.name!.isNotEmpty) {
      params['name'] = userParams.name!;
    }
    if (userParams.gender != null) {
      params['gender'] = userParams.gender!.name;
    }
    if (userParams.birthday != null) {
      params['birthday'] = userParams.birthdayStr!;
    }
    if (userParams.eatsMilk != null) {
      params['eatsMilk'] = userParams.eatsMilk!.toString();
    }
    if (userParams.eatsEggs != null) {
      params['eatsEggs'] = userParams.eatsEggs!.toString();
    }
    if (userParams.eatsHoney != null) {
      params['eatsHoney'] = userParams.eatsHoney!.toString();
    }
    if (params.isEmpty) {
      return Ok(false);
    }

    final response = await _backendGet('update_user_data/', params,
        backendClientTokenOverride: backendClientTokenOverride);
    if (response.isOk) {
      return Ok(true);
    } else {
      return Err(_errFromResp(response));
    }
  }

  Future<Result<BackendProduct?, BackendError>> requestProduct(
      String barcode) async {
    if (await _settings.fakeOffApi()) {
      // Sure, that's the requested product (lie)
      return Ok(BackendProduct((e) => e.barcode = barcode));
    }

    final response = await _backendGet('product_data/', {'barcode': barcode});
    if (response.isError) {
      return Err(_errFromResp(response));
    }
    final json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }

    if (_isError(json)) {
      final error = _errFromJson(json);
      if (error.errorKind == BackendErrorKind.PRODUCT_NOT_FOUND) {
        return Ok(null);
      } else {
        return Err(error);
      }
    }
    return Ok(BackendProduct.fromJson(json));
  }

  Future<Result<None, BackendError>> createUpdateProduct(String barcode,
      {VegStatus? vegetarianStatus, VegStatus? veganStatus}) async {
    if (await _settings.fakeOffApi()) {
      // Sure, the update was ok (lie)
      return Ok(None());
    }

    final params = <String, String>{};
    params['barcode'] = barcode;
    if (vegetarianStatus != null) {
      params['vegetarianStatus'] = vegetarianStatus.name;
    }
    if (veganStatus != null) {
      params['veganStatus'] = veganStatus.name;
    }
    final response = await _backendGet('create_update_product/', params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<None, BackendError>> sendReport(
      String barcode, String reportText) async {
    final params = <String, String>{};
    params['barcode'] = barcode;
    params['text'] = reportText;
    final response = await _backendGet('make_report/', params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<None, BackendError>> sendProductScan(String barcode) async {
    final params = <String, String>{};
    params['barcode'] = barcode;
    final response = await _backendGet('product_scan/', params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<UserParams, BackendError>> userData() async {
    final response = await _backendGet('user_data/', {});
    if (response.isError) {
      return Err(_errFromResp(response));
    }

    final json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }

    if (!_isError(json)) {
      final backendUserParams = UserParams.fromJson(json)!;
      // NOTE: client token is not present in the response, but
      // the Backend class knows the token and can set it.
      // If it wouldn't set it, the `userData()` method clients would get
      // not fully set params.
      final storedUserParams = await _userParamsController.getUserParams();
      return Ok(backendUserParams.rebuild(
          (e) => e..backendClientToken = storedUserParams?.backendClientToken));
    } else {
      return Err(_errFromJson(json));
    }
  }

  Future<Result<List<BackendProductsAtShop>, BackendError>>
      requestProductsAtShops(Iterable<String> osmIds) async {
    final response =
        await _backendGet('products_at_shops_data/', {'osmShopsIds': osmIds});
    if (response.isError) {
      return Err(_errFromResp(response));
    }

    final json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }

    if (!json.containsKey('results')) {
      Log.w('Invalid products_at_shops_data response: $json');
      return Err(BackendError.invalidJson(response.body));
    }

    final results = json['results'] as Map<String, dynamic>;
    final shops = <BackendProductsAtShop>[];
    for (final result in results.values) {
      final shop =
          BackendProductsAtShop.fromJson(result as Map<String, dynamic>);
      if (shop != null) {
        shops.add(shop);
      }
    }
    return Ok(shops);
  }

  Result<None, BackendError> _noneOrErrorFrom(BackendResponse response) {
    if (response.isError) {
      return Err(_errFromResp(response));
    }
    final json = _jsonDecodeSafe(response.body);
    if (json != null && !_isError(json)) {
      return Ok(None());
    } else {
      return Err(_errOther());
    }
  }

  Future<BackendResponse> _backendGet(String path, Map<String, dynamic>? params,
      {Map<String, String>? headers,
      String? backendClientTokenOverride}) async {
    final userParams = await _userParamsController.getUserParams();
    final backendClientToken =
        backendClientTokenOverride ?? userParams?.backendClientToken;

    final headersReally =
        Map<String, String>.from(headers ?? <String, String>{});
    if (backendClientToken != null) {
      headersReally['Authorization'] = 'Bearer $backendClientToken';
    }
    final url = Uri.https(BACKEND_ADDRESS, '/backend/$path', params);
    try {
      final httpResponse = await _http.get(url, headers: headersReally);
      return BackendResponse.fromHttpResponse(httpResponse);
    } on IOException catch (e) {
      return BackendResponse.fromError(e, url);
    }
  }

  bool _isError(Map<String, dynamic> json) {
    return BackendError.isError(json);
  }

  BackendError _errFromResp(BackendResponse response) {
    final error = BackendError.fromResp(response);
    _observers.forEach((obs) {
      obs.onBackendError(error);
    });
    return error;
  }

  BackendError _errFromJson(Map<String, dynamic> json) {
    final error = BackendError.fromJson(json);
    _observers.forEach((obs) {
      obs.onBackendError(error);
    });
    return error;
  }

  BackendError _errInvalidJson(String invalidJson) {
    final error = BackendError.invalidJson(invalidJson);
    _observers.forEach((obs) {
      obs.onBackendError(error);
    });
    return error;
  }

  BackendError _errOther() {
    final error = BackendError.other();
    _observers.forEach((obs) {
      obs.onBackendError(error);
    });
    return error;
  }
}

Map<String, dynamic>? _jsonDecodeSafe(String str) {
  try {
    return jsonDecode(str) as Map<String, dynamic>?;
  } on FormatException catch (e) {
    Log.w("Backend: couldn't decode safe: %str", ex: e);
    return null;
  }
}
