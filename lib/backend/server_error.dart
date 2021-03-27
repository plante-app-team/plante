import 'package:http/http.dart';

enum ServerErrorKind {
  ALREADY_REGISTERED,
  NOT_AUTHORIZED,
  INVALID_JSON,
  OTHER
}

class ServerError {
  ServerErrorKind errorKind;
  String? errorStr;
  String? errorDescr;
  ServerError(this.errorKind, {this.errorStr, this.errorDescr});

  static bool isError(Map<String, dynamic> json) {
    return json["error"] != null;
  }

  static ServerError fromJson(Map<String, dynamic> json) {
    assert(isError(json));

    final ServerErrorKind kind;
    switch (json["error"]) {
      case "already_registered":
        kind = ServerErrorKind.ALREADY_REGISTERED;
        break;
      default:
        kind = ServerErrorKind.OTHER;
        break;
    }

    // TODO(https://trello.com/c/XWAE5UVB/): log warning with error
    return ServerError(
        kind,
        errorStr: json["error"],
        errorDescr: json["error_description"]);
  }

  static ServerError fromResp(Response response) {
    // TODO(https://trello.com/c/XWAE5UVB/): log warning with error
    assert(response.statusCode != 200);
    if (response.statusCode == 401) {
      return ServerError(
          ServerErrorKind.NOT_AUTHORIZED,
          errorStr: null,
          errorDescr: response.reasonPhrase);
    } else {
      return ServerError(
          ServerErrorKind.OTHER,
          errorStr: null,
          errorDescr: response.reasonPhrase);
    }
  }

  static ServerError invalidJson(String invalidJson) {
    return ServerError(
        ServerErrorKind.INVALID_JSON,
        errorDescr: invalidJson);
  }
}
