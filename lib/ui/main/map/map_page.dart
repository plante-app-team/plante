import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled_vegan_app/model/location_controller.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _locationController = GetIt.I.get<LocationController>();
  final _mapController = Completer<GoogleMapController>();
  var _initialRealPositionSet = false;

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
  }

  Future<void> _moveCameraTo(CameraPosition position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(position));
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
        minMaxZoomPreference: MinMaxZoomPreference(10, 19),
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition(),
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goHome,
        label: Text("I'm drunk, let's go home!"),
        icon: Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goHome() async {
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
}
