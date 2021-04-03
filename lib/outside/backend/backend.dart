import 'dart:convert';

import 'package:either_option/either_option.dart';
import 'package:http/http.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/outside/backend/backend_error.dart';
import 'package:untitled_vegan_app/base/device_info.dart';
import 'package:untitled_vegan_app/outside/backend/backend_product.dart';
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

  Future<Either<UserParams, BackendError>> loginOrRegister(String googleIdToken) async {
    if (await isLoggedIn()) {
      final userParams = await _userParamsController.getUserParams();
      return Left(userParams!);
    }

    // Register

    final deviceId = (await DeviceInfo.get()).deviceID;
    var response = await _backendGet(
        "register_user/",
        {"googleIdToken": googleIdToken, "deviceId": deviceId});
    if (response.statusCode != 200) {
      return Right(BackendError(BackendErrorKind.OTHER));
    }

    var json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Right(BackendError.invalidJson(response.body));
    }

    if (!_isError(json)) {
      final userParams = UserParams.fromJson(json)!;
      return Left(userParams);
    }
    if (_errFromJson(json).errorKind != BackendErrorKind.ALREADY_REGISTERED) {
      return Right(BackendError(BackendErrorKind.OTHER));
    }

    // Login

    response = await _backendGet(
        "login_user/",
        {"googleIdToken": googleIdToken, "deviceId": deviceId});
    if (response.statusCode != 200) {
      return Right(BackendError(BackendErrorKind.OTHER));
    }

    json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Right(BackendError.invalidJson(response.body));
    }

    if (!_isError(json)) {
      return Left(UserParams.fromJson(json)!);
    } else {
      return Right(_errFromJson(json));
    }
  }

  Future<Either<bool, BackendError>> updateUserParams(UserParams userParams) async {
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
      return Left(false);
    }

    var response = await _backendGet("update_user_data/", params);
    if (response.statusCode == 200) {
      return Left(true);
    } else {
      return Right(_errFromResp(response));
    }
  }

  Future<BackendProduct?> requestProduct(String barcode) async {
    var response = await _backendGet("product_data/", { "barcode": barcode });
    if (response.statusCode != 200) {
      return null;
    }
    final json = _jsonDecodeSafe(response.body);
    if (json != null && !_isError(json)) {
      return BackendProduct.fromJson(json)!;
    } else {
      return null;
    }
  }

  Future<Either<None, BackendError>> createUpdateProduct(
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
    if (response.statusCode != 200) {
      return Right(_errFromResp(response));
    }
    final json = _jsonDecodeSafe(response.body);
    if (json != null && !_isError(json)) {
      return Left(None());
    } else {
      return Right(_errFromResp(response));
    }
  }

  Future<Response> _backendGet(
      String path,
      Map<String, String>? params,
      {Map<String, String>? headers}) async {
    final userParams = await _userParamsController.getUserParams();

    final headersReally = Map<String, String>.from(headers ?? Map<String, String>());
    if (userParams != null && userParams.backendClientToken != null) {
      headersReally["Authorization"] = "Bearer ${userParams.backendClientToken!}";
    }
    return _http.get(Uri.http(
        "$BACKEND_ADDRESS", path, params), headers: headersReally);
  }

  bool _isError(Map<String, dynamic> json) {
    return BackendError.isError(json);
  }
  
  BackendError _errFromResp(Response response) {
    final error = BackendError.fromResp(response);
    _observers.forEach((obs) { obs.onBackendError(error); });
    return error;
  }

  BackendError _errFromJson(Map<String, dynamic> json) {
    final error = BackendError.fromJson(json);
    _observers.forEach((obs) { obs.onBackendError(error); });
    return error;
  }
}

Map<String, dynamic>? _jsonDecodeSafe(String str) {
  try {
    return jsonDecode(str);
  } on FormatException {
    // TODO(https://trello.com/c/XWAE5UVB/): log warning
    return null;
  }
}
