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
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/map/ui_list_addresses_obtainer.dart';
import 'package:plante/outside/products/suggested_products_manager.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

enum MapPageModelError {
  NETWORK_ERROR,
  OTHER,
}

class MapPageModel implements ShopsManagerListener {
  static const DEFAULT_USER_POS = LatLng(37.49777, -122.22195);
  static final delayBetweenSuggestionsAbsorption =
      isInTests() ? const Duration(seconds: 1) : const Duration(seconds: 5);

  final ArgCallback<Map<OsmUID, Shop>> _updateShopsCallback;
  final ArgCallback<MapPageModelError> _errorCallback;
  final VoidCallback _updateCallback;
  final VoidCallback _loadingChangeCallback;
  final VoidCallback _suggestionsLoadingChangeCallback;
  final LocationController _locationController;
  final ShopsManager _shopsManager;
  final AddressObtainer _addressObtainer;
  final LatestCameraPosStorage _latestCameraPosStorage;
  final DirectionsManager _directionsManager;
  final SuggestedProductsManager _suggestedProductsManager;

  bool _viewPortShopsFetched = false;
  CoordsBounds? _latestViewPort;
  CoordsBounds? _latestFetchedViewPort;
  bool _networkOperationInProgress = false;
  bool _firstTerritoryLoadDone = false;

  Map<OsmUID, Shop> _shopsCache = {};
  final _suggestedProductsBarcodes = <OsmUID, Set<String>>{};
  StreamSubscription? _suggestedBarcodesSubscription;

  bool _directionsAvailable = false;

  MapPageModel(
      this._locationController,
      this._shopsManager,
      this._addressObtainer,
      this._latestCameraPosStorage,
      this._directionsManager,
      this._suggestedProductsManager,
      this._updateShopsCallback,
      this._errorCallback,
      this._updateCallback,
      this._loadingChangeCallback,
      this._suggestionsLoadingChangeCallback) {
    _shopsManager.addListener(this);
    _directionsManager
        .areDirectionsAvailable()
        .then((value) => _directionsAvailable = value);
  }

  void dispose() {
    _shopsManager.removeListener(this);
  }

  bool get loading => _networkOperationInProgress || !_firstTerritoryLoadDone;
  Map<OsmUID, Shop> get shopsCache => UnmodifiableMapView(_shopsCache);
  bool get loadingSuggestions => _suggestedBarcodesSubscription != null;
  Iterable<OsmUID> get shopsWithSuggestedProducts =>
      _suggestedProductsBarcodes.keys;

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
    _firstTerritoryLoadDone = true;
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
    final shopsOnMap = _shopsCache.values;

    await _suggestedBarcodesSubscription?.cancel();
    final collectedBarcodes = <OsmUID, List<String>>{};
    var lastAbsorbTime = DateTime.now();
    final absorbNewSuggestions = () {
      for (final entry in collectedBarcodes.entries) {
        _suggestedProductsBarcodes[entry.key] ??= {};
        _suggestedProductsBarcodes[entry.key]!.addAll(entry.value);
      }
      if (!collectedBarcodes.isEmpty) {
        collectedBarcodes.clear();
        _updateShopsCallback.call(_shopsCache);
      }
      lastAbsorbTime = DateTime.now();
    };
    _suggestedBarcodesSubscription = _suggestedProductsManager
        .getSuggestedBarcodes(shopsOnMap)
        .listen((event) {
      if (event.isErr) {
        return;
      }
      final pair = event.unwrap();
      collectedBarcodes[pair.first] ??= [];
      collectedBarcodes[pair.first]!.addAll(pair.second);
      if (DateTime.now().difference(lastAbsorbTime) >=
          delayBetweenSuggestionsAbsorption) {
        absorbNewSuggestions();
      }
    }, onDone: () {
      _suggestedBarcodesSubscription = null;
      _suggestionsLoadingChangeCallback.call();
      absorbNewSuggestions.call();
    });
    _suggestionsLoadingChangeCallback.call();
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

  int suggestedProductsCount(Shop shop) {
    return _suggestedProductsBarcodes[shop.osmUID]?.length ?? 0;
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
