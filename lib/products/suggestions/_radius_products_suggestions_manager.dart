import 'package:flutter/foundation.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';

class RadiusProductsSuggestionsManager {
  static const RADIUS_KMS = 50.0;
  final ShopsManager _shopsManager;

  RadiusProductsSuggestionsManager(this._shopsManager);

  Future<Map<Shop, List<String>>> getSuggestedBarcodesByRadius(
      Coord center, Iterable<Shop> shops) async {
    final goodSquare = center.makeSquare(kmToGrad(RADIUS_KMS));

    final barcodesMap = await _shopsManager.getBarcodesWithin(goodSquare);
    final shopsMap = await _shopsManager.getCachedShopsFor(barcodesMap.keys);

    return await compute(
        _calculateSuggestions,
        _CalculateSuggestionsArgs(
            targetShops: shops, barcodesMap: barcodesMap, shopsMap: shopsMap));
  }

  static Map<Shop, List<String>> _calculateSuggestions(
      _CalculateSuggestionsArgs args) {
    final targetShops = args.targetShops;
    final barcodesMap = args.barcodesMap;
    final shopsMap = args.shopsMap;

    final shopsBarcodesMap = <Shop, List<String>>{};
    for (final shop in shopsMap.values) {
      final barcodes = barcodesMap[shop.osmUID];
      if (barcodes != null && barcodesMap.isNotEmpty) {
        shopsBarcodesMap[shop] = barcodes;
      }
    }

    final namesBarcodesMap = <String, List<String>>{};
    for (final entry in shopsBarcodesMap.entries) {
      final barcodes = namesBarcodesMap[entry.key.nameClean] ?? [];
      barcodes.addAll(entry.value);
      namesBarcodesMap[entry.key.nameClean] = barcodes;
    }
    for (final barcodes in namesBarcodesMap.values) {
      barcodes.removeDuplicates();
    }

    final Map<Shop, List<String>> result = {};
    for (final shop in targetShops) {
      final barcodes = namesBarcodesMap[shop.nameClean];
      if (barcodes != null && barcodes.isNotEmpty) {
        result[shop] = barcodes;
      }
    }
    return result;
  }
}

class _CalculateSuggestionsArgs {
  final Iterable<Shop> targetShops;
  final Map<OsmUID, List<String>> barcodesMap;
  final Map<OsmUID, Shop> shopsMap;
  _CalculateSuggestionsArgs(
      {required this.targetShops,
      required this.barcodesMap,
      required this.shopsMap});
}

extension on Shop {
  String get nameClean => name.trim().toLowerCase();
}

extension<T> on List<T> {
  void removeDuplicates() {
    final set = <T>{};
    retainWhere(set.add);
  }
}
