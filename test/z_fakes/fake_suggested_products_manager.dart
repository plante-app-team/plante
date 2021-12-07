import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/products/suggested_products_manager.dart';

class FakeSuggestedProductsManager implements SuggestedProductsManager {
  final Map<OsmUID, OsmUIDBarcodesPair> _suggestions = {};

  void setSuggestionsForShop(OsmUID shopUID, Iterable<String> barcodes) {
    _suggestions[shopUID] = OsmUIDBarcodesPair(shopUID, barcodes.toList());
  }

  void clearAllSuggestions() {
    _suggestions.clear();
  }

  @override
  Stream<Result<OsmUIDBarcodesPair, SuggestedProductsManagerError>>
      getSuggestedBarcodes(Iterable<Shop> shops, String countryCode) async* {
    for (final shop in shops) {
      final suggestions = _suggestions[shop.osmUID];
      if (suggestions == null) {
        continue;
      }
      yield Ok(suggestions);
    }
  }
}
