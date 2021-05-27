import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plante/model/location_controller.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/ui_utils.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _locationController = GetIt.I.get<LocationController>();
  final _shopsManager = GetIt.I.get<ShopsManager>();
  final _mapController = Completer<GoogleMapController>();
  var _initialRealPositionSet = false;
  var _shopsMarkers = <Marker>{};
  late final ClusterManager _clusterManager;

  @override
  void initState() {
    super.initState();
    _clusterManager = ClusterManager<Shop>(
        [],
        _updateMarkers,
        markerBuilder: _markerBuilder);
    _init();
  }

  Future<void> _init() async {
    final lastKnownPosition = await _locationController.lastKnownPosition();
    if (lastKnownPosition != null && !_initialRealPositionSet) {
      await _moveCameraTo(CameraPosition(
          target:
              LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude),
          zoom: 15));
      _initialRealPositionSet = true;
    }

    await _mapController.future.then((mapController) {
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
      mapController.setMapStyle(noBusinessesStyle);
    });
  }

  Future<void> _moveCameraTo(CameraPosition position) async {
    final mapController = await _mapController.future;
    await mapController.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  CameraPosition _initialCameraPosition() {
    final lastKnownPosition = _locationController.lastKnownPositionInstant();
    if (lastKnownPosition != null) {
      _initialRealPositionSet = true;
      return CameraPosition(
          target:
              LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude),
          zoom: 15);
    } else {
      return const CameraPosition(
          target: LatLng(44.4192543, 38.2052612), zoom: 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        minMaxZoomPreference: const MinMaxZoomPreference(13, 19),
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition(),
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
          _clusterManager.setMapController(controller);
        },
        onCameraMove: _clusterManager.onCameraMove,
        onCameraIdle: _obtainShopsMarkers,
        markers: _shopsMarkers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUser,
        label: Text(context.strings.map_page_btn_where_am_i),
        icon: const Icon(Icons.person),
      ),
    );
  }

  Future<void> _showUser() async {
    if (!await _locationController.permissionStatus().isGranted) {
      final status = await _locationController.requestPermission();
      if (!status.isGranted && !status.isLimited) {
        // TODO(https://trello.com/c/662nLdKd/): properly handle all possible statuses
        return;
      }
    }

    var position = await _locationController.lastKnownPosition();
    position ??= await _locationController.currentPosition();
    if (position == null) {
      return;
    }

    await _moveCameraTo(CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 15));
  }

  void _obtainShopsMarkers() async {
    final mapController = await _mapController.future;
    final viewBounds = await mapController.getVisibleRegion();

    final shopsResult = await _shopsManager.fetchShops(
        Point(viewBounds.northeast.latitude, viewBounds.northeast.longitude),
        Point(viewBounds.southwest.latitude, viewBounds.southwest.longitude));
    if (shopsResult.isErr) {
      if (shopsResult.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
        showSnackBar(context.strings.global_network_error, context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
      setState(() {
        _shopsMarkers = {};
      });
      return;
    }
    final shops = shopsResult.unwrap();

    _clusterManager.setItems(shops.map((shop) =>
        ClusterItem(LatLng(shop.latitude, shop.longitude), item: shop))
        .toList());
    _clusterManager.updateMap();
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _shopsMarkers = markers;
    });
  }


  Future<Marker> Function(Cluster<Shop>) get _markerBuilder =>
          (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            print('---- $cluster');
            cluster.items.forEach(print);
          },
          icon: await _getMarkerBitmap(cluster.items
                  .where((element) => element != null)
                  .map((e) => e!)),
        );
      };

  Future<BitmapDescriptor> _getMarkerBitmap(Iterable<Shop> shops) async {
    const size = 125;
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Color paint1Color;
    if (shops.any((e) => e.productsCount > 0)) {
      paint1Color = Colors.orange;
    } else {
      paint1Color = Colors.grey;
    }
    final Paint paint1 = Paint()..color = paint1Color;
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.8, paint1);

    if (shops.length > 1) {
      final painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: shops.length.toString(),
        style: const TextStyle(
            fontSize: size / 3,
            color: Colors.white,
            fontWeight: FontWeight.normal),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
