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
    final backendParamsRes = await _backend.userData();
    if (backendParamsRes.isErr) {
      return;
    }
    // Vegan-only https://trello.com/c/eUGrj1eH/
    final backendParams = backendParamsRes.unwrap().rebuild((e) => e
      ..eatsEggs = false
      ..eatsMilk = false
      ..eatsHoney = false);
    if (initialParams != backendParams) {
      await _userParamsController.setUserParams(backendParams);
    }
  }
}
