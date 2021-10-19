import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/map/off_shops_manager.dart';
import 'package:plante/outside/off/off_shop.dart';

class FakeOffShopsManager implements OffShopsManager {
  @override
  Future<Result<List<OffShop>, OffShopsManagerError>> fetchOffShops() async {
    return Err(OffShopsManagerError.OTHER);
  }

  @override
  Future<Result<List<Product>, OffShopsManagerError>> fetchVeganProductsForShop(
      String shopName) async {
    return Err(OffShopsManagerError.OTHER);
  }
}
