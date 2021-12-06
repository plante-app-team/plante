import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/location/geolocator_wrapper.dart';
import 'package:plante/location/ip_location_provider.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shared_preferences_ext.dart';
import 'package:plante/model/shared_preferences_holder.dart';

const PREF_LAST_KNOWN_POS = 'PREF_LAST_KNOWN_POS2';

class UserLocationManager {
  final IpLocationProvider _ipLocationProvider;
  final PermissionsManager _permissionsManager;
  final SharedPreferencesHolder _prefsHolder;
  final GeolocatorWrapper _geolocatorWrapper;

  Coord? _lastKnownPositionField;
  Coord? get _lastKnownPosition => _lastKnownPositionField;
  set _lastKnownPosition(Coord? value) {
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

  final _lastKnownPositionCallbacks = <ArgCallback<Coord>>[];

  UserLocationManager(
      this._ipLocationProvider, this._permissionsManager, this._prefsHolder,
      {GeolocatorWrapper? geolocatorWrapper})
      : _geolocatorWrapper = geolocatorWrapper ?? GeolocatorWrapper() {
    _init();
  }

  Future<void> _init() async {
    await _initLastKnownPosition();
  }

  Future<Coord?> _tryObtainLastKnownPositionFromPrefs() async {
    final prefs = await _prefsHolder.get();
    return Coord.fromPointNullable(prefs.getPoint(PREF_LAST_KNOWN_POS));
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
      Coord position, SharedPreferencesHolder prefsHolder) async {
    if (!isInTests()) {
      throw Exception();
    }
    await _updateLastKnownPrefsPosition(position, prefsHolder);
  }

  static Future<void> _updateLastKnownPrefsPosition(
      Coord position, SharedPreferencesHolder prefsHolder) async {
    final prefs = await prefsHolder.get();
    await prefs.setPoint(PREF_LAST_KNOWN_POS, position.toPoint());
  }

  Future<PermissionState> _permissionStatus() async {
    return await _permissionsManager.status(PermissionKind.LOCATION);
  }

  Coord? lastKnownPositionInstant() => _lastKnownPosition;

  /// Can work without the permission
  Future<Coord?> lastKnownPosition() async {
    final permissionStatus = await _permissionStatus();
    if (permissionStatus != PermissionState.granted) {
      return _lastKnownPosition;
    }

    final Coord? position;
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
  Future<Coord?> currentPosition() async {
    final permissionStatus = await _permissionStatus();
    if (permissionStatus != PermissionState.granted) {
      return null;
    }
    final Coord? position;
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

  void callWhenLastPositionKnown(ArgCallback<Coord> callback) {
    if (_lastKnownPosition != null) {
      callback.call(_lastKnownPosition!);
    }
    _lastKnownPositionCallbacks.add(callback);
  }
}
