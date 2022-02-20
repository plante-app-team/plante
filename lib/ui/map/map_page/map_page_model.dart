import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/map/ui_list_addresses_obtainer.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/products/suggestions/suggested_barcodes_map_full.dart';
import 'package:plante/products/suggestions/suggested_products_manager.dart';
import 'package:plante/products/suggestions/suggestions_for_shop.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/components/delayed_loading_notifier.dart';
import 'package:plante/ui/map/components/delayed_lossy_arg_callback.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/shop_creation/shops_creation_manager.dart';

enum MapPageModelError {
  NETWORK_ERROR,
  OTHER,
}

class MapPageModel with ShopsManagerListener {
  static const DEFAULT_USER_POS = LatLng(37.49777, -122.22195);
  static final delayBetweenSuggestionsAbsorption =
      isInTests() ? const Duration(seconds: 1) : const Duration(seconds: 5);

  late final DelayedLossyArgCallback<Map<OsmUID, Shop>>
      _updateShopsAndUICallback;
  final ArgCallback<MapPageModelError> _errorCallback;
  final SharedPreferencesHolder _prefs;
  final UserLocationManager _userLocationManager;
  final ShopsManager _shopsManager;
  final AddressObtainer _addressObtainer;
  final LatestCameraPosStorage _latestCameraPosStorage;
  final DirectionsManager _directionsManager;
  final SuggestedProductsManager _suggestedProductsManager;
  final CachingUserAddressPiecesObtainer _userAddressPiecesObtainer;
  final ShopsCreationManager _shopsCreationManager;
  final UIValueBase<bool> _shouldLoadNewShops;

  var _disposed = false;

  late final UIValue<bool> _viewPortShopsFetched;
  CoordsBounds? _latestViewPort;
  CoordsBounds? _latestFetchedViewPort;
  var _fetchingViewPort = false;
  late final UIValue<bool> _firstTerritoryLoadDone;

  Map<OsmUID, Shop> _shopsCache = {};
  final _barcodesSuggestions = SuggestedBarcodesMapFull({});
  StreamSubscription? _suggestedBarcodesSubscription;

  bool _directionsAvailable = false;

  late final DelayedLoadingNotifier _loadingNotifier;
  late final DelayedLoadingNotifier _loadingSuggestionsNotifier;

  late final UIValue<bool> _loading;
  late final UIValue<bool> _loadingSuggestions;

  MapPageModel(
      this._prefs,
      this._userLocationManager,
      this._shopsManager,
      this._addressObtainer,
      this._latestCameraPosStorage,
      this._directionsManager,
      this._suggestedProductsManager,
      this._userAddressPiecesObtainer,
      this._shopsCreationManager,
      this._shouldLoadNewShops,
      ArgCallback<Map<OsmUID, Shop>> updateShopsCallback,
      this._errorCallback,
      UIValuesFactory uiValuesFactory) {
    _shopsManager.addListener(this);

    _directionsManager
        .areDirectionsAvailable()
        .then((value) => _directionsAvailable = value);
    _shouldLoadNewShops.callOnChanges((shouldLoadShops) {
      if (!shouldLoadShops && _suggestedBarcodesSubscription != null) {
        _suggestedBarcodesSubscription?.cancel();
        _suggestedBarcodesSubscription = null;
        _loadingSuggestionsNotifier.onLoadingEnd();
      }
    });

    _updateShopsAndUICallback =
        DelayedLossyArgCallback(const Duration(milliseconds: 500), (shops) {
      updateShopsCallback.call(shops);
    });

    _loadingNotifier = DelayedLoadingNotifier(
      firstLoadingInstantNotification: true,
      delay: const Duration(milliseconds: 250),
      callback: _updateLoadingValues,
    );
    _loadingSuggestionsNotifier = DelayedLoadingNotifier(
      firstLoadingInstantNotification: true,
      delay: const Duration(seconds: 2),
      callback: _updateLoadingValues,
    );
    _viewPortShopsFetched = uiValuesFactory.create<bool>(false);
    _firstTerritoryLoadDone = uiValuesFactory.create<bool>(false);
    _loading = uiValuesFactory.create<bool>(_computeLoading());
    _loadingSuggestions =
        uiValuesFactory.create<bool>(_computeLoadingSuggestions());
    _firstTerritoryLoadDone.callOnChanges((unused) => _updateLoadingValues());
  }

  bool _computeLoading() =>
      _loadingNotifier.isLoading || !_firstTerritoryLoadDone.cachedVal;
  bool _computeLoadingSuggestions() => _loadingSuggestionsNotifier.isLoading;
  void _updateLoadingValues() {
    if (_disposed) {
      return;
    }
    _loading.setValue(_computeLoading());
    _loadingSuggestions.setValue(_computeLoadingSuggestions());
  }

  void dispose() {
    _disposed = true;
    _shopsManager.removeListener(this);
  }

  UIValueBase<bool> get loading => _loading;
  UIValueBase<bool> get loadingSuggestions => _loadingSuggestions;
  Map<OsmUID, Shop> get shopsCache => UnmodifiableMapView(_shopsCache);
  SuggestedBarcodesMapFull get barcodesSuggestions =>
      _barcodesSuggestions.unmodifiable();
  SharedPreferencesHolder get prefs => _prefs;

