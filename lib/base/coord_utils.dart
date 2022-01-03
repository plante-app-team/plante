import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';

/// Note: it's very approximate since Earth is all round and complex.
/// **ALSO** please note that this function and [metersBetween] return
/// **different** results for same physical distance.
double kmToGrad(double km) {
  return km * 1 / 111;
}

// Taken from https://stackoverflow.com/a/27943
/// Note: it's very approximate since Earth is all round and complex.
/// **ALSO** please note that this function and [kmToGrad] return
/// **different** results for same physical distance.
double metersBetween(Coord coord1, Coord coord2) {
  const R = 6371; // Radius of the earth in km
  final dLat = _deg2rad(coord2.lat - coord1.lat); // deg2rad below
  final dLon = _deg2rad(coord2.lon - coord1.lon);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(coord1.lat)) *
          cos(_deg2rad(coord2.lat)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  final d = R * c; // Distance in km
  return d * 1000;
}

double _deg2rad(double deg) {
  return deg * (pi / 180);
}

String distanceMetersToStr(double meters, BuildContext context) {
  if (meters < 1000) {
    return '${meters.round()} ${context.strings.global_meters}';
  } else {
    final distanceKms = meters / 1000;
    return '${distanceKms.toStringAsFixed(1)} ${context.strings.global_kilometers}';
  }
}

CoordsBounds outliningRectFor(Iterable<Coord> coords) {
  if (coords.isEmpty) {
    Log.e('outliningRectFor received empty coords');
    return Coord(lat: 0, lon: 0).makeSquare(1);
  }
  var mostWest = coords.first.lon;
  var mostEast = coords.first.lon;
  var mostNorth = coords.first.lat;
  var mostSouth = coords.first.lat;
  for (final coord in coords) {
    if (coord.lon < mostWest) {
      mostWest = coord.lon;
    }
    if (mostEast < coord.lon) {
      mostEast = coord.lon;
    }
    if (coord.lat < mostSouth) {
      mostSouth = coord.lat;
    }
    if (mostNorth < coord.lat) {
      mostNorth = coord.lat;
    }
  }
  return CoordsBounds(
    southwest: Coord(lat: mostSouth, lon: mostWest),
    northeast: Coord(lat: mostNorth, lon: mostEast),
  );
}

// Stolen from https://stackoverflow.com/a/13274361
double boundsZoomLevel(CoordsBounds bounds, Size mapSize) {
  const WORLD_HEIGHT = 256.0;
  const WORLD_WIDTH = 256.0;
  const ZOOM_MAX = 21.0;

  final latRad = (double lat) {
    final sinVal = sin(lat * pi / 180);
    final radX2 = log((1 + sinVal) / (1 - sinVal)) / 2;
    return max(min(radX2, pi), -pi) / 2;
  };

  final zoom = (double mapPx, double worldPx, double fraction) {
    return (log(mapPx / worldPx / fraction) / ln2).floorToDouble();
  };

  final ne = bounds.northeast;
  final sw = bounds.southwest;

  final latFraction = (latRad(ne.lat) - latRad(sw.lat)) / pi;

  final lngDiff = ne.lon - sw.lon;
  final lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360;

  final latZoom = zoom(mapSize.height, WORLD_HEIGHT, latFraction);
  final lngZoom = zoom(mapSize.width, WORLD_WIDTH, lngFraction);

  return min(min(latZoom, lngZoom), ZOOM_MAX);
}
