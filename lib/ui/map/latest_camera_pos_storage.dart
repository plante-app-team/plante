import 'dart:async';

import 'package:plante/model/coord.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/shared_preferences_ext.dart';

class LatestCameraPosStorage {
  static const _LATEST_CAMERA_POS = 'LATEST_CAMERA_POS';
  final SharedPreferencesHolder _prefs;
  Coord? _pos;

  LatestCameraPosStorage(this._prefs) {
    // Make a cache
    get();
  }

  Future<void> set(Coord pos) async {
    _pos = pos;
    final prefs = await _prefs.get();
    await prefs.setPoint(_LATEST_CAMERA_POS, pos.toPoint());
  }

  Future<Coord?> get() async {
    if (_pos != null) {
      return _pos;
    }
    final prefs = await _prefs.get();
    final resultPoint = prefs.getPoint(_LATEST_CAMERA_POS);
    final result = resultPoint != null ? Coord.fromPoint(resultPoint) : null;
    if (_pos != null) {
      // Async code protection
      return _pos;
    }
    _pos ??= result;
    return result;
  }

  Coord? getCached() {
    return _pos;
  }
}
