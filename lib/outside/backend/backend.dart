import 'dart:convert';
import 'dart:io';

import 'package:untitled_vegan_app/base/log.dart';
import 'package:untitled_vegan_app/base/result.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/outside/backend/backend_error.dart';
import 'package:untitled_vegan_app/base/device_info.dart';
import 'package:untitled_vegan_app/outside/backend/backend_product.dart';
import 'package:untitled_vegan_app/outside/backend/backend_response.dart';
import 'package:untitled_vegan_app/outside/http_client.dart';
import 'package:untitled_vegan_app/model/gender.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/model/user_params_controller.dart';

const BACKEND_ADDRESS = '185.52.2.206:8080';

const PREF_BACKEND_CLIENT_TOKEN = 'BACKEND_CLIENT_TOKEN';

class BackendObserver {
  void onBackendError(BackendError error) {}
}

class Backend {
  final UserParamsController _userParamsController;
  final HttpClient _http;
  
  final _observers = <BackendObserver>[];

  Backend(this._userParamsController, this._http);

  void addObserver(BackendObserver observer) => _observers.add(observer);
  void removeObserver(BackendObserver observer) => _observers.remove(observer);

  Future<bool> isLoggedIn() async {
    final userParams = await _userParamsController.getUserParams();
    return userParams?.backendClientToken != null;
  }

  Future<Result<UserParams, BackendError>> loginOrRegister(String googleIdToken) async {
    if (await isLoggedIn()) {
      final userParams = await _userParamsController.getUserParams();
      return Ok(userParams!);
    }

    // Register

    final deviceId = (await DeviceInfo.get()).deviceID;
    var response = await _backendGet(
        "register_user/",
        {"googleIdToken": googleIdToken, "deviceId": deviceId});
    if (response.isError) {
      return Err(_errFromResp(response));
    }

    var json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }

    if (!_isError(json)) {
      final userParams = UserParams.fromJson(json)!;
      Log.i("Backend: user registered: ${userParams.toString()}");
      return Ok(userParams);
    }
    if (_errFromJson(json).errorKind != BackendErrorKind.ALREADY_REGISTERED) {
      return Err(_errFromJson(json));
    }

    // Login

    response = await _backendGet(
        "login_user/",
        {"googleIdToken": googleIdToken, "deviceId": deviceId});
    if (response.isError) {
      return Err(_errFromResp(response));
    }

    json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }

    if (!_isError(json)) {
      final userParams = UserParams.fromJson(json)!;
      Log.i("Backend: user logged in: ${userParams.toString()}");
      return Ok(userParams);
    } else {
      return Err(_errFromJson(json));
    }
  }

  Future<Result<bool, BackendError>> updateUserParams(
      UserParams userParams,
      {String? backendClientTokenOverride}) async {
    final params = Map<String, String>();
    if (userParams.name != null && userParams.name!.isNotEmpty) {
      params["name"] = userParams.name!;
    }
    if (userParams.gender != null) {
      params["gender"] = userParams.gender!.name;
    }
    if (userParams.birthday != null) {
      params["birthday"] = userParams.birthdayStr!;
    }
    if (userParams.eatsMilk != null) {
      params["eatsMilk"] = userParams.eatsMilk!.toString();
    }
    if (userParams.eatsEggs != null) {
      params["eatsEggs"] = userParams.eatsEggs!.toString();
    }
    if (userParams.eatsHoney != null) {
      params["eatsHoney"] = userParams.eatsHoney!.toString();
    }
    if (params.isEmpty) {
      return Ok(false);
    }

    var response = await _backendGet(
        "update_user_data/",
        params,
        backendClientTokenOverride: backendClientTokenOverride);
    if (response.isOk) {
      return Ok(true);
    } else {
      return Err(_errFromResp(response));
    }
  }

  Future<Result<BackendProduct?, BackendError>> requestProduct(String barcode) async {
    var response = await _backendGet("product_data/", { "barcode": barcode });
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
    return Ok(BackendProduct.fromJson(json)!);
  }

  Future<Result<None, BackendError>> createUpdateProduct(
      String barcode, {VegStatus? vegetarianStatus, VegStatus? veganStatus}) async {
    final params = Map<String, String>();
    params['barcode'] = barcode;
    if (vegetarianStatus != null) {
      params["vegetarianStatus"] = vegetarianStatus.name;
    }
    if (veganStatus != null) {
      params["veganStatus"] = veganStatus.name;
    }
    var response = await _backendGet("create_update_product/", params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<None, BackendError>> sendReport(
      String barcode, String reportText) async {
    final params = Map<String, String>();
    params['barcode'] = barcode;
    params['text'] = reportText;
    var response = await _backendGet("make_report/", params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<None, BackendError>> sendProductScan(String barcode) async {
    final params = Map<String, String>();
    params['barcode'] = barcode;
    var response = await _backendGet("product_scan/", params);
    return _noneOrErrorFrom(response);
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

  Future<BackendResponse> _backendGet(
      String path,
      Map<String, String>? params,
      {Map<String, String>? headers,
       String? backendClientTokenOverride}) async {
    final userParams = await _userParamsController.getUserParams();
    final backendClientToken = backendClientTokenOverride ?? userParams?.backendClientToken;

    final headersReally = Map<String, String>.from(headers ?? Map<String, String>());
    if (backendClientToken != null) {
      headersReally["Authorization"] = "Bearer $backendClientToken";
    }
    final url = Uri.http("$BACKEND_ADDRESS", path, params);
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
    _observers.forEach((obs) { obs.onBackendError(error); });
    return error;
  }

  BackendError _errFromJson(Map<String, dynamic> json) {
    final error = BackendError.fromJson(json);
    _observers.forEach((obs) { obs.onBackendError(error); });
    return error;
  }

  BackendError _errInvalidJson(String invalidJson) {
    final error = BackendError.invalidJson(invalidJson);
    _observers.forEach((obs) { obs.onBackendError(error); });
    return error;
  }

  BackendError _errOther() {
    final error = BackendError.other();
    _observers.forEach((obs) { obs.onBackendError(error); });
    return error;
  }
}

Map<String, dynamic>? _jsonDecodeSafe(String str) {
  try {
    return jsonDecode(str);
  } on FormatException catch(e) {
    Log.w("Backend: couldn't decode safe: %str", ex: e);
    return null;
  }
}
