import 'package:http/http.dart';
import 'package:plante/logging/log.dart';

class HttpClient extends BaseClient {
  final Client _realClient;

  HttpClient() : _realClient = Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    _logRequest(request);
    return _realClient.send(request);
  }

  @override
  void close() => _realClient.close();

  void _logRequest(BaseRequest request) {
    Log.i('HttpClient request: ${request.url.toString()}');
  }
}
