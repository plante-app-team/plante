import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/components/animated_list_simple_plante.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/ui_permissions_utils.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/components/animated_mode_widget.dart';
import 'package:plante/ui/map/components/fab_my_location.dart';
import 'package:plante/ui/map/components/map_bottom_hint.dart';
import 'package:plante/ui/map/components/map_hints_list.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/ui/map/map_page_mode_default.dart';
import 'package:plante/ui/map/map_page_model.dart';
import 'package:plante/ui/map/markers_builder.dart';

enum MapPageRequestedMode {
  DEFAULT,
  ADD_PRODUCT,
  SELECT_SHOPS,
}

class MapPage extends StatefulWidget {
  final Product? product;
  final List<Shop> initialSelectedShops;
  final MapPageRequestedMode requestedMode;
  final _testingStorage = _TestingStorage();

  MapPage(
      {Key? key,
      this.product,
      this.initialSelectedShops = const [],
      this.requestedMode = MapPageRequestedMode.DEFAULT,
      GoogleMapController? mapControllerForTesting})
      : super(key: key) {
    if (mapControllerForTesting != null && !isInTests()) {
      throw Exception('MapPage: not in tests (init)');
    }
    _testingStorage.mapControllerForTesting = mapControllerForTesting;
  }

  @override
  _MapPageState createState() => _MapPageState();

  @visibleForTesting
  void finishForTesting<T>(T result) {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (finishForTesting)');
    }
    _testingStorage.finishCallback?.call(result);
  }

  @visibleForTesting
  void onMapIdleForTesting() {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (onMapIdleForTesting)');
    }
    _testingStorage.onMapIdleCallback?.call();
  }

  @visibleForTesting
  void onMarkerClickForTesting(Iterable<Shop> markerShops) {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (onMarkerClickForTesting)');
    }
    _testingStorage.onMarkerClickCallback?.call(markerShops);
  }

  @visibleForTesting
  void onMapClickForTesting(LatLng coords) {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (onMapClickForTesting)');
    }
    _testingStorage.onMapClickCallback?.call(coords);
  }

  @visibleForTesting
  MapPageMode getModeForTesting() {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (getModeForTesting)');
    }
    return _testingStorage.modeCallback!.call();
  }

  @visibleForTesting
  Set<Shop> getDisplayedShopsForTesting() {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (getDisplayedShopsForTesting)');
    }
    return _testingStorage.displayedShops;
  }
}

typedef _TestingFinishCallback = dynamic Function(dynamic result);

class _TestingStorage {
  _TestingFinishCallback? finishCallback;
  VoidCallback? onMapIdleCallback;
  ArgCallback<Iterable<Shop>>? onMarkerClickCallback;
  ArgCallback<LatLng>? onMapClickCallback;
  ResCallback<MapPageMode>? modeCallback;
  final Set<Shop> displayedShops = {};

  GoogleMapController? mapControllerForTesting;
}

