import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/products/suggested_products_manager.dart';

class FakeSuggestedProductsManager implements SuggestedProductsManager {
  final OsmUIDBarcodesMap _suggestions = {};

  void setSuggestionsForShop(OsmUID shopUID, Iterable<String> barcodes) {
    _suggestions[shopUID] = barcodes.toList();
  }

  void clearAllSuggestions() {
    _suggestions.clear();
  }

  @override
  Future<Result<OsmUIDBarcodesMap, SuggestedProductsManagerError>>
      getSuggestedBarcodesMap(Iterable<Shop> shops) async {
    final OsmUIDBarcodesMap result = {};
    for (final shop in shops) {
      final suggestionsForShop = _suggestions[shop.osmUID];
      if (suggestionsForShop != null) {
        result[shop.osmUID] = suggestionsForShop;
      }
    }
    return Ok(result);
  }

  @override
  Stream<Result<OsmUIDBarcodesPair, SuggestedProductsManagerError>>
      getSuggestedBarcodes(Iterable<Shop> shops) async* {
    final mapRes = await getSuggestedBarcodesMap(shops);
    if (mapRes.isErr) {
      yield Err(mapRes.unwrapErr());
      return;
    }
    final map = mapRes.unwrap();
    for (final entry in map.entries) {
      yield Ok(Pair(entry.key, entry.value));
    }
  }
}
