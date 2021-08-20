import 'package:geolocator/geolocator.dart';
import 'package:plante/model/coord.dart';

/// Wrapper around the geolocator lib mainly for testing purposes
class GeolocatorWrapper {
  Future<Coord?> getLastKnownPosition() async =>
      (await Geolocator.getLastKnownPosition())?.toCoord();
  Future<Coord?> getCurrentPosition() async =>
      (await Geolocator.getCurrentPosition()).toCoord();
}

extension MyPositionExt on Position {
  Coord toCoord() => Coord(lat: latitude, lon: longitude);
}
