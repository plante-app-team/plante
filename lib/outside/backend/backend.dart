import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_response.dart';
import 'package:plante/outside/http_client.dart';

const BACKEND_ADDRESS = 'planteapp.com';
const _LOCAL_BACKEND_ADDRESS = 'localhost:8080';
const _CONNECT_TO_LOCAL_SERVER = kIsWeb && kDebugMode;

const PREF_BACKEND_CLIENT_TOKEN = 'BACKEND_CLIENT_TOKEN';

class BackendObserver {
  void onBackendError(BackendError error) {}
}

/// Extends this class to support new backend command
abstract class BackendCmd<T> {
  late Backend _backend;

  Future<Result<T, BackendError>> execute();

  Future<Result<T, BackendError>> _execute(Backend backend) {
    _backend = backend;
    return execute();
  }

  @protected
  Future<BackendResponse> backendGet(String path, Map<String, dynamic>? params,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      String? contentType}) async {
    return await _backend._backendReq(path, params, 'GET',
        headers: headers,
        backendClientTokenOverride: backendClientTokenOverride,
        body: body,
        contentType: contentType);
  }

  @protected
  Future<Result<Map<String, dynamic>, BackendError>> backendGetJson(
      String path, Map<String, dynamic>? params,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      String? contentType}) async {
    return await _backend._backendReqJson(path, params, 'GET',
        headers: headers,
        backendClientTokenOverride: backendClientTokenOverride,
        body: body,
        contentType: contentType);
  }

  @protected
  Future<Result<Map<String, dynamic>, BackendError>> backendPostJson(
      String path, Map<String, dynamic>? params,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      Uint8List? bodyBytes,
      String? contentType}) async {
    return await _backend._backendReqJson(path, params, 'POST',
        headers: headers,
        backendClientTokenOverride: backendClientTokenOverride,
        body: body,
        bodyBytes: bodyBytes,
        contentType: contentType);
  }

  @protected
  Result<None, BackendError> noneOrErrorFrom(BackendResponse response) {
    return _backend._noneOrErrorFrom(response);
  }

  @protected
  BackendError errFromResp(BackendResponse response) =>
      _backend._errFromResp(response);

  @protected
  Future<UserParams?> getUserParams() =>
      _backend._userParamsController.getUserParams();
}

/// Please do not add new backend commands functions, use [BackendCmd] instead
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

  Future<Result<T, BackendError>> executeCmd<T>(BackendCmd<T> cmd) async {
    return cmd._execute(this);
  }

  Result<None, BackendError> _noneOrErrorFrom(BackendResponse response) {
    if (response.isError) {
      return Err(_errFromResp(response));
    }
    final json = jsonDecodeSafe(response.body);
    if (json != null && !_isError(json)) {
      return Ok(None());
    } else {
      return Err(_errOther());
    }
  }

  Future<BackendResponse> _backendGet(String path, Map<String, dynamic>? params,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      String? contentType}) async {
    return await _backendReq(path, params, 'GET',
        headers: headers,
        backendClientTokenOverride: backendClientTokenOverride,
        body: body,
        contentType: contentType);
  }

  Future<Result<Map<String, dynamic>, BackendError>> _backendReqJson(
      String path, Map<String, dynamic>? params, String method,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      Uint8List? bodyBytes,
      String? contentType}) async {
    final response = await _backendReq(path, params, method,
        headers: headers,
        backendClientTokenOverride: backendClientTokenOverride,
        body: body,
        bodyBytes: bodyBytes,
        contentType: contentType);
    if (response.isError) {
      return Err(_errFromResp(response));
    }

    final json = jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }
    if (_isError(json)) {
      return Err(_errFromJson(json));
    }
    return Ok(json);
  }

  Future<BackendResponse> _backendReq(
      String path, Map<String, dynamic>? params, String requestType,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      Uint8List? bodyBytes,
      String? contentType}) async {
    final url = createUrl(path, params);
    try {
      final request = http.Request(requestType, url);
      await _fillHeaders(request,
          extraHeaders: headers,
          backendClientTokenOverride: backendClientTokenOverride,
          contentType: contentType);

      if (body != null && bodyBytes != null) {
        throw Exception('body and bodyBytes must not be both set');
      }
      if (body != null) {
        request.body = body;
      }
      if (bodyBytes != null) {
        request.bodyBytes = bodyBytes;
      }

      final httpResponse =
          await http.Response.fromStream(await _http.send(request));
      return BackendResponse.fromHttpResponse(httpResponse);
    } on IOException catch (e) {
      return BackendResponse.fromError(e, url);
    }
  }

  Uri createUrl(String path, Map<String, dynamic>? params) {
    final String backendAddress;
    if (_CONNECT_TO_LOCAL_SERVER) {
      backendAddress = _LOCAL_BACKEND_ADDRESS;
    } else {
      backendAddress = BACKEND_ADDRESS;
    }
    final Uri url;
    if (_CONNECT_TO_LOCAL_SERVER) {
      url = Uri.http(backendAddress, '/$path', params);
    } else {
      url = Uri.https(backendAddress, '/backend/$path', params);
    }
    return url;
  }

  Future<void> _fillHeaders(http.BaseRequest request,
      {required Map<String, String>? extraHeaders,
      required String? backendClientTokenOverride,
      required String? contentType}) async {
    final headersReally =
        Map<String, String>.from(extraHeaders ?? <String, String>{});
    if (contentType != null) {
      headersReally['Content-Type'] = contentType;
    }

    final auth = await authHeaders(
        backendClientTokenOverride: backendClientTokenOverride);
    headersReally.addAll(auth);

    request.headers.addAll(headersReally);
  }

  Future<Map<String, String>> authHeaders(
      {String? backendClientTokenOverride}) async {
    final headers = <String, String>{};
    final userParams = await _userParamsController.getUserParams();
    final backendClientToken =
        backendClientTokenOverride ?? userParams?.backendClientToken;
    if (backendClientToken != null) {
      headers['Authorization'] = 'Bearer $backendClientToken';
    }
    return headers;
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

  Future<BackendResponse> customGet(String path,
      [Map<String, dynamic>? queryParams, Map<String, String>? headers]) async {
    if (!kIsWeb) {
      throw Exception('Backend.customGet must be called only from Web');
    }
    return await _backendGet(path, queryParams, headers: headers);
  }

  Future<R> customRequest<R extends http.BaseRequest>(
      String path, ArgResCallback<Uri, R> createRequest,
      {Map<String, dynamic>? queryParams, Map<String, String>? headers}) async {
    final uri = createUrl(path, queryParams);
    final request = createRequest.call(uri);
    await _fillHeaders(request,
        extraHeaders: null,
        backendClientTokenOverride: null,
        contentType: null);
    Log.i(
        'Backend.customRequest: $uri, params: $queryParams, headers: $headers');
    return request;
  }
}
