import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:plante/model/coords_bounds.dart';

@immutable
class OsmCachedTerritory<T> {
  final int id;
  final DateTime whenObtained;
  final CoordsBounds bounds;
  final List<T> entities;
  OsmCachedTerritory(
      int id, DateTime whenObtained, CoordsBounds bounds, List<T> entities)
      : this._(id, whenObtained, bounds, entities.toList(growable: false));

  const OsmCachedTerritory._(
      this.id, this.whenObtained, this.bounds, this.entities);

  OsmCachedTerritory<T> add(T entity) {
    final updatedEntities = entities.toList();
    updatedEntities.add(entity);
    return OsmCachedTerritory<T>._(
        id, whenObtained, bounds, UnmodifiableListView(updatedEntities));
  }

  OsmCachedTerritory<T2> rebuildWith<T2>(List<T2> otherEntities) {
    return OsmCachedTerritory<T2>._(id, whenObtained, bounds, otherEntities);
  }

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
