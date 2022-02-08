import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';

class ConfirmedProductsModel with ShopsManagerListener {
  final ShopsManager _shopsManager;
  final Shop _shop;
  final VoidCallback _updateCallback;

  Completer<void>? _loading;
  Result<ShopProductRange, ShopsManagerError>? _shopProductRange;
  var _lastSortedConfirmedBarcodes = <String>[];

  bool get loading => _loading != null && !_loading!.isCompleted;

  bool get rangeLoaded => _shopProductRange != null && _shopProductRange!.isOk;

  Result<ShopProductRange, ShopsManagerError>? get loadedRangeRes =>
      _shopProductRange;
  ShopProductRange get loadedRange => _shopProductRange!.unwrap();
  List<Product> get loadedProducts {
    return loadedRange.products
        .where((product) => product.veganStatus != VegStatus.negative)
        .toList();
  }

  ConfirmedProductsModel(this._shopsManager, this._shop, this._updateCallback) {
    _load();
    _shopsManager.addListener(this);
  }

  void dispose() {
    _shopsManager.removeListener(this);
  }

  int lastSeenSecs(Product product) {
    return loadedRange.lastSeenSecs(product);
  }

  void reload() async {
    // Sometimes we're asked to reload while we are already
    // loading - for such cases we want to wait for the others
    // loadings to finish, only then to load ourselves.
    while (_loading != null) {
      await _loading?.future;
    }
    await _load();
  }

  Future<void> _load() async {
    await _loadingAction(() async {
      final oldProducts =
          _shopProductRange?.maybeOk()?.products.toList() ?? const [];
      _shopProductRange = await _shopsManager.fetchShopProductRange(_shop);
      // We want to sort the products by their 'last seen' property.
      //
      // But we reload the products quite often and we don't want to
      // sort them too often - we might reload the products right after
      // the user changed the 'last seen' property! (although currently it
      // shouldn't happen).
      // If we'd sort products each time we reload them, the user would
      // see them jumping around.
      //
      // To do the sorting and to avoid the jumping problem, we do 2 things:
      // 1. When a new set of products is just loaded, we memorize their
      //    barcodes and sort them.
      // 2. When the loaded set of products consists of the same barcodes as
      //    were already loaded, we update existing already loaded products
      //    we newly loaded values.
      if (_shopProductRange!.isOk) {
        final range = _shopProductRange!.unwrap();
        final newProducts = range.products.toList();
        final newBarcodes = newProducts.map((e) => e.barcode).toList();
        newBarcodes.sort();
        final productsSetChanged =
            !listEquals(newBarcodes, _lastSortedConfirmedBarcodes);
        if (productsSetChanged) {
          newProducts.sort(
              (p1, p2) => range.lastSeenSecs(p2) - range.lastSeenSecs(p1));
          _shopProductRange = Ok(loadedRange
              .rebuild((e) => e.products = ListBuilder(newProducts)));
          _lastSortedConfirmedBarcodes = newBarcodes;
        } else {
          final newProductsMap = {
            for (final product in newProducts) product.barcode: product
          };
          for (var index = 0; index < oldProducts.length; ++index) {
            final barcode = oldProducts[index].barcode;
            oldProducts[index] = newProductsMap[barcode]!;
          }
          _shopProductRange = Ok(loadedRange
              .rebuild((e) => e.products = ListBuilder(oldProducts)));
        }
      }
    });
  }

  Future<T> _loadingAction<T>(Future<T> Function() fn) async {
    _loading = Completer();
    _updateCallback.call();
    try {
      return await fn.call();
    } finally {
      _loading?.complete();
      _loading = null;
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
      return;
    }
    products[productToUpdate] = updatedProduct;
    _shopProductRange =
        Ok(loadedRange.rebuild((e) => e.products.replace(products)));
    _updateCallback.call();
  }

  Future<Result<ProductPresenceVoteResult, ShopsManagerError>?>
      productPresenceVote(Product product, bool positive) async {
    if (!loadedProducts.contains(product)) {
      return null;
    }
    return await _loadingAction(() async =>
        await _shopsManager.productPresenceVote(product, _shop, positive));
  }

  @override
  void onLocalShopsChange() {
    reload();
  }

  void onProductDeleted(Product product) {
    // Nothing to do - we depend directly on ShopsManager
    // and represent the state of our shop in it
  }
}
