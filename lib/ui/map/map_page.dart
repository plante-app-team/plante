import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/model/location_controller.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/components/checkbox_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page_model.dart';
import 'package:plante/ui/map/markers_builder.dart';
import 'package:plante/ui/map/shop_product_range_page.dart';
import 'package:plante/ui/map/shops_list_page.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapPageModel _model;

  final _mapController = Completer<GoogleMapController>();
  var _shopsMarkers = <Marker>{};
  late final ClusterManager _clusterManager;
  Timer? _mapUpdatesTimer;

  bool _showEmptyShopsChecked = false;
  bool get _showEmptyShops => _showEmptyShopsChecked;
  set _showEmptyShops(bool value) {
    setState(() {
      _showEmptyShopsChecked = value;
      _onShopsUpdated(_model.shopsCache);
    });
  }

  bool get _loading => _model.loading;

  @override
  void initState() {
    super.initState();
    final updateCallback = () {
      if (mounted) {
        setState(() {
          // Updated!
        });
      }
    };
    _model = MapPageModel(GetIt.I.get<LocationController>(),
        GetIt.I.get<ShopsManager>(), _onShopsUpdated, _onError, updateCallback);

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
    _init();
  }

  Future<Marker> _markersBuilder(Cluster<Shop> cluster) async {
    return markersBuilder(cluster, _onMarkerClick);
  }

  void _onMarkerClick(Iterable<Shop> shops) {
    if (shops.isEmpty) {
      return;
    }
    if (shops.length > 1) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ShopsListPage(shops: shops.toList())));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ShopProductRangePage(shop: shops.first)));
    }
  }

  Future<void> _init() async {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Stack(children: [
        GoogleMap(
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          minMaxZoomPreference: const MinMaxZoomPreference(13, 19),
          mapType: MapType.normal,
          initialCameraPosition:
              _model.lastKnownUserPosInstant() ?? _model.defaultUserPos(),
          onMapCreated: (GoogleMapController controller) {
            _mapController.complete(controller);
            _clusterManager.setMapController(controller);
          },
          onCameraMove: _clusterManager.onCameraMove,
          onCameraIdle: _onCameraIdle,
          markers: _shopsMarkers,
        ),
        AnimatedSwitcher(
            duration: DURATION_DEFAULT,
            child: _loading
                ? const LinearProgressIndicator()
                : const SizedBox.shrink()),
        Align(
            alignment: Alignment.topRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showEmptyShops = !_showEmptyShops;
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(context.strings.map_page_empty_shops,
                      style: TextStyles.normalSmall),
                  CheckboxPlante(
                      value: _showEmptyShops,
                      onChanged: (value) {
                        _showEmptyShops = value ?? false;
                      })
                ]),
              ),
            ))
      ])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUser,
        label: Text(context.strings.map_page_btn_where_am_i),
        icon: const Icon(Icons.person),
      ),
    );
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
    _clusterManager.setItems(shops.values
        .where((shop) => _showEmptyShops ? true : shop.productsCount > 0)
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
}
