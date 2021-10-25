import 'package:plante/base/result.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';

class FakeOffShopsManager implements OffShopsManager {
  final _suggestedBarcodes = <OffShop, List<String>>{};

  void setSuggestedBarcodes(Map<OffShop, List<String>> suggestedBarcodes) {
    _suggestedBarcodes.clear();
    _suggestedBarcodes.addAll(suggestedBarcodes);
  }

  @override
  Future<Result<List<OffShop>, OffShopsManagerError>> fetchOffShops() async {
    return Ok(_suggestedBarcodes.keys.toList());
  }

  @override
  Future<Result<ShopNamesAndBarcodesMap, OffShopsManagerError>>
      fetchVeganBarcodesForShops(
          Set<String> shopsNames, List<LangCode> langs) async {
    final ShopNamesAndBarcodesMap result = {};
    for (final name in shopsNames) {
      for (final shop in _suggestedBarcodes.keys) {
        if (shop.id == OffShop.shopNameToPossibleOffShopID(name)) {
          result[name] = _suggestedBarcodes[shop]!;
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
