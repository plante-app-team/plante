import 'package:http/http.dart';

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

    // TODO(https://trello.com/c/XWAE5UVB/): log warning with error
    return BackendError(
        kind,
        errorStr: json["error"],
        errorDescr: json["error_description"]);
  }

  static BackendError fromResp(Response response) {
    // TODO(https://trello.com/c/XWAE5UVB/): log warning with error
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
