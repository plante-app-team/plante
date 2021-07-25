import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';

class ProductsObtainer {
  final ProductsManager _productsManager;
  final UserLangsManager _userLangsManager;

  ProductsObtainer(this._productsManager, this._userLangsManager);

  Future<Result<Product?, ProductsManagerError>> getProduct(
      String barcode) async {
    return _productsManager.getProduct(barcode, await _userLangs());
  }

  Future<List<LangCode>> _userLangs() async {
    final userLangs = await _userLangsManager.getUserLangs();
    return userLangs.langs.toList();
  }

  Future<Result<Product?, ProductsManagerError>> inflate(
      BackendProduct backendProduct) async {
    return _productsManager.inflate(backendProduct, await _userLangs());
  }
}
