import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
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
      getSuggestedBarcodesFor(Iterable<Shop> shops) async {
    final OsmUIDBarcodesMap result = {};
    for (final shop in shops) {
      final suggestionsForShop = _suggestions[shop.osmUID];
      if (suggestionsForShop != null) {
        result[shop.osmUID] = suggestionsForShop;
      }
    }
    return Ok(result);
  }
}
