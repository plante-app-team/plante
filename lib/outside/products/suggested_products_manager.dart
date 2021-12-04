import 'package:plante/base/base.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/off/off_shops_manager.dart';

enum SuggestedProductsManagerError {
  NETWORK,
  OTHER,
}

typedef OsmUIDBarcodesMap = Map<OsmUID, List<String>>;
typedef OsmUIDBarcodesPair = Pair<OsmUID, List<String>>;

class SuggestedProductsManager {
  final OffShopsManager _offShopsManager;
  final ProductsAtShopsExtraPropertiesManager _productsExtraProperties;

  SuggestedProductsManager(
      this._offShopsManager, this._productsExtraProperties);

  /// NOTE: function stops data retrieval on first error
  Stream<Result<OsmUIDBarcodesPair, SuggestedProductsManagerError>>
      getSuggestedBarcodes(Iterable<Shop> shops) async* {
    if (!(await enableNewestFeatures())) {
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
    final stream = _offShopsManager.fetchVeganBarcodes(names);
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
        yield Ok(Pair(uid, suggestions.toList()));
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
  Future<Result<OsmUIDBarcodesMap, SuggestedProductsManagerError>>
      getSuggestedBarcodesMap(Iterable<Shop> shops) async {
    final OsmUIDBarcodesMap result = {};
    final stream = getSuggestedBarcodes(shops);
    await for (final pairRes in stream) {
      if (pairRes.isErr) {
        return Err(pairRes.unwrapErr());
      }
      final pair = pairRes.unwrap();
      result[pair.first] ??= [];
      result[pair.first]!.addAll(pair.second);
    }
    return Ok(result);
  }
}
