import 'package:http/http.dart';

class HttpClient extends BaseClient {
  final Client _realClient;

  HttpClient(): _realClient = Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    _logRequest(request);
    return _realClient.send(request);
  }

  void close() => _realClient.close();

  void _logRequest(BaseRequest request) {
    // TODO(https://trello.com/c/XWAE5UVB/): log info
  }
}
