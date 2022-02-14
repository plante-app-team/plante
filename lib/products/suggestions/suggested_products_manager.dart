import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/products/suggestions/_radius_products_suggestions_manager.dart';
import 'package:plante/products/suggestions/suggested_barcodes_map.dart';
import 'package:plante/products/suggestions/suggested_barcodes_map_full.dart';
import 'package:plante/products/suggestions/suggestion_type.dart';
import 'package:plante/products/suggestions/suggestions_for_shop.dart';

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
  final Settings _settings;

  SuggestedProductsManager(ShopsManager shopsManager, this._offShopsManager,
      this._productsExtraProperties, this._settings,
      {RadiusProductsSuggestionsManager? radiusManager})
      : _radiusSuggestionsManager =
            radiusManager ?? RadiusProductsSuggestionsManager(shopsManager);

  /// NOTE: function stops data retrieval on first error
  ///
  /// See also [getSuggestedBarcodesMap].
  SuggestionsStream getSuggestedBarcodes(
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

  /// NOTE: function stops data retrieval on first error
  SuggestionsStream _getSuggestedBarcodesByRadius(
      Iterable<Shop> shops, Coord center) async* {
    if (await _settings.enableRadiusProductsSuggestions() == false) {
      return;
    }

    final barcodesMap = await _radiusSuggestionsManager
        .getSuggestedBarcodesByRadius(center, shops);
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
  SuggestionsStream _getSuggestedBarcodesByOFF(
      Iterable<Shop> shops, String countryCode) async* {
    if (await _settings.enableOFFProductsSuggestions() == false) {
      return;
    }

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
      getSuggestedBarcodesMap(
          Iterable<Shop> shops, Coord center, String countryCode,
          {Set<SuggestionType>? types}) async {
    final stream =
        getSuggestedBarcodes(shops, center, countryCode, types: types);
    final result = <SuggestionType, SuggestedBarcodesMap>{};

    await for (final suggestionRes in stream) {
      if (suggestionRes.isErr) {
        return Err(suggestionRes.unwrapErr());
      }
      final suggestion = suggestionRes.unwrap();
      result[suggestion.type] ??= SuggestedBarcodesMap({});
      result[suggestion.type]!.add(suggestion.osmUID, suggestion.barcodes);
    }

    return Ok(SuggestedBarcodesMapFull(result));
  }
}
