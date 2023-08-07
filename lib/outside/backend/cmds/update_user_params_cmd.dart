import 'package:plante/base/result.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

const UPDATE_USER_PARAMS_CMD = 'update_user_data';

extension BackendExt on Backend {
  Future<Result<bool, BackendError>> updateUserParams(UserParams userParams,
          {String? backendClientTokenOverride}) =>
      executeCmd(
          _BackendUpdateUserParamsCmd(userParams, backendClientTokenOverride));
}

class _BackendUpdateUserParamsCmd extends BackendCmd<bool> {
  final UserParams userParams;
  final String? backendClientTokenOverride;

  _BackendUpdateUserParamsCmd(this.userParams, this.backendClientTokenOverride);

  @override
  Future<Result<bool, BackendError>> execute() async {
    final params = <String, dynamic>{};
    if (userParams.name != null && userParams.name!.isNotEmpty) {
      params['name'] = userParams.name;
    }
    if (userParams.selfDescription != null &&
        userParams.selfDescription!.isNotEmpty) {
      params['selfDescription'] = userParams.selfDescription;
    }
    if (userParams.langsPrioritized != null &&
        userParams.langsPrioritized!.isNotEmpty) {
      params['langsPrioritized'] = userParams.langsPrioritized;
    }
    if (params.isEmpty) {
      return Ok(false);
    }

    final response = await backendGet('$UPDATE_USER_PARAMS_CMD/', params,
        backendClientTokenOverride: backendClientTokenOverride);
    if (response.isOk) {
      return Ok(true);
    } else {
      return Err(errFromResp(response));
    }
  }
}
