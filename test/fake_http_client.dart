import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:untitled_vegan_app/outside/http_client.dart';

class FakeHttpClient extends HttpClient {
  late final MockClient _impl;
  final _responses = Map<RegExp, Response>();
  final _requests = <BaseRequest>[];

  FakeHttpClient() {
    _impl = MockClient((request) async {
      for (final response in _responses.entries) {
        if (response.key.hasMatch(request.url.toString())) {
          return response.value;
        }
      }
      return Response("", 404);
    });
  }

  void setResponse(String regex, String response, {int responseCode = 200}) {
    _responses[RegExp(regex)] = Response(response, responseCode);
  }

  List<BaseRequest> getRequestsMatching(String regex) {
    final regexpr = RegExp(regex);
    return _requests.where(
            (element) => regexpr.hasMatch(element.url.toString()))
        .toList();
  }

  void reset() {
    _responses.clear();
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    _requests.add(request);
    return _impl.send(request);
  }
}
