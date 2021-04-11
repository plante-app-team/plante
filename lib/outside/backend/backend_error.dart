import 'package:http/http.dart';
import 'package:untitled_vegan_app/base/log.dart';

enum BackendErrorKind {
  ALREADY_REGISTERED,
  NOT_AUTHORIZED,
  INVALID_JSON,
  OTHER
}

class BackendError {
  BackendErrorKind errorKind;
  String? errorStr;
  String? errorDescr;
  BackendError(this.errorKind, {this.errorStr, this.errorDescr});

  static bool isError(Map<String, dynamic> json) {
    return json["error"] != null;
  }

  static BackendError fromJson(Map<String, dynamic> json) {
    assert(isError(json));

    final BackendErrorKind kind;
    switch (json["error"]) {
      case "already_registered":
        kind = BackendErrorKind.ALREADY_REGISTERED;
        break;
      default:
        kind = BackendErrorKind.OTHER;
        break;
    }

    Log.w("BackendError from JSON: $json");
    return BackendError(
        kind,
        errorStr: json["error"],
        errorDescr: json["error_description"]);
  }

  static BackendError fromResp(Response response) {
    Log.w("BackendError from HTTP response. "
          "Code: ${response.statusCode}, "
          "Reason: ${response.reasonPhrase}, "
          "Headers: ${response.headers}, "
          "body: ${response.body}. "
          "Request URL was: ${response.request?.url.toString()}");
    if (response.statusCode == 401) {
      return BackendError(
          BackendErrorKind.NOT_AUTHORIZED,
          errorStr: null,
          errorDescr: response.reasonPhrase);
    } else {
      return BackendError(
          BackendErrorKind.OTHER,
          errorStr: null,
          errorDescr: response.reasonPhrase);
    }
  }

  static BackendError invalidJson(String invalidJson) {
    return BackendError(
        BackendErrorKind.INVALID_JSON,
        errorDescr: invalidJson);
  }
}
