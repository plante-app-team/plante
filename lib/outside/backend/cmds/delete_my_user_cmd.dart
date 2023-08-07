import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

extension BackendExt on Backend {
  Future<Result<None, BackendError>> deleteMyUser(
          {String? googleIdToken, String? appleAuthorizationCode}) =>
      executeCmd(_DeleteMyUserCmd(googleIdToken, appleAuthorizationCode));
}

class _DeleteMyUserCmd extends BackendCmd<None> {
  final String? googleIdToken;
  final String? appleAuthorizationCode;
  _DeleteMyUserCmd(this.googleIdToken, this.appleAuthorizationCode);

  @override
  Future<Result<None, BackendError>> execute() async {
    final queryParams = <String, dynamic>{};
    if (googleIdToken != null) {
      queryParams['googleIdToken'] = googleIdToken;
    }
    if (appleAuthorizationCode != null) {
      queryParams['appleAuthorizationCode'] = appleAuthorizationCode;
    }
    final response = await backendGet('delete_my_user/', queryParams);
    return noneOrErrorFrom(response);
  }
}
