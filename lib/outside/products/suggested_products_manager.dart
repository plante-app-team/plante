import 'package:plante/base/base.dart';
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

class SuggestedProductsManager {
  final OffShopsManager _offShopsManager;
  final ProductsAtShopsExtraPropertiesManager _productsExtraProperties;

  SuggestedProductsManager(
      this._offShopsManager, this._productsExtraProperties);

  Future<Result<OsmUIDBarcodesMap, SuggestedProductsManagerError>>
      getSuggestedBarcodesFor(Iterable<Shop> shops) async {
    if (!(await enableNewestFeatures())) {
      return Ok(const {});
    }

    shops = shops.toSet(); // Defensive copy
    final names = shops.map((e) => e.name).toSet();
    final barcodesMapRes =
        await _offShopsManager.fetchVeganBarcodesForShops(names);
    if (barcodesMapRes.isErr) {
      return Err(barcodesMapRes.unwrapErr().convert());
    }
    final offShopsBarcodesMap = barcodesMapRes.unwrap();

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

    // We have a problem - OFF shops manager gives a map of shops names and
    // their products, but we need to return a map of OsmUID and barcodes.
    // Let's solve the problem!
    final OsmUIDBarcodesMap result = {};
    for (final shop in shops) {
      final barcodesForName = offShopsBarcodesMap[shop.name] ?? const [];
      result[shop.osmUID] = barcodesForName;
    }

    // Let's ensure none of the suggestions we return is bad
    final allBadSuggestions =
        await _productsExtraProperties.getBarcodesWithBoolValue(
            ProductAtShopExtraPropertyType.BAD_SUGGESTION, true, result.keys);
    for (final badSuggestionsForShop in allBadSuggestions.entries) {
      final shop = badSuggestionsForShop.key;
      final badBarcodes = badSuggestionsForShop.value;
      if (badBarcodes.isNotEmpty) {
        final barcodesCopy = result[shop]?.toList();
        if (barcodesCopy != null) {
          barcodesCopy.removeWhere(badBarcodes.contains);
          result[shop] = barcodesCopy;
        }
      }
    }

    return Ok(result);
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
