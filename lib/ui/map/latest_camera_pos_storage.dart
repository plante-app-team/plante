import 'dart:async';
import 'dart:math';

import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/shared_preferences_ext.dart';

class PointPersistentStorage {
  final String _prefsKey;
  final SharedPreferencesHolder _prefs;
  Point<double>? _pos;

  PointPersistentStorage(this._prefsKey, this._prefs) {
    get(); // Make a cache
  }

  Future<void> set(Point<double> pos) async {
    _pos = pos;
    final prefs = await _prefs.get();
    await prefs.setPoint(_prefsKey, pos);
  }

  Future<Point<double>?> get() async {
    if (_pos != null) {
      return _pos;
    }
    final prefs = await _prefs.get();
    final result = prefs.getPoint(_prefsKey);
    if (_pos != null) {
      // Async code protection
      return _pos;
    }
    _pos ??= result;
    return result;
  }

  Point<double>? getInstant() {
    return _pos;
  }
}
