import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/location/geolocator_wrapper.dart';
import 'package:plante/location/ip_location_provider.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/base/log.dart';

const PREF_LAST_KNOWN_POS = 'PREF_LAST_KNOWN_POS2';

class LocationController {
  final IpLocationProvider _ipLocationProvider;
  final PermissionsManager _permissionsManager;
  final SharedPreferencesHolder _prefsHolder;
  final GeolocatorWrapper _geolocatorWrapper;

  Point<double>? _lastKnownPositionField;
  Point<double>? get _lastKnownPosition => _lastKnownPositionField;
  set _lastKnownPosition(Point<double>? value) {
    final wasKnown = _lastKnownPositionField != null;
    _lastKnownPositionField = value;
    final isKnown = _lastKnownPositionField != null;
    if (!wasKnown && isKnown) {
      _lastKnownPositionCallbacks.forEach((e) {
        e.call(_lastKnownPosition!);
      });
      _lastKnownPositionCallbacks.clear();
    }
  }

  final _lastKnownPositionCallbacks = <ArgCallback<Point<double>>>[];

  LocationController(
      this._ipLocationProvider, this._permissionsManager, this._prefsHolder,
      {GeolocatorWrapper? geolocatorWrapper})
      : _geolocatorWrapper = geolocatorWrapper ?? GeolocatorWrapper() {
    _init();
  }

  Future<void> _init() async {
    await _initLastKnownPosition();
  }

  Future<Point<double>?> _tryObtainLastKnownPositionFromPrefs() async {
    final prefs = await _prefsHolder.get();
    final posString = prefs.getString(PREF_LAST_KNOWN_POS);
    if (posString == null) {
      return null;
    }

    final lonLatStrs = posString.split(';');
    if (lonLatStrs.length != 2) {
      if (lonLatStrs.isNotEmpty) {
        Log.e('Invalid posStr (1): $posString}');
      }
      await prefs.remove(PREF_LAST_KNOWN_POS);
      return null;
    }

    final lon = double.tryParse(lonLatStrs[0]);
    final lat = double.tryParse(lonLatStrs[1]);
    if (lon == null || lat == null) {
      Log.e('Invalid posStr (2): $posString}');
      await prefs.remove(PREF_LAST_KNOWN_POS);
      return null;
    }

    return Point<double>(lon, lat);
  }

  Future<void> _initLastKnownPosition() async {
    // Both calls attempt to fill the '_lastKnownPosition' field
    var pos = await currentPosition();
    if (pos != null) {
      return;
    }
    pos = await lastKnownPosition();
    if (pos != null) {
      return;
    }

    pos = await _ipLocationProvider.positionByIP();
    if (pos != null) {
      _lastKnownPosition = pos;
      await _updateLastKnownPrefsPosition(_lastKnownPosition!, _prefsHolder);
      return;
    }

    pos = await _tryObtainLastKnownPositionFromPrefs();
    if (pos != null) {
      _lastKnownPosition = pos;
    }
  }

  @visibleForTesting
  static Future<void> updateLastKnownPrefsPositionForTesting(
      Point<double> position, SharedPreferencesHolder prefsHolder) async {
    if (!isInTests()) {
      throw Exception();
    }
    await _updateLastKnownPrefsPosition(position, prefsHolder);
  }

  static Future<void> _updateLastKnownPrefsPosition(
      Point<double> position, SharedPreferencesHolder prefsHolder) async {
    final prefs = await prefsHolder.get();
    await prefs.setString(PREF_LAST_KNOWN_POS, '${position.x};${position.y}');
  }

  Future<PermissionState> _permissionStatus() async {
    return await _permissionsManager.status(PermissionKind.LOCATION);
  }

  Point<double>? lastKnownPositionInstant() => _lastKnownPosition;

  /// Can work without the permission
  Future<Point<double>?> lastKnownPosition() async {
    final permissionStatus = await _permissionStatus();
    if (permissionStatus != PermissionState.granted) {
      return _lastKnownPosition;
    }

    final Point<double>? position;
    try {
      position = await _geolocatorWrapper.getLastKnownPosition();
    } catch (e) {
      const msg = 'Geolocator.getLastKnownPosition fail';
      if (e is PermissionDeniedException) {
        Log.w(msg, ex: e);
      } else {
        Log.e(msg, ex: e);
      }
      return _lastKnownPosition;
    }
    if (position != null) {
      _lastKnownPosition = position;
      await _updateLastKnownPrefsPosition(position, _prefsHolder);
    }

    return position;
  }

  /// Works only if the permission is acquired
  Future<Point<double>?> currentPosition() async {
    final permissionStatus = await _permissionStatus();
    if (permissionStatus != PermissionState.granted) {
      return null;
    }
    final Point<double>? position;
    try {
      position = await _geolocatorWrapper.getCurrentPosition();
    } catch (e) {
      const msg = 'Geolocator.getCurrentPosition fail';
      if (e is TimeoutException ||
          e is PermissionDeniedException ||
          e is LocationServiceDisabledException) {
        Log.w(msg, ex: e);
      } else {
        Log.e(msg, ex: e);
      }
      return null;
    }
    if (position != null) {
      _lastKnownPosition = position;
      await _updateLastKnownPrefsPosition(position, _prefsHolder);
    }
    return position;
  }

  void callWhenLastPositionKnown(ArgCallback<Point<double>> callback) {
    if (_lastKnownPosition != null) {
      callback.call(_lastKnownPosition!);
    }
    _lastKnownPositionCallbacks.add(callback);
  }
}
