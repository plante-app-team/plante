import 'package:plante/base/result.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';

class FakeOffShopsManager implements OffShopsManager {
  final _suggestedProducts = <OffShop, List<Product>>{};

  void setSuggestedProducts(Map<OffShop, List<Product>> suggestedProducts) {
    _suggestedProducts.clear();
    _suggestedProducts.addAll(suggestedProducts);
  }

  @override
  Future<Result<List<OffShop>, OffShopsManagerError>> fetchOffShops() async {
    return Ok(_suggestedProducts.keys.toList());
  }

  @override
  Future<Result<ShopNamesAndProductsMap, OffShopsManagerError>>
      fetchVeganProductsForShops(
          Set<String> shopsNames, List<LangCode> langs) async {
    final ShopNamesAndProductsMap result = {};
    for (final name in shopsNames) {
      for (final shop in _suggestedProducts.keys) {
        if (shop.id == OffShop.shopNameToPossibleOffShopID(name)) {
          result[name] = _suggestedProducts[shop]!;
        }
      }
    }
    return Ok(result);
  }

  @override
  void dispose() {
    // Nothing to do
  }
}
