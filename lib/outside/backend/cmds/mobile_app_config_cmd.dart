import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/mobile_app_config.dart';

const MOBILE_APP_CONFIG_CMD = 'mobile_app_config';

extension BackendExt on Backend {
  Future<Result<MobileAppConfig, BackendError>> mobileAppConfig() =>
      executeCmd(_MobileAppConfigCmd());
}

class _MobileAppConfigCmd extends BackendCmd<MobileAppConfig> {
  _MobileAppConfigCmd();

  @override
  Future<Result<MobileAppConfig, BackendError>> execute() async {
    final jsonRes = await backendGetJson('$MOBILE_APP_CONFIG_CMD/', {});
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();
    return Ok(MobileAppConfig.fromJson(json)!);
  }
}
