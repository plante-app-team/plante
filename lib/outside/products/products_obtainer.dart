import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';

enum ProductsObtainerError {
  NETWORK,
  OTHER,
}

class ProductsObtainer {
  final ProductsManager _productsManager;
  final OffShopsManager _offShopsManager;
  final UserLangsManager _userLangsManager;

  ProductsObtainer(
      this._productsManager, this._offShopsManager, this._userLangsManager);

  Future<Result<Product?, ProductsObtainerError>> getProduct(
      String barcode) async {
    final result =
        await _productsManager.getProduct(barcode, await _userLangs());
    if (result.isErr) {
      return Err(result.unwrapErr().convert());
    }
    return Ok(result.unwrap());
  }

  Future<List<LangCode>> _userLangs() async {
    final userLangs = await _userLangsManager.getUserLangs();
    return userLangs.langs.toList();
  }

  Future<Result<Product?, ProductsObtainerError>> inflate(
      BackendProduct backendProduct) async {
    final result =
        await _productsManager.inflate(backendProduct, await _userLangs());
    if (result.isErr) {
      return Err(result.unwrapErr().convert());
    }
    return Ok(result.unwrap());
  }

  Future<Result<List<Product>, ProductsObtainerError>> getProducts(
      List<String> barcodes) async {
    final result =
        await _productsManager.getProducts(barcodes, await _userLangs());
    if (result.isErr) {
      return Err(result.unwrapErr().convert());
    }
    return Ok(result.unwrap());
  }

  Future<Result<List<Product>, ProductsObtainerError>> inflateProducts(
      List<BackendProduct> backendProducts) async {
    final result = await _productsManager.inflateProducts(
        backendProducts, await _userLangs());
    if (result.isErr) {
      return Err(result.unwrapErr().convert());
    }
    return Ok(result.unwrap());
  }

  Future<Result<List<Product>, ProductsObtainerError>> inflateOffProducts(
      List<off.Product> offProducts) async {
    final result = await _productsManager.inflateOffProducts(
        offProducts, await _userLangs());
    if (result.isErr) {
      return Err(result.unwrapErr().convert());
    }
    return Ok(result.unwrap());
  }

  Future<Result<List<Product>, ProductsObtainerError>> getProductsOfShopsChain(
      String shopsChainName) async {
    final result = await _offShopsManager.fetchVeganProductsForShop(
        shopsChainName, await _userLangs());
    if (result.isErr) {
      return Err(result.unwrapErr().convert());
    }
    return Ok(result.unwrap());
  }
}

extension _ProductsManagerErrorExt on ProductsManagerError {
  ProductsObtainerError convert() {
    switch (this) {
      case ProductsManagerError.NETWORK_ERROR:
        return ProductsObtainerError.NETWORK;
      case ProductsManagerError.OTHER:
        return ProductsObtainerError.OTHER;
    }
  }
}

extension _OffShopsManagerErrorExt on OffShopsManagerError {
  ProductsObtainerError convert() {
    switch (this) {
      case OffShopsManagerError.NETWORK:
        return ProductsObtainerError.NETWORK;
      case OffShopsManagerError.OTHER:
        return ProductsObtainerError.OTHER;
    }
  }
}
