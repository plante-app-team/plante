import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/mobile_app_config.dart';
import 'package:plante/outside/backend/mobile_app_config_manager.dart';

class UserParamsFetcher implements MobileAppConfigManagerObserver {
  final UserParamsController _userParamsController;
  final MobileAppConfigManager _mobileAppConfigManager;

  UserParamsFetcher(this._userParamsController, this._mobileAppConfigManager) {
    _mobileAppConfigManager.addObserver(this);
  }

  @override
  void onMobileAppConfigChange(MobileAppConfig? config) async {
    if (config == null) {
      return;
    }
    final initialParams = await _userParamsController.getUserParams();
    if (initialParams == null) {
      return;
    }
    var backendParams = config.remoteUserParams;
    // NOTE: client token is not present in the remote user params, but
    // the we know the token and can set it.
    // If it wouldn't set it, everything will break - backend client is
    // needed for all requests.
    backendParams = backendParams.rebuild(
        (e) => e..backendClientToken = initialParams.backendClientToken);
    if (initialParams != backendParams) {
      await _userParamsController.setUserParams(backendParams);
    }
  }
}
