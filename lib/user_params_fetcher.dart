import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';

class UserParamsFetcher {
  final Backend _backend;
  final UserParamsController _userParamsController;

  UserParamsFetcher(this._backend, this._userParamsController) {
    _fetch();
  }

  void _fetch() async {
    final initialParams = await _userParamsController.getUserParams();
    if (initialParams == null) {
      return;
    }
    final backendParams = await _backend.userData();
    if (backendParams.isErr) {
      return;
    }
    if (initialParams != backendParams.unwrap()) {
      await _userParamsController.setUserParams(backendParams.unwrap());
    }
  }
}
