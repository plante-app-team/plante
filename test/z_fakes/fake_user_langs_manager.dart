import 'package:built_collection/built_collection.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/lang/user_langs_manager_error.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params.dart';

import 'fake_user_params_controller.dart';

class FakeUserLangsManager implements UserLangsManager {
  final FakeUserParamsController? fakeUserParamsController;

  UserLangs _userLangs;
  UserLangsManagerError? savingLangsError;

  final _observers = <UserLangsManagerObserver>[];

  FakeUserLangsManager(List<LangCode> langs,
      {this.fakeUserParamsController, bool auto = false})
      : _userLangs = UserLangs((e) => e
          ..langs.addAll(langs)
          ..sysLang = langs.first
          ..auto = auto);

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
  Future<Result<UserParams, UserLangsManagerError>> setManualUserLangs(
      List<LangCode> userLangs) async {
    if (savingLangsError != null) {
      return Err(savingLangsError!);
    }
    _userLangs = UserLangs((e) => e
      ..langs.addAll(userLangs)
      ..sysLang = userLangs.first
      ..auto = false);
    UserParams params;
    if (fakeUserParamsController != null) {
      params = (await fakeUserParamsController!.getUserParams())!;
      params = params.rebuild(
          (e) => e.langsPrioritized.addAllUnique(userLangs.map((e) => e.name)));
      await fakeUserParamsController!.setUserParams(params);
    } else {
      params = UserParams((e) => e
        ..name = 'Bob'
        ..langsPrioritized.addAllUnique(userLangs.map((e) => e.name)));
    }
    _observers.forEach((o) {
      o.onUserLangsChange(_userLangs);
    });
    return Ok(params);
  }
}

extension<T> on ListBuilder<T> {
  void addAllUnique(Iterable<T> iterable) {
    for (final item in iterable) {
      if (!build().contains(item)) {
        add(item);
      }
    }
  }
}
