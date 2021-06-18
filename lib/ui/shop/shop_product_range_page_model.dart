import 'package:flutter/cupertino.dart';
import 'package:plante/base/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/shops_manager.dart';

class ShopProductRangePageModel {
  final ShopsManager _shopsManager;
  final UserParamsController _userParamsController;
  final Backend _backend;

  final Shop _shop;

  final VoidCallback _updateCallback;

  bool _loading = false;
  bool _performingBackendAction = false;
  Result<ShopProductRange, ShopsManagerError>? _shopProductRange;

  bool get loading => _loading;
  bool get performingBackendAction => _performingBackendAction;

  bool get rangeLoaded => _shopProductRange != null && _shopProductRange!.isOk;

  Result<ShopProductRange, ShopsManagerError> get loadedRangeRes =>
      _shopProductRange!;
  ShopProductRange get loadedRange => _shopProductRange!.unwrap();
  List<Product> get loadedProducts =>
      loadedRange.products.toList(growable: false);

  UserParams get user => _userParamsController.cachedUserParams!;

  ShopProductRangePageModel(this._shopsManager, this._userParamsController,
      this._backend, this._shop, this._updateCallback) {
    load();
  }

  int lastSeenSecs(Product product) {
    return loadedRange.lastSeenSecs(product);
  }

  void reload() async {
    await load();
  }

  Future<void> load() async {
    _loading = true;
    _updateCallback.call();
    try {
      _shopProductRange = await _shopsManager.fetchShopProductRange(_shop);
    } catch (e) {
      _shopProductRange = Err(ShopsManagerError.OTHER);
      rethrow;
    } finally {
      _loading = false;
      _updateCallback.call();
    }
  }

  void onProductUpdate(Product updatedProduct) {
    if (!rangeLoaded) {
      Log.w('onProductUpdate: called but we have no products range');
      return;
    }
    final products = loadedProducts.toList();
    final productToUpdate = products
        .indexWhere((product) => product.barcode == updatedProduct.barcode);
    if (productToUpdate == -1) {
      Log.e('onProductUpdate: updated product is not found. '
          'Product: $updatedProduct, all products: $products');
      return;
    }
    products[productToUpdate] = updatedProduct;
    _shopProductRange =
        Ok(loadedRange.rebuild((e) => e.products.replace(products)));
    _updateCallback.call();
  }

  Future<Result<None, BackendError>> productPresenceVote(
      Product product, bool positive) async {
    _performingBackendAction = true;
    _updateCallback.call();
    try {
      final result = await _backend.productPresenceVote(
          product.barcode, _shop.osmId, positive);
      if (result.isOk && positive) {
        _shopProductRange = Ok(loadedRange.rebuild((e) =>
            e.productsLastSeenSecsUtc[product.barcode] =
                DateTime.now().secondsSinceEpoch));
      }
      return result;
    } finally {
      _performingBackendAction = false;
      _updateCallback.call();
    }
  }
}

extension _DateTimeExt on DateTime {
  int get secondsSinceEpoch => (millisecondsSinceEpoch / 1000).round();
}
