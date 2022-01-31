import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/ui/base/components/animated_list_simple_plante.dart';
import 'package:plante/ui/base/components/button_filled_small_plante.dart';
import 'package:plante/ui/base/components/licence_label.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/ui_permissions_utils.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/components/animated_map_widget.dart';
import 'package:plante/ui/map/components/fab_my_location.dart';
import 'package:plante/ui/map/components/map_bottom_hint.dart';
import 'package:plante/ui/map/components/map_hints_list.dart';
import 'package:plante/ui/map/components/map_search_bar.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_create_shop.dart';
import 'package:plante/ui/map/map_page/map_page_mode_default.dart';
import 'package:plante/ui/map/map_page/map_page_model.dart';
import 'package:plante/ui/map/map_page/map_page_progress_bar.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';
import 'package:plante/ui/map/map_page/map_page_timed_hints.dart';
import 'package:plante/ui/map/map_page/markers_builder.dart';
import 'package:plante/ui/map/search_page/map_search_page.dart';
import 'package:plante/ui/map/search_page/map_search_page_result.dart';

enum MapPageRequestedMode {
  DEFAULT,
  ADD_PRODUCT,
  SELECT_SHOPS,
}

class MapPageController {
  VoidCallback? _startStoreCreation;
  VoidCallback? _switchToDefaultMode;

  /// Note: the map will switch to the default mode after store creation
  /// is finished (or canceled).
  void startShopCreation() {
    _startStoreCreation?.call();
  }

  void switchToDefaultMode() {
    _switchToDefaultMode?.call();
  }
}

class MapPage extends PagePlante {
  final Product? product;
  final List<Shop> initialSelectedShops;
  final MapPageRequestedMode requestedMode;
  final MapPageController? controller;
  final testingStorage = MapPageTestingStorage();

