import 'package:plante/base/coord_utils.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/shops_manager.dart';

class RadiusProductsSuggestionsManager {
  static const RADIUS_KMS = 50.0;
  final ShopsManager _shopsManager;

  RadiusProductsSuggestionsManager(this._shopsManager);

  Map<Shop, List<String>> getSuggestedBarcodesByRadius(
      Coord center, Iterable<Shop> shops) {
    final goodSquare = center.makeSquare(kmToGrad(RADIUS_KMS));

    final barcodesMap = _shopsManager.getBarcodesCache();
    final shopsMap = _shopsManager.getCachedShopsFor(barcodesMap.keys);
    final shopsBarcodesMap = <Shop, List<String>>{};
    for (final shop in shopsMap.values) {
      final barcodes = barcodesMap[shop.osmUID];
      if (barcodes != null && barcodesMap.isNotEmpty) {
        shopsBarcodesMap[shop] = barcodes;
      }
    }
    shopsBarcodesMap
        .removeWhere((key, value) => !goodSquare.contains(key.coord));

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
    for (final shop in shops) {
      final barcodes = namesBarcodesMap[shop.nameClean];
      if (barcodes != null && barcodes.isNotEmpty) {
        result[shop] = barcodes;
      }
    }
    return result;
  }
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
