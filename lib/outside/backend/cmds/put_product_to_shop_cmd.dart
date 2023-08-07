import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';

const PUT_PRODUCT_TO_SHOP_CMD = 'put_product_to_shop';

extension BackendExt on Backend {
  Future<Result<None, BackendError>> putProductToShop(
          String barcode, Shop shop, ProductAtShopSource source) =>
      executeCmd(_PutProductToShopCmd(barcode, shop, source));
}

class _PutProductToShopCmd extends BackendCmd<None> {
  final String barcode;
  final Shop shop;
  final ProductAtShopSource source;
  _PutProductToShopCmd(this.barcode, this.shop, this.source);

  @override
  Future<Result<None, BackendError>> execute() async {
    final response = await backendGet('$PUT_PRODUCT_TO_SHOP_CMD/', {
      'barcode': barcode,
      'shopOsmUID': shop.osmUID.toString(),
      'lon': shop.coord.lon.toString(),
      'lat': shop.coord.lat.toString(),
      'source': source.persistentName,
    });
    return noneOrErrorFrom(response);
  }
}
