import 'package:untitled_vegan_app/backend/backend.dart';
import 'package:untitled_vegan_app/backend/server_error.dart';
import 'package:untitled_vegan_app/model/user_params_controller.dart';

class UserParamsAutoWiper implements BackendObserver {
  final Backend _backend;
  final UserParamsController _userParamsController;

  UserParamsAutoWiper(this._backend, this._userParamsController) {
    _backend.addObserver(this);
  }

  @override
  void onServerError(ServerError error) {
    if (error.errorKind == ServerErrorKind.NOT_AUTHORIZED) {
      _userParamsController.setUserParams(null);
    }
  }
}
