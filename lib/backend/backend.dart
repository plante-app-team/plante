import 'dart:convert';

import 'package:either_option/either_option.dart';
import 'package:http/http.dart';
import 'package:untitled_vegan_app/backend/server_error.dart';
import 'package:untitled_vegan_app/base/device_info.dart';
import 'package:untitled_vegan_app/base/http_client.dart';
import 'package:untitled_vegan_app/model/gender.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/model/user_params_controller.dart';

const BACKEND_ADDRESS = '185.52.2.206:8080';

const PREF_BACKEND_CLIENT_TOKEN = 'BACKEND_CLIENT_TOKEN';

class BackendObserver {
  void onServerError(ServerError error) {}
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

  Future<Either<UserParams, ServerError>> loginOrRegister(String googleIdToken) async {
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
      return Right(ServerError(ServerErrorKind.OTHER));
    }

    var json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Right(ServerError.invalidJson(response.body));
    }

    if (!isError(json)) {
      final userParams = UserParams.fromJson(json)!;
      return Left(userParams);
    }
    if (_errFromJson(json).errorKind != ServerErrorKind.ALREADY_REGISTERED) {
      return Right(ServerError(ServerErrorKind.OTHER));
    }

    // Login

    response = await _backendGet(
        "login_user/",
        {"googleIdToken": googleIdToken, "deviceId": deviceId});
    if (response.statusCode != 200) {
      return Right(ServerError(ServerErrorKind.OTHER));
    }

    json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Right(ServerError.invalidJson(response.body));
    }

    if (!isError(json)) {
      return Left(UserParams.fromJson(json)!);
    } else {
      return Right(_errFromJson(json));
    }
  }

  Future<Either<bool, ServerError>> updateUserParams(UserParams userParams) async {
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

  bool isError(Map<String, dynamic> json) {
    return ServerError.isError(json);
  }
  
  ServerError _errFromResp(Response response) {
    final error = ServerError.fromResp(response);
    _observers.forEach((obs) { obs.onServerError(error); });
    return error;
  }

  ServerError _errFromJson(Map<String, dynamic> json) {
    final error = ServerError.fromJson(json);
    _observers.forEach((obs) { obs.onServerError(error); });
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
