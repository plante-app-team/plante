import 'dart:async';
import 'dart:convert';

import 'package:plante/model/user_langs.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shared_preferences_holder.dart';

class UserLangsStorage {
  static const PREF_USER_LANGS = 'USER_LANGS';

  final SharedPreferencesHolder _prefsHolder;

  UserLangs? _userLangs;
  final _loadCompleter = Completer<UserLangs?>();

  UserLangsStorage(this._prefsHolder) {
    _initAsync();
  }

  void _initAsync() async {
    final prefs = await _prefsHolder.get();
    final valStr = prefs.getString(PREF_USER_LANGS);
    if (valStr == null) {
      _loadCompleter.complete(null);
      return;
    }

    try {
      _userLangs =
          UserLangs.fromJson(jsonDecode(valStr) as Map<String, dynamic>);
    } on FormatException catch (e) {
      Log.w('UserLangsStorage._initAsync exception', ex: e);
    } finally {
      _loadCompleter.complete(_userLangs);
    }
  }

  Future<UserLangs?> userLangs() async {
    if (!_loadCompleter.isCompleted) {
      return _loadCompleter.future;
    }
    return _userLangs;
  }

  Future<void> setUserLangs(UserLangs? value) async {
    _userLangs = value;
    final prefs = await _prefsHolder.get();
    if (value == null) {
      await prefs.remove(PREF_USER_LANGS);
    } else {
      await prefs.setString(PREF_USER_LANGS, jsonEncode(value.toJson()));
    }
  }
}
