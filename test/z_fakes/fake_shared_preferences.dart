import 'package:plante/model/shared_preferences_holder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSharedPreferences implements SharedPreferences {
  var _getCallsCount = 0;
  final _map = <String, dynamic>{};

  int get getCallsCount => _getCallsCount;

  SharedPreferencesHolder asHolder() => _Holder(this);

  @override
  Future<bool> commit() async => true;

  @override
  Future<void> reload() async {}

  @override
  bool containsKey(String key) => _map.containsKey(key);

  @override
  Set<String> getKeys() => _map.keys.toSet();

  @override
  Object? get(String key) {
    _getCallsCount += 1;
    return _map[key];
  }

  @override
  bool? getBool(String key) {
    _getCallsCount += 1;
    return _map[key] as bool?;
  }

  @override
  double? getDouble(String key) {
    _getCallsCount += 1;
    return _map[key] as double?;
  }

  @override
  int? getInt(String key) {
    _getCallsCount += 1;
    return _map[key] as int?;
  }

  @override
  String? getString(String key) {
    _getCallsCount += 1;
    return _map[key] as String?;
  }

  @override
  List<String>? getStringList(String key) {
    _getCallsCount += 1;
    return _map[key] as List<String>?;
  }

  @override
  Future<bool> remove(String key) async => _map.remove(key) != null;

  @override
  Future<bool> setBool(String key, bool value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> clear() async {
    _map.clear();
    return true;
  }
}

class _Holder implements SharedPreferencesHolder {
  final SharedPreferences _prefs;

  _Holder(this._prefs);

  @override
  Future<SharedPreferences> get() async => _prefs;
}
