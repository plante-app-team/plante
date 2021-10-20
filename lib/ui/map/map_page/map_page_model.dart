import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/map/ui_list_addresses_obtainer.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

enum MapPageModelError {
  NETWORK_ERROR,
  OTHER,
}

class MapPageModel implements ShopsManagerListener {
  static const DEFAULT_USER_POS = LatLng(37.49777, -122.22195);

  final ArgCallback<Map<OsmUID, Shop>> _updateShopsCallback;
  final ArgCallback<MapPageModelError> _errorCallback;
  final VoidCallback _updateCallback;
  final VoidCallback _loadingChangeCallback;
  final LocationController _locationController;
  final ShopsManager _shopsManager;
  final AddressObtainer _addressObtainer;
  final LatestCameraPosStorage _latestCameraPosStorage;
  final DirectionsManager _directionsManager;
  final ProductsObtainer _productsObtainer;

  bool _viewPortShopsFetched = false;
  CoordsBounds? _latestViewPort;
  CoordsBounds? _latestFetchedViewPort;
  bool _networkOperationInProgress = false;

  Map<OsmUID, Shop> _shopsCache = {};
  final _shopsWithPossibleProducts = <OsmUID>{};

  bool _directionsAvailable = false;

  MapPageModel(
      this._locationController,
      this._shopsManager,
      this._addressObtainer,
      this._latestCameraPosStorage,
      this._directionsManager,
      this._productsObtainer,
      this._updateShopsCallback,
      this._errorCallback,
      this._updateCallback,
      this._loadingChangeCallback) {
    _shopsManager.addListener(this);
    _directionsManager
        .areDirectionsAvailable()
        .then((value) => _directionsAvailable = value);
  }

  void dispose() {
    _shopsManager.removeListener(this);
  }

  bool get loading => _networkOperationInProgress;
  Map<OsmUID, Shop> get shopsCache => UnmodifiableMapView(_shopsCache);
  Set<OsmUID> get shopsWithPossibleProducts =>
      UnmodifiableSetView(_shopsWithPossibleProducts);

  CameraPosition? initialCameraPosInstant() {
    var result = _latestCameraPosStorage.getCached();
    if (result != null) {
      return _pointToCameraPos(result);
    }
    result = _locationController.lastKnownPositionInstant();
    if (result != null) {
      return _pointToCameraPos(result);
    }
    return null;
  }

  Future<CameraPosition> initialCameraPos() async {
    var result = await _latestCameraPosStorage.get();
    if (result != null) {
      return _pointToCameraPos(result);
    }
    result = await _locationController.lastKnownPosition();
    if (result != null) {
      return _pointToCameraPos(result);
    }
    final _completer = Completer<CameraPosition>();
    _locationController.callWhenLastPositionKnown((pos) {
      _completer.complete(_pointToCameraPos(pos));
    });
    return _completer.future;
  }

  CameraPosition defaultUserPos() {
    return const CameraPosition(target: DEFAULT_USER_POS, zoom: 15);
  }

  CameraPosition _pointToCameraPos(Coord point) {
    return CameraPosition(target: point.toLatLng(), zoom: 15);
  }

  Future<CameraPosition?> currentUserPos() async {
    final result = await _locationController.currentPosition();
    if (result != null) {
      return _pointToCameraPos(result);
    }
  }

  bool viewPortShopsLoaded() => _viewPortShopsFetched;

  Future<void> onCameraIdle(CoordsBounds viewBounds) async {
    _latestViewPort = viewBounds;
    unawaited(_latestCameraPosStorage.set(viewBounds.center));

    // NOTE: we intentionally load shops each time
    // camera is idle - this is because [ShopsManager] filters
    // out shops which are not within the bounds it receives, thus
    // we need to give it new bounds all the time.
    if (await _shopsManager.osmShopsCacheExistFor(viewBounds)) {
      unawaited(_loadShopsImpl(viewBounds));
    } else {
      _viewPortShopsFetched = false;
    }
    _updateCallback.call();
  }

  Future<void> loadShops() async {
    if (_latestViewPort == null) {
      Log.e('MapPageModel.loadShops: no view port');
      return;
    }
    await _loadShopsImpl(_latestViewPort!);
  }

  Future<void> _loadShopsImpl(CoordsBounds viewPort) async {
    final result = await _networkOperation(() async {
      return await _shopsManager.fetchShops(viewPort);
    });
    if (result.isOk) {
      _shopsCache = result.unwrap();
      _viewPortShopsFetched = true;
      _latestFetchedViewPort = viewPort;
      _updateShopsCallback.call(result.unwrap());
      unawaited(_fetchOffShopsProductsData());
    } else {
      _errorCallback.call(_convertShopsManagerError(result.unwrapErr()));
    }
    _updateCallback.call();
  }

  Future<void> _fetchOffShopsProductsData() async {
    // Let's see which of the shops we display on the map
    // has products in Open Food Facts.
    final shopsOnMap = _shopsCache.values.toSet();
    for (final shopOnMap in shopsOnMap) {
      // Let's convert our shop name to what would be a Shop ID in OFF.
      final possibleOffShopID =
          OffShopsManager.shopNameToPossibleOffShopID(shopOnMap.name);
      final products =
          await _productsObtainer.getProductsOfShopsChain(possibleOffShopID);
      if (products.isOk && products.unwrap().isNotEmpty) {
        _shopsWithPossibleProducts.add(shopOnMap.osmUID);
        _updateShopsCallback.call(_shopsCache);
      }
    }
  }

  Future<T> _networkOperation<T>(Future<T> Function() operation) async {
    _networkOperationInProgress = true;
    _updateCallback.call();
    _loadingChangeCallback.call();
    try {
      return await operation.call();
    } finally {
      _networkOperationInProgress = false;
      _updateCallback.call();
      _loadingChangeCallback.call();
    }
  }

  Future<Result<None, ShopsManagerError>> putProductToShops(
      Product product, List<Shop> shops) async {
    return await _networkOperation(() async {
      return await _shopsManager.putProductToShops(product, shops);
    });
  }

  Future<Result<Shop, ShopsManagerError>> createShop(
      String name, ShopType type, Coord coord) async {
    return await _networkOperation(() async {
      return await _shopsManager.createShop(
        name: name,
        coord: coord,
        type: type,
      );
    });
  }

  UiListAddressesObtainer<Shop> createListAddressesObtainer() {
    return UiListAddressesObtainer<Shop>(_addressObtainer);
  }

  @override
  void onLocalShopsChange() {
    /// Invalidating cache!
    if (_latestFetchedViewPort != null) {
      // We expect the call to not go to network because
      // we use already fetched view port
      _loadShopsImpl(_latestFetchedViewPort!);
    }
  }

  bool areDirectionsAvailable() => _directionsAvailable;

  void showDirectionsTo(Shop shop) {
    _directionsManager.direct(shop.coord, shop.name);
  }

  void finishWith<T>(BuildContext context, T result) {
    Navigator.pop(context, result);
  }
}

MapPageModelError _convertShopsManagerError(ShopsManagerError error) {
  switch (error) {
    case ShopsManagerError.NETWORK_ERROR:
      return MapPageModelError.NETWORK_ERROR;
    case ShopsManagerError.OSM_SERVERS_ERROR:
      return MapPageModelError.OTHER;
    case ShopsManagerError.OTHER:
      return MapPageModelError.OTHER;
  }
}

extension _CoordExt on Coord {
  LatLng toLatLng() => LatLng(lat, lon);
}
