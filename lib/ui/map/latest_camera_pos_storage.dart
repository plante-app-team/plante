import 'dart:async';
import 'dart:math';

import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/shared_preferences_ext.dart';

class LatestCameraPosStorage {
  static const _LATEST_CAMERA_POS = 'LATEST_CAMERA_POS';
  final SharedPreferencesHolder _prefs;
  Point<double>? _pos;

  LatestCameraPosStorage(this._prefs) {
    // Make a cache
    get();
  }

  Future<void> set(Point<double> pos) async {
    _pos = pos;
    final prefs = await _prefs.get();
    await prefs.setPoint(_LATEST_CAMERA_POS, pos);
  }

  Future<Point<double>?> get() async {
    if (_pos != null) {
      return _pos;
    }
    final prefs = await _prefs.get();
    final result = prefs.getPoint(_LATEST_CAMERA_POS);
    if (_pos != null) {
      // Async code protection
      return _pos;
    }
    _pos ??= result;
    return result;
  }

  Point<double>? getCached() {
    return _pos;
  }
}
