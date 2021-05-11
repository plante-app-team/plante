import 'package:flutter/cupertino.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

import 'barcode_scan_page_content_state.dart';

enum BarcodeScanPageSearchResult { OK, ERROR_NETWORK, ERROR_OTHER }

class BarcodeScanPageModel {
  final VoidCallback _onStateChangeCallback;
  final ProductsManager _productsManager;
  final LangCodeHolder _langCodeHolder;

  String? _barcode;
  bool _searching = false;
  Product? _foundProduct;
  String get _langCode => _langCodeHolder.langCode;

  BarcodeScanPageModel(
      this._onStateChangeCallback, this._productsManager, this._langCodeHolder);

  String? get barcode => _barcode;
  bool get searching => _searching;

  void onProductExternalUpdate(Product updatedProduct) {
    _foundProduct = updatedProduct;
    _onStateChangeCallback.call();
  }

  BarcodeScanPageContentState get contentState {
    if (_barcode == null) {
      return BarcodeScanPageContentState.nothingScanned();
    } else if (_searching && _barcode != null) {
      return BarcodeScanPageContentState.searchingProduct(_barcode!);
    } else if (_foundProduct != null &&
        ProductPageWrapper.isProductFilledEnoughForDisplay(_foundProduct!)) {
      return BarcodeScanPageContentState.productFound(
          _foundProduct!, onProductExternalUpdate);
    } else {
      final Product product;
      if (_foundProduct != null) {
        product = _foundProduct!;
      } else {
        product = Product((v) => v.barcode = _barcode!);
      }
      return BarcodeScanPageContentState.productNotFound(
          product, onProductExternalUpdate);
    }
  }

  Future<BarcodeScanPageSearchResult> searchProduct(String barcode) async {
    _barcode = barcode;
    _searching = true;
    _onStateChangeCallback.call();

    final foundProductResult =
        await _productsManager.getProduct(barcode, _langCode);

    final foundProduct = foundProductResult.maybeOk();
    _foundProduct = foundProduct;
    _searching = false;
    _barcode = foundProductResult.isOk ? barcode : null;
    _onStateChangeCallback.call();

    if (foundProductResult.isErr) {
      if (foundProductResult.unwrapErr() ==
          ProductsManagerError.NETWORK_ERROR) {
        return BarcodeScanPageSearchResult.ERROR_NETWORK;
      } else {
        return BarcodeScanPageSearchResult.ERROR_OTHER;
      }
    } else {
      return BarcodeScanPageSearchResult.OK;
    }
  }
}
