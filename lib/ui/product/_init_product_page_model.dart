import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_restorable.dart';

typedef ProductBuilderFunction = void Function(ProductBuilder product);
class ProductUpdate {
  final Product product;
  final String? updater;
  ProductUpdate(this.product, this.updater);
}

class InitProductPageModel {
  final ProductRestorable _productRestorable;
  final _ocrNeedsVerification = RestorableBool(false);
  final _ocrAllowed = RestorableBool(true);
  bool _loading = false;

  final _productStreamController = StreamController<ProductUpdate>.broadcast();
  final _loadingStreamController = StreamController<bool>.broadcast();
  bool get loading => _loading;

  Product get product => _productRestorable.value;

  Map<String, RestorableProperty<Object?>> get restorableProperties => {
    "product": _productRestorable,
    "ocr_needs_verification": _ocrNeedsVerification,
    "ocr_allowed": _ocrAllowed
  };

  Stream<ProductUpdate> get productChanges => _productStreamController.stream;
  Stream<bool> get loadingChanges => _loadingStreamController.stream;

  bool get ocrNeedsVerification => _ocrNeedsVerification.value;
  set ocrNeedsVerification(bool val) {
    _ocrNeedsVerification.value = val;
    // Let's notify about the (fake) change so that the UI will update
    _productStreamController.add(ProductUpdate(product, null));
  }

  bool get ocrAllowed => _ocrAllowed.value;
  set ocrAllowed(bool val) {
    _ocrAllowed.value = val;
    // Let's notify about the (fake) change so that the UI will update
    _productStreamController.add(ProductUpdate(product, null));
  }

  InitProductPageModel(Product initialProduct):
      _productRestorable = ProductRestorable(initialProduct);


  void updateProduct({required ProductBuilderFunction fn, String? updater}) {
    final updatedProduct = product.rebuild((builder) => fn.call(builder));
    _productRestorable.value = updatedProduct;
    _productStreamController.add(ProductUpdate(updatedProduct, updater));
  }

  void setProduct(Product newProduct, {String? updater}) {
    _productRestorable.value = newProduct;
    _productStreamController.add(ProductUpdate(newProduct, updater));
  }

  void longAction(dynamic Function() action) async {
    _loading = true;
    _loadingStreamController.add(_loading);
    try {
      await action.call();
    } finally {
      _loading = false;
      _loadingStreamController.add(_loading);
    }
  }
}
