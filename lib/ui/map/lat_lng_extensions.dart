import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/base/log.dart';

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

  bool containsBounds(LatLngBounds other) {
    if (east < west || other.east < other.west) {
      Log.e('East < west, hello 180 meridian. '
          'You have users either on Fiji or Antarctica, congrats. '
          'Fix this for them. '
          'lhs: $this, rhs: $other');
    }

    final west1 = southwest.longitude;
    final north1 = northeast.latitude;
    final east1 = northeast.longitude;
    final south1 = southwest.latitude;
    final west2 = other.southwest.longitude;
    final north2 = other.northeast.latitude;
    final east2 = other.northeast.longitude;
    final south2 = other.southwest.latitude;

    return west1 <= west2 &&
        east2 <= east1 &&
        north2 <= north1 &&
        south1 <= south2;
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
}
