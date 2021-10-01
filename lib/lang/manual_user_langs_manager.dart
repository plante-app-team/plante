import 'dart:async';

import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager_error.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

/// Please use UserLangsManager instead of this class.
class ManualUserLangsManager implements UserParamsControllerObserver {
  final UserParamsController _userParamsController;
  final Backend _backend;
  final Analytics _analytics;

  List<LangCode>? _userLangs;
  final _initCompleter = Completer<List<LangCode>?>();
  Future<void> get initFuture => _initCompleter.future;

  ManualUserLangsManager(
      this._userParamsController, this._backend, this._analytics) {
    _initAsync();
    _userParamsController.addObserver(this);
  }

  void _initAsync() async {
    try {
      final userParams = await _userParamsController.getUserParams();
      if (userParams != null) {
        _userLangs = _extractLangsFrom(userParams);
      }
    } finally {
      _initCompleter.complete(_userLangs);
    }
  }

  @override
  void onUserParamsUpdate(UserParams? userParams) {
    if (userParams != null) {
      _userLangs = _extractLangsFrom(userParams);
    } else {
      _userLangs = null;
    }
  }

  List<LangCode>? _extractLangsFrom(UserParams userParams) {
    if (userParams.langsPrioritized != null &&
        userParams.langsPrioritized!.isNotEmpty) {
      return _convertFromStrs(userParams.langsPrioritized!);
    }
    return null;
  }

  List<LangCode> _convertFromStrs(Iterable<String> strs) {
    return strs
        .map(LangCode.safeValueOf)
        .where((lang) => lang != null)
        .map((e) => e!)
        .toList();
  }

  Future<List<LangCode>?> getUserLangs() async {
    if (!_initCompleter.isCompleted) {
      return _initCompleter.future;
    }
    return _userLangs;
  }

  Future<Result<UserParams, UserLangsManagerError>> setUserLangs(
      List<LangCode> langs) async {
    if (langs.length == 1) {
      _analytics.sendEvent('single_manual_user_lang');
    } else if (langs.length > 1) {
      _analytics.sendEvent('multiple_manual_user_langs');
    } else {
      _analytics.sendEvent('zero_manual_user_langs');
    }
    var params = await _userParamsController.getUserParams();
    if (params == null) {
      Log.e('ManualUserLangsManager.setUserLangs '
          'cannot work without user params');
      return Err(UserLangsManagerError.OTHER);
    }
    params = params
        .rebuild((e) => e.langsPrioritized.replace(langs.map((e) => e.name)));
    final updateRes = await _backend.updateUserParams(params);
    if (updateRes.isErr) {
      if (updateRes.unwrapErr().errorKind == BackendErrorKind.NETWORK_ERROR) {
        return Err(UserLangsManagerError.NETWORK);
      } else {
        return Err(UserLangsManagerError.OTHER);
      }
    }
    await _userParamsController.setUserParams(params);
    return Ok(params);
  }
}
