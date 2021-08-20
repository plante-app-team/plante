import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plante/outside/http_client.dart';

class FakeHttpClient extends HttpClient {
  late final MockClient _impl;
  final _responses = <RegExp, _Response>{};
  final _requests = <http.BaseRequest>[];

  FakeHttpClient() {
    _impl = MockClient((request) async {
      for (final response in _responses.entries) {
        if (response.key.hasMatch(request.url.toString())) {
          if (response.value.httpResponse != null) {
            return response.value.httpResponse!;
          } else {
            throw response.value.exception!;
          }
        }
      }
      return http.Response('', 404);
    });
  }

  void setResponse(String regex, String response, {int responseCode = 200}) {
    _responses[RegExp(regex)] =
        _Response.ok(http.Response(response, responseCode));
  }

  void setResponseException(String regex, Exception exception) {
    _responses[RegExp(regex)] = _Response.err(exception);
  }

  List<http.BaseRequest> getRequestsMatching(String regex) {
    final regexpr = RegExp(regex);
    return _requests
        .where((element) => regexpr.hasMatch(element.url.toString()))
        .toList();
  }

  void reset() {
    _responses.clear();
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
