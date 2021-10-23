import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/products/suggested_products_manager.dart';

class FakeSuggestedProductsManager implements SuggestedProductsManager {
  @override
  Future<Result<OsmUIDProductsMap, SuggestedProductsManagerError>>
      getSuggestedProductsFor(Iterable<Shop> shops) async {
    return Ok(const {});
  }
}
