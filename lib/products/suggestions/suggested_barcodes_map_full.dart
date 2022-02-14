import 'dart:collection';

import 'package:plante/base/base.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/products/suggestions/suggested_barcodes_map.dart';
import 'package:plante/products/suggestions/suggestion_type.dart';
import 'package:plante/products/suggestions/suggestions_for_shop.dart';

class SuggestedBarcodesMapFull {
  final Map<SuggestionType, SuggestedBarcodesMap> _map;

  SuggestedBarcodesMapFull(Map<SuggestionType, SuggestedBarcodesMap> map)
      : _map = map;

  SuggestedBarcodesMap? operator [](SuggestionType type) => _map[type];
  operator []=(SuggestionType type, SuggestedBarcodesMap suggestions) =>
      _map[type] = suggestions;

  SuggestedBarcodesMapFull unmodifiable() {
    if (!isInTests()) {
      // Somehow this functions is too slow for the app,
      // so we'll check the map being not modified only in tests.
      return this;
    }
    final map = <SuggestionType, SuggestedBarcodesMap>{};
    for (final entry in _map.entries) {
      map[entry.key] = entry.value.unmodifiable();
    }
    return SuggestedBarcodesMapFull(UnmodifiableMapView(map));
  }

  int suggestionsCountFor(OsmUID osmUID, [SuggestionType? type]) {
    if (type != null) {
      return this[type]?.suggestionsCountFor(osmUID) ?? 0;
    }
    var suggestedProductsCount = 0;
    for (final map in _map.values) {
      suggestedProductsCount += map.suggestionsCountFor(osmUID);
    }
    return suggestedProductsCount;
  }

  void add(SuggestionsForShop suggestions) {
    _map[suggestions.type] ??= SuggestedBarcodesMap({});
    _map[suggestions.type]!.add(suggestions.osmUID, suggestions.barcodes);
  }

  List<SuggestionsForShop> allSuggestions() {
    final result = <SuggestionsForShop>[];
    for (final mapEntry in _map.entries) {
      final type = mapEntry.key;
      final map = mapEntry.value;
      for (final entry in map.asMap().entries) {
        result.add(SuggestionsForShop(
          entry.key,
          type,
          entry.value,
        ));
      }
    }
    return result;
  }

  /// NOTE: we don't override operator== because the class is
  /// not immutable
  bool equals(SuggestedBarcodesMapFull other) {
    if (identical(other, this)) {
      return true;
    }
    final otherMap = other._map;
    if (_map.keys.length != otherMap.keys.length) {
      return false;
    }
    for (final key in _map.keys) {
      final val1 = _map[key];
      final val2 = otherMap[key];
      if (val1 == null || val2 == null) {
        return false;
      }
      if (!val1.equals(val2)) {
        return false;
      }
    }
    return true;
  }
}