  CameraPosition? initialCameraPosInstant() {
    var result = _latestCameraPosStorage.getCached();
    if (result != null) {
      return _pointToCameraPos(result);
    }
    result = _userLocationManager.lastKnownPositionInstant();
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
    result = await _userLocationManager.lastKnownPosition();
    if (result != null) {
      return _pointToCameraPos(result);
    }
    final _completer = Completer<CameraPosition>();
    _userLocationManager.callWhenLastPositionKnown((pos) {
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

  Future<CameraPosition?> currentUserPos(
      {required bool explicitUserRequest}) async {
    final result = await _userLocationManager.currentPosition(
        explicitUserRequest: explicitUserRequest);
    if (result != null) {
      return _pointToCameraPos(result);
    }
    return null;
  }

  UIValueBase<bool> get viewPortShopsLoaded => _viewPortShopsFetched;

  Future<void> onCameraIdle(CoordsBounds viewBounds) async {
    _latestViewPort = viewBounds;
    unawaited(_latestCameraPosStorage.set(viewBounds.center));

    // NOTE: we load shops only when they're in cache already.
    // If they're not in cache, setting of [_viewPortShopsFetched] will
    // show to the user button with a prompt to load the shops.
    if (await _shopsManager.osmShopsCacheExistFor(viewBounds)) {
      unawaited(_loadShopsImpl(viewBounds));
    } else {
      _viewPortShopsFetched.setValue(false);
    }
    _firstTerritoryLoadDone.setValue(true);
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
      try {
        _fetchingViewPort = true;
        return await _shopsManager.fetchShops(viewPort);
      } finally {
        _fetchingViewPort = false;
      }
    });
    if (result.isOk) {
      _shopsCache = result.unwrap();
      _latestFetchedViewPort = viewPort;
      _viewPortShopsFetched.setValue(true);
      _updateShopsAndUICallback.call(result.unwrap());
      unawaited(_fetchSuggestions());
    } else {
      _errorCallback.call(_convertShopsManagerError(result.unwrapErr()));
    }
    // NOTE: we don't call [_updateCallback] here, because
    // [_updateShopsAndUICallback] will update the UI anyways.
  }

  Future<void> _fetchSuggestions() async {
    await _suggestedBarcodesSubscription?.cancel();
    if (!_loadingSuggestionsNotifier.isLoading) {
      _loadingSuggestionsNotifier.onLoadingStart();
    }

    final countryCode = await _userAddressPiecesObtainer.getCameraCountryCode();
    final center = _latestViewPort?.center;
    if (countryCode == null ||
        center == null ||
        !_shouldLoadNewShops.cachedVal) {
      _loadingSuggestionsNotifier.onLoadingEnd();
      return;
    }

    // Let's see which of the shops we display on the map
    // has products in Open Food Facts.
    final shopsOnMap = _shopsCache.values;

    final collectedSuggestions = <OsmUID, List<SuggestionsForShop>>{};
    var lastAbsorbTime = DateTime.now();
    final absorbNewSuggestions = () {
      for (final entry in collectedSuggestions.entries) {
        entry.value.forEach(_applySuggestions);
      }
      if (collectedSuggestions.isNotEmpty) {
        collectedSuggestions.clear();
        _updateShopsAndUICallback.call(_shopsCache);
      }
      lastAbsorbTime = DateTime.now();
    };

    final stream = _suggestedProductsManager.getSuggestedBarcodes(
        shopsOnMap, center, countryCode);
    _suggestedBarcodesSubscription = stream.listen((event) {
      if (event.isErr) {
        return;
      }
      final suggestion = event.unwrap();
      collectedSuggestions[suggestion.osmUID] ??= [];
      collectedSuggestions[suggestion.osmUID]!.add(suggestion);
      if (DateTime.now().difference(lastAbsorbTime) >=
          delayBetweenSuggestionsAbsorption) {
        absorbNewSuggestions();
      }
    }, onDone: () {
      _suggestedBarcodesSubscription = null;
      _loadingSuggestionsNotifier.onLoadingEnd();
      absorbNewSuggestions.call();
    });
  }

  void _applySuggestions(SuggestionsForShop suggestions) {
    _barcodesSuggestions.add(suggestions);
  }

  Future<T> _networkOperation<T>(Future<T> Function() operation) async {
    _loadingNotifier.onLoadingStart();
    try {
      return await operation.call();
    } finally {
      _loadingNotifier.onLoadingEnd();
    }
  }

  Future<Result<None, ShopsManagerError>> putProductToShops(
      Product product, List<Shop> shops, ProductAtShopSource source) async {
    return await _networkOperation(() async {
      return await _shopsManager.putProductToShops(product, shops, source);
    });
  }

  Future<Result<Shop?, GeneralError>> startShopCreation(
      Coord coord, BuildContext context) {
    return _shopsCreationManager.startShopCreation(coord, context);
  }

  UiListAddressesObtainer<Shop> createListAddressesObtainer() {
    return UiListAddressesObtainer<Shop>(_addressObtainer);
  }

  @override
  void onLocalShopsChange() {
    // Let's invalidate cache if a viewport was loaded before, and if
    // a viewport is not being loaded right now - if it's being loaded right
    // now, [_latestFetchedViewPort] has an outdated value.
    if (_latestFetchedViewPort != null && !_fetchingViewPort) {
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

extension on Coord {
  LatLng toLatLng() => LatLng(lat, lon);
}
