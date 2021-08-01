import 'dart:async';
import 'dart:convert';

import 'package:plante/model/lang_code.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shared_preferences_holder.dart';

class LocationBasedUserLangsStorage {
  static const PREF_LOCATION_BASED_USER_LANGS = 'LOCATION_BASED_USER_LANGS';

  final SharedPreferencesHolder _prefsHolder;

  List<LangCode>? _userLangs;
  final _loadCompleter = Completer<List<LangCode>?>();

  LocationBasedUserLangsStorage(this._prefsHolder) {
    _initAsync();
  }

  void _initAsync() async {
    final prefs = await _prefsHolder.get();
    final valStr = prefs.getString(PREF_LOCATION_BASED_USER_LANGS);
    if (valStr == null) {
      _loadCompleter.complete(null);
      return;
    }

    try {
      _userLangs = _convertFromStrs(
          (jsonDecode(valStr) as List).map((e) => e as String));
    } on FormatException catch (e) {
      Log.w('AutoUserLangsStorage._initAsync exception', ex: e);
    } finally {
      _loadCompleter.complete(_userLangs);
    }
  }

  List<LangCode> _convertFromStrs(Iterable<String> strs) {
    return strs
        .map(LangCode.safeValueOf)
        .where((lang) => lang != null)
        .map((e) => e!)
        .toList();
  }

  Future<List<LangCode>?> userLangs() async {
    if (!_loadCompleter.isCompleted) {
      return _loadCompleter.future;
    }
    return _userLangs;
  }

  Future<void> setUserLangs(List<LangCode>? value) async {
    _userLangs = value;
    final prefs = await _prefsHolder.get();
    if (value == null) {
      await prefs.remove(PREF_LOCATION_BASED_USER_LANGS);
    } else {
      await prefs.setString(PREF_LOCATION_BASED_USER_LANGS,
          jsonEncode(value.map((e) => e.name).toList()));
    }
  }
}
