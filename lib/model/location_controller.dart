import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plante/base/log.dart';

const PREF_LAST_KNOWN_POS = 'PREF_LAST_KNOWN_POS';

/// Works only if the permission is acquired
class LocationController {
  Position? _lastKnownPosition;

  LocationController() {
    _init();
  }

  Future<void> _init() async {
    await _tryObtainLastPositionFromPrefs();
  }

  Future<void> _tryObtainLastPositionFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final posString = prefs.getString(PREF_LAST_KNOWN_POS);
    if (posString != null) {
      try {
        _lastKnownPosition = Position.fromMap(json.decode(posString));
      } on FormatException catch (e) {
        _lastKnownPosition = null;
        Log.e("LocationController exception while parsing $posString", ex: e);
      }
    }
  }

  Future<void> _updateLastKnownPrefsPosition(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(PREF_LAST_KNOWN_POS, json.encode(position.toJson()));
  }

  Future<PermissionStatus> permissionStatus() async {
    return Permission.location.status;
  }

  Future<PermissionStatus> requestPermission() async {
    return await Permission.location.request();
  }

  Position? lastKnownPositionInstant() => _lastKnownPosition;

  Future<Position?> lastKnownPosition() async {
    if (!await permissionStatus().isGranted) {
      return null;
    }

    var position = await Geolocator.getLastKnownPosition();
    if (position != null && position != _lastKnownPosition) {
      _lastKnownPosition = position;
      _updateLastKnownPrefsPosition(position);
    }

    return position;
  }

  Future<Position?> currentPosition() async {
    if (!await permissionStatus().isGranted) {
      return null;
    }
    final result = await Geolocator.getCurrentPosition();
    _lastKnownPosition = result;
    _updateLastKnownPrefsPosition(result);
    return result;
  }
}
