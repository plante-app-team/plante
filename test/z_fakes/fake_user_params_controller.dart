import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';

class FakeUserParamsController implements UserParamsController {
  final _observers = <UserParamsControllerObserver>[];
  UserParams? _userParams;

  // ignore: non_constant_identifier_names
  void setUserParams_testing(UserParams? userParams) {
    _userParams = userParams;
    _observers.forEach((l) {
      l.onUserParamsUpdate(userParams);
    });
  }

  @override
  void addObserver(UserParamsControllerObserver observer) =>
      _observers.add(observer);

  @override
  void removeObserver(UserParamsControllerObserver observer) =>
      _observers.remove(observer);

  @override
  Future<UserParams?> getUserParams() async {
    return _userParams;
  }

  @override
  Future<void> setUserParams(UserParams? userParams) async {
    setUserParams_testing(userParams);
  }

  @override
  UserParams? get cachedUserParams => _userParams;
}
