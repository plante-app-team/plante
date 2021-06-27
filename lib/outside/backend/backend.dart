import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/base/device_info.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_response.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/fake_backend.dart';
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
  late final Backend _fakeBackend;
  final Analytics _analytics;
  final UserParamsController _userParamsController;
  final HttpClient _http;
  final Settings _settings;

  final _observers = <BackendObserver>[];

  Backend(
      this._analytics, this._userParamsController, this._http, this._settings) {
    _fakeBackend = FakeBackend(_settings);
  }

  void addObserver(BackendObserver observer) => _observers.add(observer);
  void removeObserver(BackendObserver observer) => _observers.remove(observer);

  Future<bool> isLoggedIn() async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.isLoggedIn();
    }
    final userParams = await _userParamsController.getUserParams();
    return userParams?.backendClientToken != null;
  }

  Future<Result<UserParams, BackendError>> loginOrRegister(
      {String? googleIdToken, String? appleAuthorizationCode}) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.loginOrRegister(
          googleIdToken: googleIdToken,
          appleAuthorizationCode: appleAuthorizationCode);
    }

    if (await isLoggedIn()) {
      final userParams = await _userParamsController.getUserParams();
      return Ok(userParams!);
    }

    // Register
    final deviceId = (await DeviceInfo.get()).deviceID;
    final queryParams = {
      'deviceId': deviceId,
    };
    if (googleIdToken != null) {
      queryParams['googleIdToken'] = googleIdToken;
    }
    if (appleAuthorizationCode != null) {
      queryParams['appleAuthorizationCode'] = appleAuthorizationCode;
    }
    var jsonRes = await _backendGetJson('register_user/', queryParams);
    if (jsonRes.isOk) {
      final userParams = UserParams.fromJson(jsonRes.unwrap())!;
      Log.i('Backend: user registered: ${userParams.toString()}');
      return Ok(userParams);
    } else {
      if (jsonRes.unwrapErr().errorKind !=
          BackendErrorKind.ALREADY_REGISTERED) {
        return Err(jsonRes.unwrapErr());
      } else {
        // Already registered, need to login
      }
    }

    // Login

    jsonRes = await _backendGetJson(
        'login_user/', {'googleIdToken': googleIdToken, 'deviceId': deviceId});
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final userParams = UserParams.fromJson(jsonRes.unwrap())!;
    Log.i('Backend: user logged in: ${userParams.toString()}');
    return Ok(userParams);
  }

  Future<Result<bool, BackendError>> updateUserParams(UserParams userParams,
      {String? backendClientTokenOverride}) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.updateUserParams(userParams,
          backendClientTokenOverride: backendClientTokenOverride);
    }

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
    if (await _settings.testingBackends()) {
      return await _fakeBackend.requestProduct(barcode);
    }

    final jsonRes =
        await _backendGetJson('product_data/', {'barcode': barcode});
    if (jsonRes.isErr) {
      if (jsonRes.unwrapErr().errorKind == BackendErrorKind.PRODUCT_NOT_FOUND) {
        return Ok(null);
      } else {
        return Err(jsonRes.unwrapErr());
      }
    }
    final json = jsonRes.unwrap();
    return Ok(BackendProduct.fromJson(json));
  }

  Future<Result<None, BackendError>> createUpdateProduct(String barcode,
      {VegStatus? vegetarianStatus, VegStatus? veganStatus}) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.createUpdateProduct(barcode,
          vegetarianStatus: vegetarianStatus, veganStatus: veganStatus);
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
    _analytics
        .sendEvent('report_sent', {'barcode': barcode, 'report': reportText});
    if (await _settings.testingBackends()) {
      return await _fakeBackend.sendReport(barcode, reportText);
    }

    final params = <String, String>{};
    params['barcode'] = barcode;
    params['text'] = reportText;
    final response = await _backendGet('make_report/', params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<None, BackendError>> sendProductScan(String barcode) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.sendProductScan(barcode);
    }

    final params = <String, String>{};
    params['barcode'] = barcode;
    final response = await _backendGet('product_scan/', params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<UserParams, BackendError>> userData() async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.userData();
    }

    final jsonRes = await _backendGetJson('user_data/', {});
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    final backendUserParams = UserParams.fromJson(json)!;
    // NOTE: client token is not present in the response, but
    // the Backend class knows the token and can set it.
    // If it wouldn't set it, the `userData()` method clients would get
    // not fully set params.
    final storedUserParams = await _userParamsController.getUserParams();
    return Ok(backendUserParams.rebuild(
        (e) => e..backendClientToken = storedUserParams?.backendClientToken));
  }

  Future<Result<List<BackendProductsAtShop>, BackendError>>
      requestProductsAtShops(Iterable<String> osmIds) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.requestProductsAtShops(osmIds);
    }

    final jsonRes = await _backendGetJson(
        'products_at_shops_data/', {'osmShopsIds': osmIds});
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    if (!json.containsKey('results')) {
      Log.w('Invalid products_at_shops_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final results = json['results'] as Map<String, dynamic>;
    final productsAtShops = <BackendProductsAtShop>[];
    for (final result in results.values) {
      final productsAtShop =
          BackendProductsAtShop.fromJson(result as Map<String, dynamic>);
      if (productsAtShop != null) {
        productsAtShops.add(productsAtShop);
      }
    }
    return Ok(productsAtShops);
  }

  Future<Result<List<BackendShop>, BackendError>> requestShops(
      Iterable<String> osmIds) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.requestShops(osmIds);
    }

    final jsonRes = await _backendGetJson('shops_data/', {},
        body: jsonEncode({'osm_ids': osmIds.toList()}),
        contentType: 'application/json');
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    if (!json.containsKey('results')) {
      Log.w('Invalid shops_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final results = json['results'] as Map<String, dynamic>;
    final shops = <BackendShop>[];
    for (final result in results.values) {
      final shop = BackendShop.fromJson(result as Map<String, dynamic>);
      if (shop != null) {
        shops.add(shop);
      }
    }
    return Ok(shops);
  }

  Future<Result<None, BackendError>> productPresenceVote(
      String barcode, String osmId, bool positive) async {
    _analytics.sendEvent('product_presence_vote',
        {'barcode': barcode, 'shop': osmId, 'vote': positive});
    if (await _settings.testingBackends()) {
      return await _fakeBackend.productPresenceVote(barcode, osmId, positive);
    }

    final response = await _backendGet('product_presence_vote/', {
      'barcode': barcode,
      'shopOsmId': osmId,
      'voteVal': positive ? '1' : '0',
    });
    return _noneOrErrorFrom(response);
  }

  Future<Result<None, BackendError>> putProductToShop(
      String barcode, String osmId) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.putProductToShop(barcode, osmId);
    }

    final response = await _backendGet('put_product_to_shop/', {
      'barcode': barcode,
      'shopOsmId': osmId,
    });
    return _noneOrErrorFrom(response);
  }

  Future<Result<BackendShop, BackendError>> createShop(
      {required String name,
      required Point<double> coords,
      required String type}) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.createShop(
          name: name, coords: coords, type: type);
    }

    final jsonRes = await _backendGetJson('create_shop/', {
      'lon': coords.x.toString(),
      'lat': coords.y.toString(),
      'name': name,
      'type': type
    });
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();
    if (!json.containsKey('osm_id')) {
      return Err(BackendError.invalidDecodedJson(json));
    }
    return Ok(BackendShop((e) => e
      ..osmId = json['osm_id'] as String
      ..productsCount = 0));
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

  Future<Result<Map<String, dynamic>, BackendError>> _backendGetJson(
      String path, Map<String, dynamic>? params,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      String? contentType}) async {
    final response = await _backendGet(path, params,
        headers: headers,
        backendClientTokenOverride: backendClientTokenOverride,
        body: body,
        contentType: contentType);
    if (response.isError) {
      return Err(_errFromResp(response));
    }

    final json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }
    if (_isError(json)) {
      return Err(_errFromJson(json));
    }
    return Ok(json);
  }

  Future<BackendResponse> _backendGet(String path, Map<String, dynamic>? params,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      String? contentType}) async {
    final userParams = await _userParamsController.getUserParams();
    final backendClientToken =
        backendClientTokenOverride ?? userParams?.backendClientToken;

    final headersReally =
        Map<String, String>.from(headers ?? <String, String>{});
    if (backendClientToken != null) {
      headersReally['Authorization'] = 'Bearer $backendClientToken';
    }
    if (contentType != null) {
      headersReally['Content-Type'] = contentType;
    }
    final url = Uri.https(BACKEND_ADDRESS, '/backend/$path', params);
    try {
      final request = http.Request('GET', url);
      request.headers.addAll(headersReally);

      if (body != null) {
        request.body = body;
      }

      final httpResponse =
          await http.Response.fromStream(await _http.send(request));
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
