import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

class UserParamsAutoWiper implements BackendObserver {
  final Backend _backend;
  final UserParamsController _userParamsController;

  UserParamsAutoWiper(this._backend, this._userParamsController) {
    _backend.addObserver(this);
  }

  @override
  void onBackendError(BackendError error) {
    if (error.errorKind == BackendErrorKind.NOT_AUTHORIZED) {
      _userParamsController.setUserParams(null);
    }
  }
}
