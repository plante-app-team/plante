import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggested_barcodes_map.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

abstract class SuggestedProductsModel {
  static const LOADED_BATCH_SIZE = 20;
  final ProductsObtainer _productsObtainer;
  final ProductsAtShopsExtraPropertiesManager _productsExtraProperties;
  final ShopsManager _shopsManager;
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

  SuggestedProductsModel(this._productsObtainer, this._productsExtraProperties,
      this._shopsManager, this._shop, this._updateCallback) {
    load();
  }

  @protected
  Future<Result<SuggestedBarcodesMap, SuggestedProductsManagerError>>
      obtainSuggestedProducts();

  void dispose() {}

  Future<void> load() async {
    await _loadingAction(() async {
      final allSuggestedBarcodesRes = await obtainSuggestedProducts();
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

  Future<Result<ProductPresenceVoteResult, ShopsManagerError>?>
      productPresenceVote(Product product, bool positive) async {
    if (positive) {
      final putRes = await _shopsManager.putProductToShops(
          product, [_shop], ProductAtShopSource.OFF_SUGGESTION);
      if (putRes.isErr) {
        return Err(putRes.unwrapErr());
      }
      _updateCallback.call();
      return Ok(ProductPresenceVoteResult(productDeleted: false));
    } else {
      await _productsExtraProperties.setBoolProperty(
          ProductAtShopExtraPropertyType.BAD_SUGGESTION,
          _shop.osmUID,
          product.barcode,
          true);
      _updateCallback.call();
      return Ok(ProductPresenceVoteResult(productDeleted: true));
    }
  }

  void onProductDeleted(Product product) {
    if (_products.remove(product)) {
      _updateCallback.call();
    }
  }
}
