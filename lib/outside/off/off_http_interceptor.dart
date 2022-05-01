import 'package:http/http.dart' as http;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/outside/backend/backend.dart';

class OffHttpInterceptor implements off.HttpInterceptor {
  final Backend _backend;

  OffHttpInterceptor(this._backend);

  @override
  Future<http.Response>? fullyInterceptGet(Uri uri) {
    // GET requests are not intercepted - Open Food Facts
    // doesn't require them to be authed.
    return null;
  }

  @override
  Future<http.Request>? interceptGet(Uri uri) {
    // GET requests are not intercepted - Open Food Facts
    // doesn't require them to be authed.
    return null;
  }

  @override
  Future<http.Request>? interceptPost(Uri uri) async {
    return await _backend.customRequest(
        'off_proxy_form_post${uri.pathWithoutSlash}',
        (uri) => http.Request('POST', uri),
        queryParams: uri.queryParametersAll,
        headers: null);
  }

  @override
  Future<http.MultipartRequest>? interceptMultipart(
      String method, Uri uri) async {
    return await _backend.customRequest(
        'off_proxy_multipart${uri.pathWithoutSlash}',
        (uri) => http.MultipartRequest(method, uri),
        queryParams: uri.queryParametersAll,
        headers: null);
  }
}

extension on Uri {
  String get pathWithoutSlash {
    if (!path.endsWith('/')) {
      return path;
    }
    return path.substring(0, path.length - 1);
  }
}
