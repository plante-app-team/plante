import 'package:plante/base/result.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';

class FakeOffShopsManager implements OffShopsManager {
  @override
  Future<Result<List<OffShop>, OffShopsManagerError>> fetchOffShops() async {
    return Err(OffShopsManagerError.OTHER);
  }

  @override
  Future<Result<List<Product>, OffShopsManagerError>> fetchVeganProductsForShop(
      String shopName, List<LangCode> langs) async {
    return Err(OffShopsManagerError.OTHER);
  }
}
