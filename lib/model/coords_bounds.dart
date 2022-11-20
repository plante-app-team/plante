import 'package:flutter/cupertino.dart';
import 'package:plante/model/coord.dart';

/// A latitude/longitude aligned rectangle.
///
/// The rectangle conceptually includes all points (lat, lng) where
/// * lat ∈ [`southwest.latitude`, `northeast.latitude`]
/// * lng ∈ [`southwest.longitude`, `northeast.longitude`],
///   if `southwest.longitude` ≤ `northeast.longitude`,
/// * lng ∈ [-180, `northeast.longitude`] ∪ [`southwest.longitude`, 180],
///   if `northeast.longitude` < `southwest.longitude`
///
/// This class is very similar to the LatLngBounds class from Google libs,
/// but has custom ==operator logic and additional methods.
@immutable
class CoordsBounds {
  final Coord northeast;
  final Coord southwest;

  double get width => (northeast.lon - southwest.lon).abs();
  double get height => (northeast.lat - southwest.lat).abs();
  double get west => southwest.lon;
  double get north => northeast.lat;
  double get east => northeast.lon;
  double get south => southwest.lat;

  /// Creates geographical bounding box with the specified corners.
  ///
  /// The latitude of the southwest corner cannot be larger than the
  /// latitude of the northeast corner.
  CoordsBounds({required this.southwest, required this.northeast})
      : assert(southwest.lat <= northeast.lat);

  /// Returns whether this rectangle contains the given [Coord].
  bool contains(Coord point) {
    return _containsLatitude(point.lat) && _containsLongitude(point.lon);
  }

  bool _containsLatitude(double lat) {
    return (southwest.lat <= lat) && (lat <= northeast.lat);
  }

  bool _containsLongitude(double lng) {
    if (southwest.lon <= northeast.lon) {
      return southwest.lon <= lng && lng <= northeast.lon;
    } else {
      return southwest.lon <= lng || lng <= northeast.lon;
    }
  }

  Coord get center {
    final latCenter = (northeast.lat + southwest.lat) / 2;
    final lngCenter = (northeast.lon + southwest.lon) / 2;
    return Coord(lat: latCenter, lon: lngCenter);
  }

  /// PLEASE NOTE that this function works properly ONLY
  /// with small sized bounds and with bounds pairs
  /// which are close to each other.
  /// If given bounds size is close to half of Earth's length, or bounds
  /// are very far away from each other, weird things might happen.
  /// Concrete examples of weird things are not available as I didn't give
  /// it much of a thought - the function works properly with Plante's use
  /// cases and that makes the function good for the app.
  bool containsBounds(CoordsBounds other) {
    var west1 = southwest.lon;
    final north1 = northeast.lat;
    var east1 = northeast.lon;
    final south1 = southwest.lat;
    var west2 = other.southwest.lon;
    final north2 = other.northeast.lat;
    var east2 = other.northeast.lon;
    final south2 = other.southwest.lat;

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

  /// Converts this object to something serializable in JSON.
  Object toJson() {
    return <Object>[southwest.toJson(), northeast.toJson()];
  }

  static CoordsBounds? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    assert(json is List && json.length == 2);
    final list = json as List;
    final southwest = Coord.fromJson(list[0]);
    final northeast = Coord.fromJson(list[1]);
    if (southwest == null || northeast == null) {
      return null;
    }
    return CoordsBounds(
      southwest: southwest,
      northeast: northeast,
    );
  }

  @override
  String toString() {
    return '$CoordsBounds($southwest, $northeast)';
  }

  @override
  bool operator ==(Object other) {
    if (other is! CoordsBounds) {
      return false;
    }
    return other.southwest == southwest && other.northeast == northeast;
  }

  @override
  int get hashCode => Object.hash(southwest, northeast);
}
