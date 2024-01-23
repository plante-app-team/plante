import 'package:plante/base/device_info.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

const LOGIN_OR_REGISTER_CMD = 'login_or_register_user';

extension BackendExt on Backend {
  Future<Result<UserParams, BackendError>> loginOrRegister(
          {required DeviceInfo deviceInfo,
          String? googleIdToken,
          String? appleAuthorizationCode}) =>
      executeCmd(_BackendLoginOrRegisterCmd(
          deviceInfo, googleIdToken, appleAuthorizationCode));
}

class _BackendLoginOrRegisterCmd extends BackendCmd<UserParams> {
  final DeviceInfo deviceInfo;
  final String? googleIdToken;
  final String? appleAuthorizationCode;

  _BackendLoginOrRegisterCmd(
      this.deviceInfo, this.googleIdToken, this.appleAuthorizationCode);

  @override
  Future<Result<UserParams, BackendError>> execute() async {
    final existingUserParams = await getUserParams();
    if (existingUserParams != null) {
      return Ok(existingUserParams);
    }

    final deviceId = deviceInfo.deviceID;
    final queryParams = {
      'deviceId': deviceId,
    };
    if (googleIdToken != null) {
      queryParams['googleIdToken'] = googleIdToken!;
    }
    if (appleAuthorizationCode != null) {
      queryParams['appleAuthorizationCode'] = appleAuthorizationCode!;
    }
    final jsonRes =
        await backendGetJson('$LOGIN_OR_REGISTER_CMD/', queryParams);
    if (jsonRes.isOk) {
      final userParams = UserParams.fromJson(jsonRes.unwrap())!;
      Log.i(
          '_BackendLoginOrRegisterCmd: user logged in or registered: ${userParams.toString()}');
      return Ok(userParams);
    } else {
      return Err(jsonRes.unwrapErr());
    }
  }
}
