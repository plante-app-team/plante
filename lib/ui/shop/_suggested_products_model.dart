import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggested_products_manager.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

class SuggestedProductsModel {
  static const LOADED_BATCH_SIZE = 20;
  final SuggestedProductsManager _suggestedProductsManager;
  final ProductsObtainer _productsObtainer;
  final Shop _shop;
  final VoidCallback _updateCallback;

  bool _loading = false;
  bool _initialLoadingFinished = false;
  List<String>? _barcodes;
  var _products = <Product>[];

  bool get loading => _loading;
  bool get initialLoadFinished => _initialLoadingFinished;
  List<Product> get suggestedProducts => _products
      .where(ProductPageWrapper.isProductFilledEnoughForDisplay)
      .toList();

  SuggestedProductsModel(this._suggestedProductsManager, this._productsObtainer,
      this._shop, this._updateCallback) {
    load();
  }

  void dispose() {}

  Future<void> load() async {
    await _loadingAction(() async {
      final allSuggestedBarcodesRes =
          await _suggestedProductsManager.getSuggestedBarcodesFor([_shop]);
      if (allSuggestedBarcodesRes.isErr) {
        Log.w(
            'Could not load suggested products because: $allSuggestedBarcodesRes');
        _initialLoadingFinished = true;
        return;
      }
      final allSuggestedBarcodes = allSuggestedBarcodesRes.unwrap();
      _barcodes = allSuggestedBarcodes[_shop.osmUID] ?? const [];
      if (_barcodes == null || _barcodes!.isEmpty) {
        _initialLoadingFinished = true;
        return;
      }
      await _loadNextProductsBatch();
      _initialLoadingFinished = true;
    });
  }

  Future<void> _loadingAction(dynamic Function() fn) async {
    _loading = true;
    _updateCallback.call();
    try {
      await fn.call();
    } finally {
      _loading = false;
      _updateCallback.call();
    }
  }

  Future<void> _loadNextProductsBatch() async {
    await _loadingAction(() async {
      final barcodes = _barcodes;
      if (barcodes == null) {
        Log.e('Cannot load next batch because there are not barcodes');
        return;
      }
      final alreadyLoaded = _products.length;
      final howManyLoad =
          min(LOADED_BATCH_SIZE, barcodes.length - alreadyLoaded);
      if (howManyLoad == 0) {
        return;
      }

      final suggestedProductsRes = await _productsObtainer.getProducts(
          barcodes.sublist(alreadyLoaded, alreadyLoaded + howManyLoad));
      if (suggestedProductsRes.isErr) {
        Log.w(
            'Could not load suggested products because: $suggestedProductsRes');
        return;
      }
      _products.addAll(suggestedProductsRes.unwrap());
    });
  }

  void onProductUpdate(Product updatedProduct) {
    final products = suggestedProducts.toList();
    final productToUpdate = products
        .indexWhere((product) => product.barcode == updatedProduct.barcode);
    if (productToUpdate == -1) {
      return;
    }
    products[productToUpdate] = updatedProduct;
    _products = products;
    _updateCallback.call();
  }

  void onProductVisibilityChange(Product product, bool visible) {
    if (_products.isEmpty || loading) {
      return;
    }
    if (_products.last.barcode == product.barcode && visible) {
      _loadNextProductsBatch();
    }
  }
}
