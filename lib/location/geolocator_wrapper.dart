import 'dart:math';

import 'package:geolocator/geolocator.dart';

/// Wrapper around the geolocator lib mainly for testing purposes
class GeolocatorWrapper {
  Future<Point<double>?> getLastKnownPosition() async =>
      (await Geolocator.getLastKnownPosition())?.toPoint();
  Future<Point<double>?> getCurrentPosition() async =>
      (await Geolocator.getCurrentPosition()).toPoint();
}

extension MyPositionExt on Position {
  Point<double> toPoint() => Point(longitude, latitude);
}
