import 'package:http/http.dart';
import 'package:plante/base/log.dart';

class BackendResponse {
  final Uri? requestUrl;
  final int? statusCode;
  final String? reasonPhrase;
  final String body;
  final Map<String, String> headers;
  final dynamic? exception;

  bool get isOk => statusCode == 200;
  bool get isError => !isOk;

  BackendResponse.fromHttpResponse(Response response)
      : requestUrl = response.request?.url,
        statusCode = response.statusCode,
        reasonPhrase = response.reasonPhrase,
        body = response.body,
        headers = response.headers,
        exception = null;
  BackendResponse.fromError(this.exception, this.requestUrl)
      : statusCode = null,
        reasonPhrase = null,
        body = '',
        headers = {} {
    Log.w(
        'BackendResponse.fromError, url: ${requestUrl.toString()}, '
        'e: $exception',
        ex: exception);
  }
}
