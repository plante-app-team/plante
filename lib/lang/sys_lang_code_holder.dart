import 'dart:async';

import 'package:plante/base/base.dart';

class SysLangCodeHolder {
  final _initCallbacks = <ArgCallback<String>>[];
  final _langCodeCompleter = Completer<String>();
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

    if (!_langCodeCompleter.isCompleted) {
      _langCodeCompleter.complete(value);
    }
  }

  Future<String> get langCodeInited =>
      _langCode != null ? Future.value(_langCode) : _langCodeCompleter.future;

  void callWhenInited(ArgCallback<String> callback) {
    if (_langCode != null) {
      callback.call(_langCode!);
    } else {
      _initCallbacks.add(callback);
    }
  }
}
