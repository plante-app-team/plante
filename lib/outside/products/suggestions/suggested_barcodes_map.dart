import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

class SuggestedBarcodesMap {
  final Map<OsmUID, List<String>> _map;

  SuggestedBarcodesMap(Map<OsmUID, List<String>> map) : _map = map;

  List<String>? operator [](OsmUID uid) => _map[uid];
  operator []=(OsmUID uid, List<String> barcodes) => _map[uid] = barcodes;

  SuggestedBarcodesMap unmodifiable() {
    final map = <OsmUID, List<String>>{};
    for (final entry in _map.entries) {
      map[entry.key] = UnmodifiableListView(entry.value);
    }
    return SuggestedBarcodesMap(UnmodifiableMapView(map));
  }

  Map<OsmUID, List<String>> asMap() => unmodifiable()._map;

  int suggestionsCountFor(OsmUID osmUID) {
    return this[osmUID]?.length ?? 0;
  }

  void add(OsmUID osmUID, List<String> barcodes) {
    final oldBarcodes = _map[osmUID] ?? [];
    final newBarcodes =
        barcodes.where((barcode) => !oldBarcodes.contains(barcode));
    oldBarcodes.addAll(newBarcodes);
    _map[osmUID] = oldBarcodes;
  }

  /// NOTE: we don't override operator== because the class is
  /// not immutable
  bool equals(SuggestedBarcodesMap other) {
    if (identical(other, this)) {
      return true;
    }
    final otherMap = other._map;
    if (_map.keys.length != otherMap.keys.length) {
      return false;
    }
    for (final key in _map.keys) {
      final list1 = _map[key];
      final list2 = otherMap[key];
      if (list1 == null || list2 == null) {
        return false;
      }
      if (!listEquals(list1, list2)) {
        return false;
      }
    }
    return true;
  }
}
