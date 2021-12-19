import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/products/suggestions/_radius_products_suggestions_manager.dart';
import 'package:plante/outside/products/suggestions/suggested_barcodes_map.dart';
import 'package:plante/outside/products/suggestions/suggested_barcodes_map_full.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/outside/products/suggestions/suggestions_for_shop.dart';

enum SuggestedProductsManagerError {
  NETWORK,
  OTHER,
}

typedef SuggestionsStream
    = Stream<Result<SuggestionsForShop, SuggestedProductsManagerError>>;

class SuggestedProductsManager {
  final RadiusProductsSuggestionsManager _radiusSuggestionsManager;
  final OffShopsManager _offShopsManager;
  final ProductsAtShopsExtraPropertiesManager _productsExtraProperties;

  SuggestedProductsManager(ShopsManager shopsManager, this._offShopsManager,
      this._productsExtraProperties,
      {RadiusProductsSuggestionsManager? radiusManager})
      : _radiusSuggestionsManager =
            radiusManager ?? RadiusProductsSuggestionsManager(shopsManager);

  /// NOTE: function stops data retrieval on first error
  SuggestionsStream getAllSuggestedBarcodes(
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

  /// NOTE: function stops data retrieval on first error
  SuggestionsStream getSuggestedBarcodesByRadius(
      Iterable<Shop> shops, Coord center) async* {
    final barcodesMap =
        _radiusSuggestionsManager.getSuggestedBarcodesByRadius(center, shops);
    for (final entry in barcodesMap.entries) {
      final shop = entry.key;
      final barcodes = entry.value;
      final badSuggestions = await _badSuggestionsFor(shop.osmUID);
      final suggestions = barcodes.where((e) => !badSuggestions.contains(e));
      yield Ok(SuggestionsForShop(
          shop.osmUID, SuggestionType.RADIUS, suggestions.toList()));
    }
  }

  /// NOTE: function stops data retrieval on first error
  ///
  /// See also: [getSuggestedBarcodesByOFFMap].
  SuggestionsStream getSuggestedBarcodesByOFF(
      Iterable<Shop> shops, String countryCode) async* {
    // There can be many shops with same name,
    // let's build a map which will let us to work with that.
    final namesUidsMap = <String, List<OsmUID>>{};
    for (final shop in shops) {
      var list = namesUidsMap[shop.name];
      if (list == null) {
        list = <OsmUID>[];
        namesUidsMap[shop.name] = list;
      }
      list.add(shop.osmUID);
    }

    shops = shops.toSet(); // Defensive copy
    final names = shops.map((e) => e.name).toSet();
    final stream = _offShopsManager.fetchVeganBarcodes(names, countryCode);
    await for (final pairRes in stream) {
      if (pairRes.isErr) {
        yield Err(pairRes.unwrapErr().convert());
        return;
      }
      final pair = pairRes.unwrap();
      final uids = namesUidsMap[pair.first] ?? const [];
      for (final uid in uids) {
        final badSuggestions = await _badSuggestionsFor(uid);
        final suggestions =
            pair.second.where((e) => !badSuggestions.contains(e));
        yield Ok(
            SuggestionsForShop(uid, SuggestionType.OFF, suggestions.toList()));
      }
    }
  }

  Future<Iterable<String>> _badSuggestionsFor(OsmUID shopUID) async {
    final map = await _productsExtraProperties.getBarcodesWithBoolValue(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, true, [shopUID]);
    return map[shopUID] ?? const [];
  }
}

extension _OffShopsManagerErrorExt on OffShopsManagerError {
  SuggestedProductsManagerError convert() {
    switch (this) {
      case OffShopsManagerError.NETWORK:
        return SuggestedProductsManagerError.NETWORK;
      case OffShopsManagerError.OTHER:
        return SuggestedProductsManagerError.OTHER;
    }
  }
}

extension SuggestedProductsManagerExt on SuggestedProductsManager {
  Future<Result<SuggestedBarcodesMapFull, SuggestedProductsManagerError>>
      getAllSuggestedBarcodesMap(
          Iterable<Shop> shops, Coord center, String countryCode) async {
    final radMap = await getSuggestedBarcodesByRadiusMap(shops, center);
    if (radMap.isErr) {
      return Err(radMap.unwrapErr());
    }
    final offMap = await getSuggestedBarcodesByOFFMap(shops, countryCode);
    if (offMap.isErr) {
      return Err(offMap.unwrapErr());
    }
    return Ok(SuggestedBarcodesMapFull({
      SuggestionType.RADIUS: radMap.unwrap(),
      SuggestionType.OFF: offMap.unwrap(),
    }));
  }

  Future<Result<SuggestedBarcodesMap, SuggestedProductsManagerError>>
      getSuggestedBarcodesByRadiusMap(
          Iterable<Shop> shops, Coord center) async {
    return await _streamToMap(getSuggestedBarcodesByRadius(shops, center));
  }

  Future<Result<SuggestedBarcodesMap, SuggestedProductsManagerError>>
      getSuggestedBarcodesByOFFMap(
          Iterable<Shop> shops, String countryCode) async {
    return await _streamToMap(getSuggestedBarcodesByOFF(shops, countryCode));
  }

  Future<Result<SuggestedBarcodesMap, SuggestedProductsManagerError>>
      _streamToMap(SuggestionsStream stream) async {
    final SuggestedBarcodesMap result = SuggestedBarcodesMap({});
    await for (final suggestionRes in stream) {
      if (suggestionRes.isErr) {
        return Err(suggestionRes.unwrapErr());
      }
      final suggestion = suggestionRes.unwrap();
      result[suggestion.osmUID] ??= [];
      result[suggestion.osmUID]!.addAll(suggestion.barcodes);
    }
    return Ok(result);
  }
}
