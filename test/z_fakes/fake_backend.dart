import 'package:http/http.dart' as http;
import 'package:http/src/base_request.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_response.dart';

import 'fake_http_client.dart';
import 'fake_user_params_controller.dart';

class FakeBackend implements Backend {
  final _httpClient = FakeHttpClient();
  late Backend _impl;

  FakeBackend([FakeUserParamsController? userParamsController]) {
    if (userParamsController == null) {
      userParamsController = FakeUserParamsController();
      userParamsController.setUserParams_testing(UserParams((v) => v
        ..backendId = '123'
        ..backendClientToken = '321'
        ..name = 'Bob'));
    }
    _impl = Backend(userParamsController, _httpClient);
  }

  // ignore: non_constant_identifier_names
  void setResponse_testing(String regex, String response,
          {int responseCode = 200}) =>
      _httpClient.setResponse(regex, response, responseCode: responseCode);

  // ignore: non_constant_identifier_names
  void setResponseFunction_testing(String regex,
          ArgResCallback<http.BaseRequest, Result<String, int>> fn) =>
      _httpClient.setResponseFunction(regex, fn);

  // ignore: non_constant_identifier_names
  void setResponseAsyncFunction_testing(String regex,
          ArgResCallback<http.BaseRequest, Future<Result<String, int>>> fn) =>
      _httpClient.setResponseAsyncFunction(regex, fn);

  // ignore: non_constant_identifier_names
  void setResponseException_testing(String regex, Exception exception) =>
      _httpClient.setResponseException(regex, exception);

  // ignore: non_constant_identifier_names
  List<http.BaseRequest> getRequestsMatching_testing(String regex) =>
      _httpClient.getRequestsMatching(regex);

  // ignore: non_constant_identifier_names
  List<http.BaseRequest> getAllRequests_testing() =>
      _httpClient.getRequestsMatching('.*');

  // ignore: non_constant_identifier_names
  void reset_testing() => _httpClient.reset();

  // ignore: non_constant_identifier_names
  void resetRequests_testing() => _httpClient.resetRequests();

  @override
  Future<Result<T, BackendError>> executeCmd<T>(BackendCmd<T> cmd) =>
      _impl.executeCmd(cmd);

  @override
  void addObserver(BackendObserver observer) => _impl.addObserver(observer);

  @override
  void removeObserver(BackendObserver observer) =>
      _impl.removeObserver(observer);

  @override
  Future<Map<String, String>> authHeaders(
          {String? backendClientTokenOverride}) =>
      _impl.authHeaders(backendClientTokenOverride: backendClientTokenOverride);

  @override
  Uri createUrl(String path, Map<String, dynamic>? params) =>
      _impl.createUrl(path, params);

  @override
  Future<BackendResponse> customGet(String path,
          [Map<String, dynamic>? queryParams, Map<String, String>? headers]) =>
      _impl.customGet(path, queryParams, headers);

  @override
  Future<R> customRequest<R extends BaseRequest>(
          String path, ArgResCallback<Uri, R> createRequest,
          {Map<String, dynamic>? queryParams, Map<String, String>? headers}) =>
      _impl.customRequest(path, createRequest,
          queryParams: queryParams, headers: headers);

  @override
  Future<bool> isLoggedIn() => _impl.isLoggedIn();
}
