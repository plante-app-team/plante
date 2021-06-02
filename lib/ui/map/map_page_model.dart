import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/location_controller.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/map/lat_lng_extensions.dart';

typedef MapPageModelUpdateShopsCallback = void Function(
    Map<String, Shop> shops);
typedef MapPageModelErrorCallback = void Function(MapPageModelError error);

enum MapPageModelError {
  NETWORK_ERROR,
  OTHER,
}

class MapPageModel implements ShopsManagerListener {
  static const _DEFAULT_USER_POS = LatLng(44.4192543, 38.2052612);
  static const MAX_SHOPS_LOADS_ATTEMPTS = 3;
  static final _shopsLoadsAttemptsCooldown = isInTests()
      ? const Duration(milliseconds: 50)
      : const Duration(seconds: 3);
  final MapPageModelUpdateShopsCallback _updateShopsCallback;
  final MapPageModelErrorCallback _errorCallback;
  final VoidCallback _updateCallback;
  final LocationController _locationController;
  final ShopsManager _shopsManager;
  final _shopsCache = <String, Shop>{};
  final _loadedAreas = <LatLngBounds>{};
  DateTime _lastShopsLoadTime = DateTime(2000);
  LatLngBounds? _loadingArea;
  bool _networkOperationInProgress = false;

  LatLngBounds? _latestViewPort;

  int get loadedAreasCount => _loadedAreas.length;

  MapPageModel(this._locationController, this._shopsManager,
      this._updateShopsCallback, this._errorCallback, this._updateCallback) {
    _shopsManager.addListener(this);
  }

  void dispose() {
    _shopsManager.removeListener(this);
  }

  bool get loading => _loadingArea != null || _networkOperationInProgress;
  Map<String, Shop> get shopsCache => UnmodifiableMapView(_shopsCache);

  Future<bool> ensurePermissions() async {
    if (!await _locationController.permissionStatus().isGranted) {
      final status = await _locationController.requestPermission();
      if (!status.isGranted && !status.isLimited) {
        // TODO(https://trello.com/c/662nLdKd/): properly handle all possible statuses
        return false;
      }
    }
    return true;
  }

  CameraPosition defaultUserPos() {
    return const CameraPosition(target: _DEFAULT_USER_POS, zoom: 15);
  }

  CameraPosition? lastKnownUserPosInstant() {
    final lastKnownPosition = _locationController.lastKnownPositionInstant();
    if (lastKnownPosition == null) {
      return null;
    }
    return CameraPosition(
        target: LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude),
        zoom: 15);
  }

  Future<CameraPosition?> lastKnownUserPos() async {
    final lastKnownPosition = await _locationController.lastKnownPosition();
    if (lastKnownPosition == null) {
      return null;
    }
    return CameraPosition(
        target: LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude),
        zoom: 15);
  }

  Future<CameraPosition?> currentUserPos() async {
    final position = await _locationController.currentPosition();
    if (position == null) {
      return null;
    }
    return CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 15);
  }

  Future<void> onCameraMoved(LatLngBounds viewBounds) async {
    _latestViewPort = viewBounds;
    final result = await _maybeLoadShops(viewBounds, attemptNumber: 1);
    if (result.isOk) {
      final loadedSomething = result.unwrap();
      if (loadedSomething) {
        _updateShopsCallback.call(_shopsCache);
      }
    } else {
      _errorCallback.call(result.unwrapErr());
    }
    _updateCallback.call();
  }

  Future<Result<bool, MapPageModelError>> _maybeLoadShops(
      LatLngBounds viewBounds,
      {required int attemptNumber}) async {
    for (final loadedArea in _loadedAreas) {
      if (loadedArea.containsBounds(viewBounds)) {
        // Already loaded
        return Ok(false);
      }
    }

    if (_loadingArea != null && _loadingArea!.containsBounds(viewBounds)) {
      // Already loading
      return Ok(false);
    }
    final boundsToLoad = viewBounds.center.makeSquare(20 * 1 / 111); // +-20 kms
    _loadingArea = boundsToLoad;
    final timeSinceLastLoad = DateTime.now().difference(_lastShopsLoadTime);
    if (timeSinceLastLoad < _shopsLoadsAttemptsCooldown) {
      await Future.delayed(_shopsLoadsAttemptsCooldown - timeSinceLastLoad);
    }
    if (_loadingArea != boundsToLoad) {
      // Another load started while we were waiting
      return Ok(false);
    }

    _lastShopsLoadTime = DateTime.now();
    final Result<Map<String, Shop>, ShopsManagerError> shopsResult;
    try {
      shopsResult = await _shopsManager.fetchShops(
          Point(boundsToLoad.northeast.latitude,
              boundsToLoad.northeast.longitude),
          Point(boundsToLoad.southwest.latitude,
              boundsToLoad.southwest.longitude));
    } finally {
      _loadingArea = null;
    }

    if (shopsResult.isErr) {
      if (shopsResult.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
        return Err(MapPageModelError.NETWORK_ERROR);
      } else {
        if (attemptNumber >= MAX_SHOPS_LOADS_ATTEMPTS) {
          return Err(MapPageModelError.OTHER);
        }
        return _maybeLoadShops(viewBounds, attemptNumber: attemptNumber + 1);
      }
    }

    final shops = shopsResult.unwrap();
    _shopsCache.addAll(shops);
    _loadedAreas.add(boundsToLoad);
    return Ok(shops.isNotEmpty);
  }

  Future<Result<None, ShopsManagerError>> putProductToShops(
      Product product, List<Shop> shops) async {
    _networkOperationInProgress = true;
    _updateCallback.call();
    try {
      return await _shopsManager.putProductToShops(product, shops);
    } finally {
      _networkOperationInProgress = false;
      _updateCallback.call();
    }
  }

  @override
  void onLocalShopsChange() {
    /// Invalidating cache!
    _loadedAreas.clear();
    _shopsCache.clear();
    if (_latestViewPort != null) {
      onCameraMoved(_latestViewPort!);
    }
  }
}
