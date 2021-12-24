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
      getSuggestedBarcodes(
          Iterable<Shop> shops, Coord center, String countryCode,
          {Set<SuggestionType>? types}) async* {
    if (types == null || types.contains(SuggestionType.RADIUS)) {
      final suggestions = _getSuggestedBarcodesByRadius(shops, center);
      await for (final suggestion in suggestions) {
        yield suggestion;
        if (suggestion.isErr) {
          return;
        }
      }
    }
    if (types == null || types.contains(SuggestionType.OFF)) {
      final suggestions = _getSuggestedBarcodesByOFF(shops, countryCode);
      await for (final suggestion in suggestions) {
        yield suggestion;
        if (suggestion.isErr) {
          return;
        }
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

  Stream<Result<SuggestionsForShop, SuggestedProductsManagerError>>
      _getSuggestedBarcodesByOFF(Iterable<Shop> shops, String countryCode) {
    return _suggestionsFor(shops, SuggestionType.OFF);
  }

  Stream<Result<SuggestionsForShop, SuggestedProductsManagerError>>
      _getSuggestedBarcodesByRadius(Iterable<Shop> shops, Coord center) {
    return _suggestionsFor(shops, SuggestionType.RADIUS);
  }
}
