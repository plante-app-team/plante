import 'dart:math';

import 'package:plante/model/coord.dart';

/// Note: it's very approximate since Earth is all round and complex.
double kmToGrad(double km) {
  return km * 1 / 111;
}

// Taken from https://stackoverflow.com/a/27943
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
