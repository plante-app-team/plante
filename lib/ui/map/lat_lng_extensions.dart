import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/model/shop.dart';

extension LatLngBoundsExt on LatLngBounds {
  LatLng get center {
    final latCenter = (northeast.latitude + southwest.latitude) / 2;
    final lngCenter = (northeast.longitude + southwest.longitude) / 2;

    return LatLng(latCenter, lngCenter);
  }

  double get width => (northeast.longitude - southwest.longitude).abs();
  double get height => (northeast.latitude - southwest.latitude).abs();
  double get west => southwest.longitude;
  double get north => northeast.latitude;
  double get east => northeast.longitude;
  double get south => southwest.latitude;

  /// PLEASE NOTE that this function works properly ONLY
  /// with small sized bounds and with bounds pairs
  /// which are close to each other.
  /// If given bounds size is close to half of Earth's length, or bounds
  /// are very far away from each other, weird things might happen.
  /// Concrete examples of weird things are not available as I didn't give
  /// it much of a thought - the function works properly with Plante's use
  /// cases and that makes the function good for the app.
  bool containsBounds(LatLngBounds other) {
    var west1 = southwest.longitude;
    final north1 = northeast.latitude;
    var east1 = northeast.longitude;
    final south1 = southwest.latitude;
    var west2 = other.southwest.longitude;
    final north2 = other.northeast.latitude;
    var east2 = other.northeast.longitude;
    final south2 = other.southwest.latitude;

    if (east < west || other.east < other.west) {
      if (west1 < 0) {
        west1 += 360;
      }
      if (west2 < 0) {
        west2 += 360;
      }
      if (east1 < 0) {
        east1 += 360;
      }
      if (east2 < 0) {
        east2 += 360;
      }
    }

    return west1 <= west2 &&
        east2 <= east1 &&
        north2 <= north1 &&
        south1 <= south2;
  }

  bool containsShop(Shop shop) {
    return contains(LatLng(shop.latitude, shop.longitude));
  }
}

extension LatLngExt on LatLng {
  LatLngBounds makeSquare(double size) {
    final north = latitude + size / 2;
    final south = latitude - size / 2;
    var west = longitude - size / 2;
    if (west < -180) {
      west += 360;
    }
    var east = longitude + size / 2;
    if (180 < east) {
      east -= 360;
    }
    return LatLngBounds(
      northeast: LatLng(north, east),
      southwest: LatLng(south, west),
    );
  }

  Point<double> toPoint() {
    return Point<double>(longitude, latitude);
  }
}
