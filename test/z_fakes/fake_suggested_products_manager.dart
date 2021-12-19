import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/products/suggestions/suggested_barcodes_map.dart';
import 'package:plante/outside/products/suggestions/suggested_barcodes_map_full.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/outside/products/suggestions/suggestions_for_shop.dart';

class FakeSuggestedProductsManager implements SuggestedProductsManager {
  var _suggestions = SuggestedBarcodesMapFull({});

  void setSuggestionsForShop(
      OsmUID shopUID, Iterable<String> barcodes, SuggestionType type) {
    final map = _suggestions[type] ?? SuggestedBarcodesMap({});
    map[shopUID] = barcodes.toList();
    _suggestions[type] = map;
  }

  void clearAllSuggestions() {
    _suggestions = SuggestedBarcodesMapFull({});
  }

  @override
  Stream<Result<SuggestionsForShop, SuggestedProductsManagerError>>
      getAllSuggestedBarcodes(
          Iterable<Shop> shops, Coord center, String countryCode) async* {
    await for (final suggestion
        in getSuggestedBarcodesByRadius(shops, center)) {
      yield suggestion;
      if (suggestion.isErr) {
        return;
      }
    }
    await for (final suggestion
        in getSuggestedBarcodesByOFF(shops, countryCode)) {
      yield suggestion;
      if (suggestion.isErr) {
        return;
      }
    }
  }

  Stream<Result<SuggestionsForShop, SuggestedProductsManagerError>>
      _suggestionsFor(Iterable<Shop> shops, SuggestionType type) async* {
    final uids = shops.map((e) => e.osmUID);
    for (final suggestion in _suggestions.allSuggestions()) {
      if (type == suggestion.type && uids.contains(suggestion.osmUID)) {
        yield Ok(suggestion);
      }
    }
  }

  @override
  Stream<Result<SuggestionsForShop, SuggestedProductsManagerError>>
      getSuggestedBarcodesByOFF(Iterable<Shop> shops, String countryCode) {
    return _suggestionsFor(shops, SuggestionType.OFF);
  }

  @override
  Stream<Result<SuggestionsForShop, SuggestedProductsManagerError>>
      getSuggestedBarcodesByRadius(Iterable<Shop> shops, Coord center) {
    return _suggestionsFor(shops, SuggestionType.RADIUS);
  }
}
