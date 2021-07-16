import 'package:plante/base/base.dart';

class SysLangCodeHolder {
  final _initCallbacks = <ArgCallback<String>>[];
  String? _langCode;

  SysLangCodeHolder();
  SysLangCodeHolder.inited(String initialLangCode)
      : _langCode = initialLangCode;

  String get langCode => _langCode!;
  set langCode(String value) {
    _langCode = value;
    for (final callback in _initCallbacks) {
      callback.call(value);
    }
    _initCallbacks.clear();
  }

  void callWhenInited(ArgCallback<String> callback) {
    if (_langCode != null) {
      callback.call(_langCode!);
    } else {
      _initCallbacks.add(callback);
    }
  }
}
