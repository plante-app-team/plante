import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:plante/model/coords_bounds.dart';

@immutable
class OsmCachedTerritory<T> {
  final int id;
  final DateTime whenObtained;
  final CoordsBounds bounds;
  final List<T> entities;
  const OsmCachedTerritory(
      this.id, this.whenObtained, this.bounds, this.entities);

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is OsmCachedTerritory &&
        id == other.id &&
        whenObtained == other.whenObtained &&
        bounds == other.bounds &&
        listEquals(entities, other.entities);
  }

  @override
  String toString() {
    return '{ $id, $whenObtained, $bounds, $entities }';
  }
}
