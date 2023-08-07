import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/http_client.dart';

class FakeHttpClient extends HttpClient {
  late final MockClient _impl;
  final _responses =
      <RegExp, ArgResCallback<http.BaseRequest, Future<_Response>>>{};
  final _requests = <http.BaseRequest>[];

  FakeHttpClient() {
    _impl = MockClient((request) async {
      for (final responsePair in _responses.entries) {
        if (responsePair.key.hasMatch(request.url.toString())) {
          final response = await responsePair.value.call(request);
          if (response.httpResponse != null) {
            return response.httpResponse!;
          } else {
            throw response.exception!;
          }
        }
      }
      return http.Response('', 404);
    });
  }

  void setResponse(String regex, String response, {int responseCode = 200}) {
    _responses[RegExp(regex)] =
        (_) async => _Response.ok(http.Response(response, responseCode));
  }

  void setResponseFunction(
      String regex, ArgResCallback<http.BaseRequest, Result<String, int>> fn) {
    setResponseAsyncFunction(regex, (req) async => fn.call(req));
  }

  void setResponseAsyncFunction(String regex,
      ArgResCallback<http.BaseRequest, Future<Result<String, int>>> fn) {
    _responses[RegExp(regex)] = (request) async {
      final resp = await fn.call(request);
      if (resp.isOk) {
        return _Response.ok(http.Response(resp.unwrap(), 200));
      } else {
        return _Response.ok(http.Response('', resp.unwrapErr()));
      }
    };
  }

  void setResponseException(String regex, Exception exception) {
    _responses[RegExp(regex)] = (_) async => _Response.err(exception);
  }

  List<http.BaseRequest> getRequestsMatching(String regex) {
    final regexpr = RegExp(regex);
    return _requests
        .where((element) => regexpr.hasMatch(element.url.toString()))
        .toList();
  }

  void reset() {
    _responses.clear();
    _requests.clear();
  }

  void resetRequests() {
    _requests.clear();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _requests.add(request);
    return _impl.send(request);
  }
}

class _Response {
  final http.Response? httpResponse;
  final Exception? exception;
  _Response.ok(this.httpResponse) : exception = null;
  _Response.err(this.exception) : httpResponse = null;
}
