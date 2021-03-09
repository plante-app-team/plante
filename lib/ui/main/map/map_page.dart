import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled_vegan_app/model/location_controller.dart';
import 'package:untitled_vegan_app/model/open_street_map.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _locationController = GetIt.I.get<LocationController>();
  final _osm = GetIt.I.get<OpenStreetMap>();
  final _mapController = Completer<GoogleMapController>();
  var _initialRealPositionSet = false;
  var _supermarketsMarkers = Set<Marker>();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final lastKnownPosition = await _locationController.lastKnownPosition();
    if (lastKnownPosition != null && !_initialRealPositionSet) {
      _moveCameraTo(CameraPosition(
          target: LatLng(
              lastKnownPosition.latitude, lastKnownPosition.longitude),
          zoom: 15));
      _initialRealPositionSet = true;
    }

    _mapController.future.then((mapController) {
      // We'd like to hide all businesses known to Google Maps because
      // we'll how our own list of shops and we don't want 2 lists to conflict.
      final noBusinessesStyle = '''
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
    mapController.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  CameraPosition _initialCameraPosition() {
    final lastKnownPosition = _locationController.lastKnownPositionInstant();
    if (lastKnownPosition != null) {
      _initialRealPositionSet = true;
      return CameraPosition(
        target: LatLng(
          lastKnownPosition.latitude, lastKnownPosition.longitude),
        zoom: 15);
    } else {
      return CameraPosition(
        target: LatLng(44.4192543, 38.2052612),
        zoom: 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        minMaxZoomPreference: MinMaxZoomPreference(13, 19),
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition(),
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
        },
        onCameraIdle: _obtainSupermarketsMarkers,
        markers: _supermarketsMarkers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUser,
        label: Text(context.strings.map_page_btn_where_am_i),
        icon: Icon(Icons.person),
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
    if (position == null) {
      position = await _locationController.currentPosition();
    }
    if (position == null) {
      return;
    }

    await _moveCameraTo(CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15));
  }

  void _obtainSupermarketsMarkers() async {
    final mapController = await _mapController.future;
    final viewBounds = await mapController.getVisibleRegion();

    final supermarkets = await _osm.fetchShops(
      Point(viewBounds.northeast.latitude, viewBounds.northeast.longitude),
      Point(viewBounds.southwest.latitude, viewBounds.southwest.longitude));

    final newMarkers = Set<Marker>();
    for (final supermarket in supermarkets) {
      newMarkers.add(Marker(
        markerId: MarkerId(supermarket.id),
        position: LatLng(supermarket.latitude, supermarket.longitude),
        infoWindow: InfoWindow(
            title: supermarket.name,
            snippet: supermarket.type ?? context.strings.map_page_default_shop_type_name),
      ));
    }

    if (_supermarketsMarkers != newMarkers) {
      setState(() {
        _supermarketsMarkers = newMarkers;
      });
    }
  }
}
