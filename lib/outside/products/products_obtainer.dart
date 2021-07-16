import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';

class ProductsObtainer {
  final ProductsManager _productsManager;
  final SysLangCodeHolder _langCodeHolder;

  ProductsObtainer(this._productsManager, this._langCodeHolder);

  Future<Result<Product?, ProductsManagerError>> getProduct(
      String barcode) async {
    return _productsManager.getProduct(barcode, _langCodeHolder.langCode);
  }

  Future<Result<Product?, ProductsManagerError>> inflate(
      BackendProduct backendProduct) async {
    return _productsManager.inflate(backendProduct, _langCodeHolder.langCode);
  }
}
