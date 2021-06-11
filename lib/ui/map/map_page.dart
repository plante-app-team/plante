import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
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
  final _testingFinishCallbackStorage = _TestingFinishCallbackStorage();

  MapPage(
      {Key? key,
      this.product,
      this.initialSelectedShops = const [],
      this.requestedMode = MapPageRequestedMode.DEFAULT})
      : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();

  void finishForTesting<T>(T result) {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests');
    }
    _testingFinishCallbackStorage.finishCallback?.call(result);
  }
}

typedef _TestingFinishCallback = dynamic Function(dynamic result);

class _TestingFinishCallbackStorage {
  _TestingFinishCallback? finishCallback;
}

class _MapPageState extends State<MapPage> {
  static final _instances = <_MapPageState>[];
  late final MapPageModel _model;
  late MapPageMode _mode;

  final _mapController = Completer<GoogleMapController>();
  var _shopsMarkers = <Marker>{};
  late final ClusterManager _clusterManager;
  Timer? _mapUpdatesTimer;

  bool get _loading => _model.loading;

  @override
  void initState() {
    super.initState();
    widget._testingFinishCallbackStorage.finishCallback = (result) {
      _model.finishWith(context, result);
    };

    final updateCallback = () {
      if (mounted) {
        setState(() {
          // Updated!
        });
      }
    };
    _model = MapPageModel(
        GetIt.I.get<LocationController>(),
        GetIt.I.get<PermissionsManager>(),
        GetIt.I.get<ShopsManager>(),
        _onShopsUpdated,
        _onError,
        updateCallback);

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
    final switchModeCallback = (MapPageMode newMode) {
      setState(() {
        final oldMode = _mode;
        _mode = newMode;
        _mode.init(oldMode);
      });
    };
    final updateMapCallback = () {
      final additionalShops = {
        for (var shop in _mode.additionalShops()) shop.osmId: shop
      };
      final allShops = <String, Shop>{};
      allShops.addAll(_model.shopsCache);
      allShops.addAll(additionalShops);
      _onShopsUpdated(allShops);
    };
    _mode = MapPageModeDefault(_model, widgetSource, contextSource,
        updateCallback, updateMapCallback, switchModeCallback);
    _mode.init(null);

    _initAsync();
    _instances.add(this);
    _instances.forEach((instance) {
      instance.onInstancesChange();
    });
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
    _mode.onMarkerClick(shops);
  }

  Future<void> _initAsync() async {
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
    final lastKnownPos = await _model.lastKnownUserPos();
    if (lastKnownPos != null) {
      await _moveCameraTo(lastKnownPos);
    }
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
    super.dispose();
    _model.dispose();
    () async {
      final mapController = await _mapController.future;
      mapController.dispose();
    }.call();
  }

  void onInstancesChange() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(() {
        // Update!
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var initialPos = _model.lastKnownUserPosInstant();
    if (initialPos == null) {
      _model.callWhenUserPosKnown(_moveCameraTo);
      initialPos = _model.defaultUserPos();
    }

    return WillPopScope(
        onWillPop: _mode.onWillPop,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
              child: Stack(children: [
            GoogleMap(
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(13, 19),
              mapType: MapType.normal,
              initialCameraPosition: initialPos,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
                _clusterManager.setMapController(controller);
              },
              onCameraMove: _clusterManager.onCameraMove,
              onCameraIdle: _onCameraIdle,
              onTap: _onMapTap,
              // When there are more than 2 instances of GoogleMap and both
              // of them have markers, this screws up the markers for some reason.
              // Couldn't figure out why, probably there's a mistake either in
              // the Google Map lib or in the Clustering lib, but it's easier to
              // just use markers for 1 instance at a time.
              markers: _instances.last == this ? _shopsMarkers : {},
            ),
            _mode.buildOverlay(context),
            AnimatedSwitcher(
                duration: DURATION_DEFAULT,
                child: _loading
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink()),
          ])),
          floatingActionButton: FloatingActionButton(
            onPressed: _showUser,
            backgroundColor: Colors.white,
            splashColor: ColorsPlante.primaryDisabled,
            child: SizedBox(
                width: 30,
                height: 30,
                child: SvgPicture.asset('assets/my_location.svg')),
          ),
        ));
  }

  Future<void> _showUser() async {
    if (!await _model.ensurePermissions()) {
      return;
    }
    final position = await _model.currentUserPos();
    if (position == null) {
      return;
    }
    await _moveCameraTo(position);
  }

  void _onCameraIdle() async {
    final mapController = await _mapController.future;
    final viewBounds = await mapController.getVisibleRegion();
    _updateMap(delay: const Duration(milliseconds: 1000));
    await _model.onCameraMoved(viewBounds);
  }

  void _onShopsUpdated(Map<String, Shop> shops) {
    _clusterManager.setItems(_mode
        .filter(shops.values)
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
    setState(() {
      _shopsMarkers = markers;
    });
  }

  void _onMapTap(LatLng coords) {
    _mode.onMapClick(coords.toPoint());
  }
}

extension _MyLatLngExt on LatLng {
  Point<double> toPoint() => Point(longitude, latitude);
}