class _MapPageState extends PageStatePlante<MapPage>
    with SingleTickerProviderStateMixin {
  static final _instances = <_MapPageState>[];
  final PermissionsManager _permissionsManager;
  late final MapPageModel _model;
  var _modeInited = false;
  late MapPageMode _mode;
  bool _locationPermissionObtained = false;

  final _mapController = Completer<GoogleMapController>();
  var _displayedShopsMarkers = <Marker>{};
  Iterable<Shop> _displayedShops = const [];
  late final ClusterManager _clusterManager;
  Timer? _mapUpdatesTimer;

  final _hintsController = MapHintsListController();
  String? _bottomHint;

  bool get _loading => _model.loading;

  _MapPageState()
      : _permissionsManager = GetIt.I.get<PermissionsManager>(),
        super('MapPage');

  @override
  void initState() {
    super.initState();
    widget._testingStorage.finishCallback = (result) {
      _model.finishWith(context, result);
    };
    widget._testingStorage.onMapIdleCallback = _onCameraIdle;
    widget._testingStorage.onMarkerClickCallback = _onMarkerClick;
    widget._testingStorage.onMapClickCallback = _onMapTap;
    widget._testingStorage.modeCallback = () {
      return _mode;
    };

    final updateCallback = () {
      if (mounted) {
        setState(() {
          // Updated!
        });
      }
    };
    final updateMapCallback = () {
      final allShops = <Shop>{};
      _mode.onShopsUpdated(_model.shopsCache);
      allShops.addAll(_model.shopsCache.values);
      allShops.addAll(_mode.additionalShops());
      _onShopsUpdated(_mode.filter(allShops));
    };
    _model = MapPageModel(
        GetIt.I.get<LocationController>(),
        GetIt.I.get<ShopsManager>(),
        GetIt.I.get<AddressObtainer>(),
        GetIt.I.get<LatestCameraPosStorage>(), (_) {
      updateMapCallback.call();
    }, _onError, updateCallback);

    /// The clustering library levels logic is complicated.
    ///
    /// The manager will have N number of levels, each level is a zoom value
    /// which marks when clustering behaviour should change (whether to cluster
    /// markers into smaller or bigger groups).
    ///
    /// We allow to change map's zoom between 13 and 19 so all levels outside
    /// of those bounds are useless for us.
    /// The useful levels (vals between 13 and 19) in the const list below are
    /// selected by manual testing.
    /// You can adjust them, but only with very careful testing and with
    /// God's help (you'll need it).
    const clusteringLevels = <double>[12, 12, 12, 12, 12, 12, 14, 16.5, 20];
    _clusterManager = ClusterManager<Shop>([], _updateMarkers,
        markerBuilder: _markersBuilder, levels: clusteringLevels);

    final widgetSource = () => widget;
    final contextSource = () => context;
    final displayedShopsSource = () => _displayedShops;
    final updateBottomHintCallback = (String? hint) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bottomHint = hint;
      });
    };
    final moveMapCallback = (Point<double> coords) async {
      final mapController = await _mapController.future;
      await mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(coords.y, coords.x),
              zoom: await mapController.getZoomLevel())));
    };
    final switchModeCallback = (MapPageMode newMode) {
      setState(() {
        analytics.sendEvent('map_page_mode_switch_${newMode.nameForAnalytics}');
        final oldMode = _mode;
        oldMode.deinit();
        _mode = newMode;
        _mode.init(oldMode);
      });
    };
    _mode = MapPageModeDefault(
        analytics,
        _model,
        _hintsController,
        widgetSource,
        contextSource,
        displayedShopsSource,
        updateCallback,
        updateMapCallback,
        updateBottomHintCallback,
        moveMapCallback,
        switchModeCallback);

    _asyncInit();
    _instances.add(this);
    _instances.forEach((instance) {
      instance.onInstancesChange();
    });

    if (widget._testingStorage.mapControllerForTesting != null) {
      _mapController.complete(widget._testingStorage.mapControllerForTesting);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_modeInited) {
      _mode.init(null);
      _modeInited = true;
    }
  }

  Future<Marker> _markersBuilder(Cluster<Shop> cluster) async {
    final extraData =
        ShopsMarkersExtraData(_mode.selectedShops(), _mode.accentedShops());
    return markersBuilder(cluster, extraData, context, _onMarkerClick);
  }

  void _onMarkerClick(Iterable<Shop> shops) {
    if (shops.isEmpty) {
      return;
    }
    analytics.sendEvent(
        'map_shops_click', {'shops': shops.map((e) => e.osmId).join(', ')});
    _mode.onMarkerClick(shops);
  }

  void _asyncInit() async {
    await _initMapStyle();
    final permission =
        await _permissionsManager.status(PermissionKind.LOCATION);
    setState(() {
      _locationPermissionObtained = permission == PermissionState.granted ||
          permission == PermissionState.limited;
    });
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

  Future<void> _moveCameraTo(CameraPosition position) async {
    final mapController = await _mapController.future;
    await mapController.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  @override
  void dispose() {
    _instances.remove(this);
    _instances.forEach((instance) {
      instance.onInstancesChange();
    });
    _model.dispose();
    _mapUpdatesTimer?.cancel();
    () async {
      final mapController = await _mapController.future;
      mapController.dispose();
    }.call();
    super.dispose();
  }

  void onInstancesChange() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(() {
        // Update!
      });
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    var initialPos = _model.initialCameraPosInstant();
    if (initialPos == null) {
      _model.initialCameraPos().then(_moveCameraTo);
      initialPos = _model.defaultUserPos();
    }

    final content = Stack(children: [
      GoogleMap(
        myLocationEnabled: _locationPermissionObtained,
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        minMaxZoomPreference: const MinMaxZoomPreference(13, 19),
        mapType: MapType.normal,
        initialCameraPosition: initialPos,
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
          _clusterManager.setMapController(controller);
          _clusterManager.onCameraMove(initialPos!);
          _onCameraIdle();
        },
        onCameraMove: _clusterManager.onCameraMove,
        onCameraIdle: _onCameraIdle,
        onTap: _onMapTap,
        // When there are more than 2 instances of GoogleMap and both
        // of them have markers, this screws up the markers for some reason.
        // Couldn't figure out why, probably there's a mistake either in
        // the Google Map lib or in the Clustering lib, but it's easier to
        // just use markers for 1 instance at a time.
        markers: _instances.last == this ? _displayedShopsMarkers : {},
      ),
      Align(
          alignment: Alignment.bottomCenter,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                    width: 80,
                    child: AnimatedListSimplePlante(children: _fabs()))),
            MapBottomHint(_bottomHint),
            AnimatedListSimplePlante(
                children: _mode.buildBottomActions(context)),
          ])),
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 44),
            child: Column(children: [
              AnimatedModeWidget(child: _mode.buildHeader(context)),
              MapHintsList(controller: _hintsController),
              AnimatedModeWidget(child: _mode.buildTopActions(context)),
            ])),
      ),
      _mode.buildOverlay(context),
      AnimatedSwitcher(
          duration: DURATION_DEFAULT,
          child: _loading
              ? const LinearProgressIndicator()
              : const SizedBox.shrink()),
    ]);

    return WillPopScope(
        onWillPop: _mode.onWillPop,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
              child: VisibilityDetectorPlante(
            keyStr: 'map_page_visibility_detector',
            onVisibilityChanged: (visible, firstCall) {
              // Workaround for https://trello.com/c/D33qHsGn/
              // (https://github.com/flutter/flutter/issues/40284)
              if (visible && !firstCall) {
                _initMapStyle();
              }
            },
            child: content,
          )),
        ));
  }

  List<Widget> _fabs() {
    final fabs = _mode.buildFABs() +
        [
          FabMyLocation(key: const Key('my_location_fab'), onPressed: _showUser)
        ];
    return fabs
        .map((e) => Padding(
            key: Key('${e.key}_wrapped'),
            padding: const EdgeInsets.only(right: 24, bottom: 24),
            child: e))
        .toList();
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
    setState(() {
      _locationPermissionObtained = result;
    });
    return result;
  }

  void _onCameraIdle() async {
    final mapController = await _mapController.future;
    final viewBounds = await mapController.getVisibleRegion();
    _updateMap(delay: const Duration(milliseconds: 1000));
    await _model.onCameraMoved(viewBounds);
  }

  void _onShopsUpdated(Iterable<Shop> shops) {
    _displayedShops = shops;
    widget._testingStorage.displayedShops.clear();
    widget._testingStorage.displayedShops.addAll(shops);
    _mode.onDisplayedShopsChange(shops);

    _clusterManager.setItems(shops
        .map((shop) =>
            ClusterItem(LatLng(shop.latitude, shop.longitude), item: shop))
        .toList());
    _updateMap(delay: const Duration(seconds: 0));
  }

  void _updateMap({required Duration delay}) async {
    // Too frequent map updates make for terrible performance
    _mapUpdatesTimer?.cancel();
    _mapUpdatesTimer = Timer(delay, _clusterManager.updateMap);
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
    if (mounted) {
      setState(() {
        _displayedShopsMarkers = markers;
      });
    }
  }

  void _onMapTap(LatLng coords) {
    _mode.onMapClick(coords.toPoint());
  }
}

extension _MyLatLngExt on LatLng {
  Point<double> toPoint() => Point(longitude, latitude);
}
