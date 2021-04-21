import 'dart:io';

import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/outside/backend/backend_response.dart';

enum BackendErrorKind {
  ALREADY_REGISTERED,
  GOOGLE_EMAIL_NOT_VERIFIED,
  NOT_AUTHORIZED,
  PRODUCT_NOT_FOUND,
  INVALID_JSON,
  NETWORK_ERROR,
  OTHER
}

class BackendError {
  BackendErrorKind errorKind;
  String? errorStr;
  String? errorDescr;
  BackendError._(this.errorKind, {this.errorStr, this.errorDescr});

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
      case "google_email_not_verified":
        kind = BackendErrorKind.GOOGLE_EMAIL_NOT_VERIFIED;
        break;
      case "product_not_found":
        kind = BackendErrorKind.PRODUCT_NOT_FOUND;
        break;
      default:
        kind = BackendErrorKind.OTHER;
        break;
    }

    Log.w("BackendError from JSON: $json");
    return BackendError._(
        kind,
        errorStr: json["error"],
        errorDescr: json["error_description"]);
  }

  static BackendError fromResp(BackendResponse response) {
    assert(response.statusCode != 200);
    Log.w("BackendError from HTTP response. "
          "Code: ${response.statusCode}, "
          "Reason: ${response.reasonPhrase}, "
          "Headers: ${response.headers}, "
          "body: ${response.body}. "
          "Request URL was: ${response.requestUrl?.toString()}");
    if (response.statusCode == 401) {
      return BackendError._(
          BackendErrorKind.NOT_AUTHORIZED,
          errorStr: null,
          errorDescr: response.reasonPhrase);
    } else if (response.exception != null) {
      return BackendError._(
          exceptionToErrorKind(response.exception),
          errorStr: response.exception.toString(),
          errorDescr: null);
    } else {
      return BackendError._(
          BackendErrorKind.OTHER,
          errorStr: null,
          errorDescr: response.reasonPhrase);
    }
  }

  static BackendError invalidJson(String invalidJson) {
    Log.w("BackendError from invalid JSON: $invalidJson");
    return BackendError._(
        BackendErrorKind.INVALID_JSON,
        errorDescr: invalidJson);
  }

  static BackendError other() {
    Log.w("BackendError other");
    return BackendError._(BackendErrorKind.OTHER);
  }
}

BackendErrorKind exceptionToErrorKind(dynamic exception) {
  if (exception is IOException) {
    return BackendErrorKind.NETWORK_ERROR;
  } else {
    return BackendErrorKind.OTHER;
  }
}

extension BackendErrorKindTestingExtention on BackendErrorKind {
  BackendError toErrorForTesting() {
    if (!isInTests()) {
      throw Error();
    }
    return BackendError._(this);
  }
}
