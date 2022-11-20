import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:plante/model/coords_bounds.dart';

/// A pair of latitude and longitude coordinates, stored as degrees.
/// Very similar to the LatLng class from Google libs,
/// **BUT** tails are being cut to certain precision - [lat] and [lon] will
/// have up to [precision] digits after the dot.
/// **AND** if the cut tail is 9 in period (999..), the value is rounded to the
/// next integer (e.g. 1.999 => 2.000).
///
/// Also, this class has some additional methods.
@immutable
class Coord {
  static const _DEFAULT_PRECISION = 10;
  final int precision;
  final double lat;
  final double lon;

  static double _toSmallPrecision(double val, int precision) {
    // val=1.23456, precision=3, factor=1000
    final factor = pow(10, precision);
    final enlarged = val * factor;
    // enlarged=1234.56
    final rounded = enlarged.toInt().toDouble();
    // rounded=1234
    final scaledBack = rounded / factor;
    // scaledBack=1.23400
    // 1.23456=>1.23400

    final minWithGivenPrecision = (1 / factor) * scaledBack.sign;
    // =0.001
    final scaledBackPlusMin = scaledBack + minWithGivenPrecision;
    // 1.23400=>1.23500
    if (scaledBackPlusMin.toInt() != scaledBack.toInt()) {
      // if scaledBack=1.999, scaledBackPlusMin would be 2.000
      return scaledBackPlusMin;
    } else {
      // if scaledBack=1.998, scaledBackPlusMin would be 1.999
      return scaledBack;
    }
  }

  /// Creates a geographical location specified in degrees [lat] and
  /// [lon].
  ///
  /// The latitude is clamped to the inclusive interval from -90.0 to +90.0.
  ///
  /// The longitude is normalized to the half-open interval from -180.0
  /// (inclusive) to +180.0 (exclusive)
  ///
  /// [precision] is used to cut tails of the given [lat] and [lon].
  Coord(
      {required double lat,
      required double lon,
      this.precision = _DEFAULT_PRECISION})
      : lat = _toSmallPrecision(
            lat < -90.0 ? -90.0 : (90.0 < lat ? 90.0 : lat), precision),
        lon = _toSmallPrecision((lon + 180.0) % 360.0 - 180.0, precision);

  static Coord fromPoint(Point<double> point,
      {int precision = _DEFAULT_PRECISION}) {
    return Coord(lat: point.y, lon: point.x, precision: precision);
  }

  static Coord? fromPointNullable(Point<double>? point,
      {int precision = _DEFAULT_PRECISION}) {
    if (point == null) {
      return null;
    }
    return Coord.fromPoint(point, precision: precision);
  }

  Point<double> toPoint() => Point(lon, lat);

  CoordsBounds makeSquare(double size) {
    final north = lat + size / 2;
    final south = lat - size / 2;
    var west = lon - size / 2;
    if (west < -180) {
      west += 360;
    }
    var east = lon + size / 2;
    if (180 < east) {
      east -= 360;
    }
    return CoordsBounds(
      northeast: Coord(lat: north, lon: east),
      southwest: Coord(lat: south, lon: west),
    );
  }

  /// Converts this object to something serializable in JSON.
  Object toJson() {
    return <double>[lat, lon];
  }

  /// Initialize a LatLng from an \[lat, lng\] array.
  static Coord? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    assert(json is List && json.length == 2);
    final list = json as List;
    if (list[0] is! double || list[1] is! double) {
      return null;
    }
    return Coord(lat: list[0] as double, lon: list[1] as double);
  }

  @override
  String toString() => 'Coord($lat, $lon)';

  @override
  bool operator ==(Object other) {
    if (other is! Coord) {
      return false;
    }
    return lat == other.lat && lon == other.lon;
  }

  @override
  int get hashCode => Object.hash(lat, lon);
}
