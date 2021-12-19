import 'dart:ui';

import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggested_barcodes_map.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/ui/shop/_suggested_products_model.dart';

class OFFSuggestedProductsModel extends SuggestedProductsModel {
  final SuggestedProductsManager _suggestedProductsManager;
  final Shop _shop;
  final Future<String?> _countryCode;
  OFFSuggestedProductsModel(
      this._suggestedProductsManager,
      ProductsObtainer productsObtainer,
      ProductsAtShopsExtraPropertiesManager productsExtraProperties,
      ShopsManager shopsManager,
      this._countryCode,
      this._shop,
      VoidCallback updateCallback)
      : super(productsObtainer, productsExtraProperties, shopsManager, _shop,
            updateCallback);

  @override
  Future<Result<SuggestedBarcodesMap, SuggestedProductsManagerError>>
      obtainSuggestedProducts() async {
    final countryCode = await _countryCode;
    if (countryCode == null) {
      return Ok(SuggestedBarcodesMap({}));
    }
    return await _suggestedProductsManager
        .getSuggestedBarcodesByOFFMap([_shop], countryCode);
  }
}