  MapPage(
      {Key? key,
      this.product,
      this.initialSelectedShops = const [],
      this.requestedMode = MapPageRequestedMode.DEFAULT,
      this.controller,
      GoogleMapController? mapControllerForTesting,
      bool createMapWidgetForTesting = false})
      : super(key: key) {
    if (mapControllerForTesting != null && !isInTests()) {
      throw Exception('MapPage: not in tests (init)');
    }
    testingStorage.mapControllerForTesting = mapControllerForTesting;
    testingStorage.createMapWidgetForTesting = createMapWidgetForTesting;
  }

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends PageStatePlante<MapPage>
    with SingleTickerProviderStateMixin {
  static final _instances = <_MapPageState>[];
  final PermissionsManager _permissionsManager;
  late final MapPageModel _model;
  var _modeInited = false;
  late final UIValue<MapPageMode> _mode;
  late final UIValue<bool> _locationPermissionObtained;

  final _mapController = Completer<GoogleMapController>();
  late final UIValue<Set<Marker>> _displayedShopsMarkers;
  Iterable<Shop> _displayedShops = const [];
  late final ClusterManager _clusterManager;

  final _hintsController = MapHintsListController();
  late final UIValue<RichText?> _bottomHint;

  late final UIValue<MapSearchPageResult?> _latestSearchResult;

  late final UIValue<bool> _loadNewShops;

  _MapPageState()
      : _permissionsManager = GetIt.I.get<PermissionsManager>(),
        super('MapPage');

  @override
  void initState() {
    super.initState();
    _locationPermissionObtained = UIValue(false, ref);
    _displayedShopsMarkers = UIValue({}, ref);
    _bottomHint = UIValue(null, ref);
    _latestSearchResult = UIValue(null, ref);
    _loadNewShops = UIValue(true, ref);

    widget.testingStorage.finishCallback = (result) {
      _model.finishWith(context, result);
    };
    widget.testingStorage.onMapMoveCallback = (posZoomPair) {
      _onCameraMove(CameraPosition(
          target: posZoomPair.first.toLatLng(), zoom: posZoomPair.second));
    };
    widget.testingStorage.onMapIdleCallback = _onCameraIdle;
    widget.testingStorage.onMarkerClickCallback = _onMarkerClick;
    widget.testingStorage.onMapClickCallback = (Coord coord) {
      _onMapTap(LatLng(coord.lat, coord.lon));
    };
    widget.testingStorage.modeCallback = () {
      return _mode.cachedVal;
    };
    widget.testingStorage.onSearchResultCallback = _onSearchResult;

    final updateMapCallback = () {
      if (mounted) {
        final allShops = <Shop>{};
        _mode.cachedVal.onShopsUpdated(_model.shopsCache);
        allShops.addAll(_model.shopsCache.values);
        allShops.addAll(_mode.cachedVal.additionalShops());
        _onShopsUpdated(_mode.cachedVal.filter(allShops));
      }
    };
    final updateShopsCallback = (_) {
      updateMapCallback.call();
    };
    _model = MapPageModel(
      GetIt.I.get<SharedPreferencesHolder>(),
      GetIt.I.get<UserLocationManager>(),
      GetIt.I.get<ShopsManager>(),
      GetIt.I.get<AddressObtainer>(),
      GetIt.I.get<LatestCameraPosStorage>(),
      GetIt.I.get<DirectionsManager>(),
      GetIt.I.get<SuggestedProductsManager>(),
      GetIt.I.get<CachingUserAddressPiecesObtainer>(),
      _loadNewShops.unmodifiable(),
      updateShopsCallback,
      _onError,
      uiValuesFactory,
    );

    /// The clustering library levels logic is complicated.
    ///
    /// The manager will have N number of levels, each level is a zoom value
    /// which marks when clustering behaviour should change (whether to cluster
    /// markers into smaller or bigger groups).
    ///
    /// The levels in the const list below are selected by manual testing.
    /// You can adjust them, but only with very careful testing and with
    /// God's help (you'll need it).
    const clusteringLevels = <double>[9, 9.5, 10, 10.5, 11, 12, 14, 17, 18];
    _clusterManager = ClusterManager<Shop>([], _updateMarkers,
        markerBuilder: _markersBuilder, levels: clusteringLevels);

    final updateBottomHintCallback = _bottomHint.setValue;
    final moveMapCallback = (Coord coord) async {
      final mapController = await _mapController.future;
      await mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(coord.lat, coord.lon),
              zoom: await mapController.getZoomLevel())));
    };
    final switchModeCallback = (MapPageMode newMode) {
      analytics.sendEvent('map_page_mode_switch_${newMode.nameForAnalytics}');
      final oldMode = _mode.cachedVal;
      oldMode.deinit();
      _mode.setValue(newMode);
      newMode.init(oldMode);
      updateMapCallback.call();
    };
    _mode = UIValue(
        MapPageModeDefault(MapPageModeParams(
            analytics: analytics,
            model: _model,
            hintsListController: _hintsController,
            widgetSource: () => widget,
            contextSource: () => context,
            displayedShopsSource: () => _displayedShops,
            updateMapCallback: updateMapCallback,
            bottomHintCallback: updateBottomHintCallback,
            moveMapCallback: moveMapCallback,
            modeSwitchCallback: switchModeCallback,
            uiValuesFactory: uiValuesFactory,
            isLoading: _model.loading,
            isLoadingSuggestions: _model.loadingSuggestions,
            areShopsForViewPortLoaded: _model.viewPortShopsLoaded,
            shouldLoadNewShops: _loadNewShops)),
        ref);

    widget.controller?._switchToDefaultMode = () {
      if (_mode.cachedVal is! MapPageModeDefault) {
        switchModeCallback.call(MapPageModeDefault(_mode.cachedVal.params));
      }
    };
    widget.controller?._startStoreCreation = () {
      final nextMode = () => MapPageModeDefault(_mode.cachedVal.params);
      switchModeCallback
          .call(MapPageModeCreateShop(_mode.cachedVal.params, nextMode));
    };

    _asyncInit();
    _instances.add(this);
    _instances.forEach((instance) {
      instance.onInstancesChange();
    });

    if (widget.testingStorage.mapControllerForTesting != null) {
      _mapController.complete(widget.testingStorage.mapControllerForTesting);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_modeInited) {
      // NOTE: didChangeDependencies is called indirectly from
      // a [Widget.build] function.
      // The Riverpod library _hates_ it when values managed by it
      // are changed from [Widget.build] and causes exceptions.
      // Meanwhile, [MapPageMode.init] can (and does) cause different
      // UIValues to be changed. To avoid exceptions, we delay [init] call
      // until the next frame.
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        if (!_modeInited) {
          _mode.cachedVal.init(null);
          _modeInited = true;
        }
      });
    }
  }

  Future<Marker> _markersBuilder(Cluster<Shop> cluster) async {
    final extraData = ShopsMarkersExtraData(_mode.cachedVal.selectedShops(),
        _mode.cachedVal.accentedShops(), _model.barcodesSuggestions);
    return markersBuilder(cluster, extraData, context, _onMarkerClick);
  }

  void _onMarkerClick(Iterable<Shop> shops) {
    if (shops.isEmpty) {
      return;
    }
    analytics.sendEvent(
        'map_shops_click', {'shops': shops.map((e) => e.osmUID).join(', ')});
    _mode.cachedVal.onMarkerClick(shops);
  }

  void _asyncInit() async {
    await _initMapStyle();
    final permission =
        await _permissionsManager.status(PermissionKind.LOCATION);
    final permissionObtained = permission == PermissionState.granted ||
        permission == PermissionState.limited;
    _locationPermissionObtained.setValue(permissionObtained);
  }

  Future<void> _initMapStyle() async {
    final mapController = await _mapController.future;
    // We'd like to hide all businesses known to Google Maps because
    // we'll how our own list of shops and we don't want 2 lists to conflict.
    const noBusinessesStyle = '''
      [
        {
          "featureType": "poi.business",
          "elementType": "all",
          "stylers": [ { "visibility": "off" } ]
        }
      ]
      ''';
    await mapController.setMapStyle(noBusinessesStyle);
  }

  /// Returns visible region after camera move
  Future<LatLngBounds> _moveCameraTo(CameraPosition position) async {
    final mapController = await _mapController.future;
    await mapController.animateCamera(CameraUpdate.newCameraPosition(position));
    return await mapController.getVisibleRegion();
  }

  @override
  void dispose() {
    _instances.remove(this);
    _instances.forEach((instance) {
      instance.onInstancesChange();
    });
    _model.dispose();
    () async {
      final mapController = await _mapController.future;
      mapController.dispose();
    }.call();
    super.dispose();
  }

  void onInstancesChange() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Update!
        });
      }
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    var initialPos = _model.initialCameraPosInstant();
    if (initialPos == null) {
      _model.initialCameraPos().then(_moveCameraTo);
      initialPos = _model.defaultUserPos();
    }

    final searchBar = consumer((ref) {
      final loadNewShops = _loadNewShops.watch(ref);
      final viewPortShopsLoaded = _model.viewPortShopsLoaded.watch(ref);
      if (!loadNewShops || !viewPortShopsLoaded) {
        return const SizedBox();
      }
      return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Hero(
              tag: 'search_bar',
              child: Consumer(
                  builder: (context, ref, _) => MapSearchBar(
                      queryOverride: _latestSearchResult.watch(ref)?.query,
                      enabled: false,
                      onDisabledTap: _onSearchBarTap,
                      onCleared: () {
                        _latestSearchResult.setValue(null);
                        _mode.cachedVal.deselectShops();
                      }))));
    });

    final loadShopsButton = consumer((ref) {
      final loadNewShops = _loadNewShops.watch(ref);
      final loading = _model.loading.watch(ref);
      final viewPortShopsLoaded = _model.viewPortShopsLoaded.watch(ref);
      return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: AnimatedMapWidget(
              child: !viewPortShopsLoaded && loadNewShops && !loading
                  ? ButtonFilledSmallPlante.lightGreen(
                      elevation: 5,
                      onPressed: _loadShops,
                      text: context.strings.map_page_load_shops_of_this_area,
                    )
                  : const SizedBox()));
    });

    final createMapWidget =
        !isInTests() || widget.testingStorage.createMapWidgetForTesting;
    final content = Stack(children: [
      if (createMapWidget)
        Consumer(
            builder: (context, ref, _) => GoogleMap(
                  myLocationEnabled: _locationPermissionObtained.watch(ref),
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  minMaxZoomPreference: MinMaxZoomPreference(
                      _mode.watch(ref).minZoom(), _mode.watch(ref).maxZoom()),
                  mapType: MapType.normal,
                  initialCameraPosition: initialPos!,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller);
                    _clusterManager.setMapController(controller);
                    _clusterManager.onCameraMove(initialPos!);
                    _onCameraIdle();
                  },
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  onTap: _onMapTap,
                  // When there are more than 2 instances of GoogleMap and both
                  // of them have markers, this screws up the markers for some reason.
                  // Couldn't figure out why, probably there's a mistake either in
                  // the Google Map lib or in the Clustering lib, but it's easier to
                  // just use markers for 1 instance at a time.
                  markers: _instances.last == this
                      ? _displayedShopsMarkers.watch(ref)
                      : {},
                )),
      Align(
        alignment: Alignment.bottomRight,
        child: LicenceLabel(
          darkBox: false,
          label: context.strings.map_page_open_street_map_licence,
        ),
      ),
      Align(
          alignment: Alignment.bottomCenter,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
                alignment: Alignment.centerRight,
                child: SizedBox(width: 80, child: _fabs())),
            loadShopsButton,
            Consumer(
                builder: (context, ref, _) =>
                    MapBottomHint(_bottomHint.watch(ref))),
            Consumer(
                builder: (context, ref, _) => AnimatedListSimplePlante(
                    children: _mode.watch(ref).buildBottomActions())),
            _progressBar(),
          ])),
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
            padding: const EdgeInsets.only(top: 44),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: AnimatedMapWidget(child: searchBar),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Consumer(
                    builder: (context, ref, _) => AnimatedMapWidget(
                        child: _mode.watch(ref).buildHeader())),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: MapHintsList(controller: _hintsController),
              ),
              Consumer(
                  builder: (context, ref, _) => AnimatedMapWidget(
                      child: _mode.watch(ref).buildTopActions())),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: IgnorePointer(
                    child: MapPageTimedHints(
                        loading: _model.loading,
                        loadingSuggestions: _model.loadingSuggestions)),
              ),
            ])),
      ),
      consumer((ref) => _mode.watch(ref).buildOverlay()),
    ]);

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
              child: VisibilityDetectorPlante(
            keyStr: 'map_page_visibility_detector',
            onVisibilityChanged: (visible, firstCall) {
              // Workaround for: 'Google Map is blank if the app is
              // minimized and then maximized after some time'
              // (https://github.com/flutter/flutter/issues/40284)
              if (visible && !firstCall) {
                _initMapStyle();
              }
            },
            child: content,
          )),
        ));
  }

  Widget _fabs() {
    return consumer((ref) {
      final modeFabs = _mode.watch(ref).buildFABs() +
          [
            FabMyLocation(
                key: const Key('my_location_fab'), onPressed: _showUser)
          ];
      final fabs = modeFabs
          .map((e) => Padding(
              key: Key('${e.key}_wrapped'),
              padding: const EdgeInsets.only(right: 24, bottom: 24),
              child: e))
          .toList();
      return AnimatedListSimplePlante(children: fabs);
    });
  }

  Future<void> _showUser() async {
    if (!await _ensurePermissions()) {
      return;
    }
    final position = await _model.currentUserPos();
    if (position == null) {
      return;
    }
    await _moveCameraTo(position);
  }

  Future<bool> _ensurePermissions() async {
    final result = await maybeRequestPermission(
        context,
        _permissionsManager,
        PermissionKind.LOCATION,
        context.strings.map_page_location_permission_reasoning_settings,
        context.strings.map_page_location_permission_go_to_settings,
        settingsDialogCancelWhat:
            context.strings.map_page_location_permission_cancel_go_to_settings,
        settingsDialogTitle:
            context.strings.map_page_location_permission_title);
    _locationPermissionObtained.setValue(result);
    return result;
  }

  Widget _progressBar() {
    return consumer((ref) {
      final loading = _model.loading.watch(ref);
      final loadingSuggestions = _model.loadingSuggestions.watch(ref);
      if (loading) {
        return MapPageProgressBar.forLoadingShops(inProgress: true);
      } else if (loadingSuggestions) {
        return MapPageProgressBar.forLoadingProductsSuggestions(
            inProgress: true);
      } else {
        return MapPageProgressBar.stop();
      }
    });
  }

  void _onCameraMove(CameraPosition position) {
    _clusterManager.onCameraMove(position);
    _mode.cachedVal.onCameraMove(position.target.toCoord(), position.zoom);
  }

  void _onCameraIdle() async {
    final mapController = await _mapController.future;
    final viewBounds = await mapController.getVisibleRegion();
    await _model.onCameraIdle(viewBounds.toCoordsBounds());
    _mode.cachedVal.onCameraIdle();
  }

  void _onShopsUpdated(Iterable<Shop> shops) {
    _displayedShops = shops;
    widget.testingStorage.displayedShops.clear();
    widget.testingStorage.displayedShops.addAll(shops);
    _mode.cachedVal.onDisplayedShopsChange(shops);

    _clusterManager.setItems(shops
        .map((shop) =>
            ClusterItem(LatLng(shop.latitude, shop.longitude), item: shop))
        .toList());
    _clusterManager.updateMap();
  }

  void _onError(MapPageModelError error) {
    if (!mounted) {
      return;
    }
    switch (error) {
      case MapPageModelError.NETWORK_ERROR:
        showSnackBar(context.strings.global_network_error, context);
        break;
      case MapPageModelError.OTHER:
        showSnackBar(context.strings.global_something_went_wrong, context);
        break;
    }
  }

  void _updateMarkers(Set<Marker> markers) {
    _displayedShopsMarkers.setValue(markers);
  }

  void _onMapTap(LatLng coord) {
    _mode.cachedVal.onMapClick(coord.toCoord());
  }

  void _onSearchBarTap() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MapSearchPage(initialState: _latestSearchResult.cachedVal)));
    if (result is MapSearchPageResult?) {
      await _onSearchResult(result);
    }
  }

  Future<void> _onSearchResult(MapSearchPageResult? result) async {
    _latestSearchResult.setValue(result);
    if (result == null) {
      return;
    }
    final shops = result.chosenShops;
    final road = result.chosenRoad;
    if (shops != null && shops.isNotEmpty) {
      _mode.cachedVal.deselectShops();
      if (shops.length == 1) {
        await _moveCameraTo(
            CameraPosition(target: shops.first.coord.toLatLng(), zoom: 17));
      } else {
        final coords = shops.map((e) => e.coord);
        await _moveCameraToShowManyCoords(coords);
      }
      _onMarkerClick(shops);
    } else if (road != null) {
      _mode.cachedVal.deselectShops();
      await _moveCameraTo(
          CameraPosition(target: road.coord.toLatLng(), zoom: 17));
    }
  }

  Future<void> _moveCameraToShowManyCoords(Iterable<Coord> coords) async {
    final coordsBounds = outliningRectFor(coords);
    final screenSize = MediaQuery.of(context).size;
    // -2 is so that the markers won't be hidden behind the search
    // bar or the shops cards (the map will be zoomed out a little more
    // than necessary).
    var zoomLevel = boundsZoomLevel(coordsBounds, screenSize) - 2;
    if (zoomLevel < MapPageMode.DEFAULT_MIN_ZOOM) {
      zoomLevel = MapPageMode.DEFAULT_MIN_ZOOM;
    } else if (MapPageMode.DEFAULT_MAX_ZOOM < zoomLevel) {
      zoomLevel = MapPageMode.DEFAULT_MAX_ZOOM;
    }
    final mapController = await _mapController.future;

    // At first let's just zoom out to see if that will be enough in
    // order for any of coords to be visible.
    var currentVisibleRegion = await mapController.getVisibleRegion();
    final newCoord = currentVisibleRegion.toCoordsBounds().center.toLatLng();
    await mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: newCoord, zoom: zoomLevel)));

    // Now let's move the camera to the coords center IF none of them
    // is visible.
    currentVisibleRegion = await mapController.getVisibleRegion();
    if (!coords
        .any((coord) => currentVisibleRegion.contains(coord.toLatLng()))) {
      await mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: coordsBounds.center.toLatLng(), zoom: zoomLevel)));
    }

    // Now let's move the camera to the first coord if still none is visible
    currentVisibleRegion = await mapController.getVisibleRegion();
    if (!coords
        .any((coord) => currentVisibleRegion.contains(coord.toLatLng()))) {
      await mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: coords.first.toLatLng(), zoom: zoomLevel)));
    }
  }

  Future<bool> _onWillPop() async {
    if (_latestSearchResult.cachedVal != null) {
      _onSearchBarTap();
      return false;
    }
    return await _mode.cachedVal.onWillPop();
  }

  void _loadShops() {
    _model.loadShops();
  }
}

extension on LatLng {
  Coord toCoord() => Coord(lat: latitude, lon: longitude);
}

extension on Coord {
  LatLng toLatLng() => LatLng(lat, lon);
}

extension on LatLngBounds {
  CoordsBounds toCoordsBounds() => CoordsBounds(
      southwest: southwest.toCoord(), northeast: northeast.toCoord());
}
