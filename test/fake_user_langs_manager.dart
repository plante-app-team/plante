import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/lang/user_langs_manager_error.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';

class FakeUserLangsManager implements UserLangsManager {
  UserLangs _userLangs;
  final _observers = <UserLangsManagerObserver>[];

  FakeUserLangsManager(List<LangCode> langs)
      : _userLangs = UserLangs((e) => e
          ..langs.addAll(langs)
          ..sysLang = langs.first
          ..auto = false);

  @override
  void addObserver(UserLangsManagerObserver observer) {
    _observers.add(observer);
  }

  @override
  void removeObserver(UserLangsManagerObserver observer) {
    _observers.remove(observer);
  }

  @override
  Future<UserLangs> getUserLangs() async => _userLangs;

  @override
  Future<void> get initFuture => Future.value();

  @override
  Future<Result<None, UserLangsManagerError>> setManualUserLangs(
      List<LangCode> userLangs) async {
    _userLangs = UserLangs((e) => e
      ..langs.addAll(userLangs)
      ..sysLang = userLangs.first
      ..auto = false);
    _observers.forEach((o) {
      o.onUserLangsChange(_userLangs);
    });
    return Ok(None());
  }
}
