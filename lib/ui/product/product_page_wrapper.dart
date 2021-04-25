import 'package:flutter/material.dart';
import 'package:plante/model/product.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';

typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class ProductPageWrapper extends StatefulWidget {
  final Product initialProduct;
  final ProductUpdatedCallback? productUpdatedCallback;

  ProductPageWrapper(this.initialProduct, {this.productUpdatedCallback});

  @override
  _ProductPageWrapperState createState() => _ProductPageWrapperState(
      this.initialProduct, this.productUpdatedCallback);
}

class _ProductPageWrapperState extends State<ProductPageWrapper> {
  final Product _initialProduct;
  final ProductUpdatedCallback? _productUpdatedCallback;

  _ProductPageWrapperState(this._initialProduct, this._productUpdatedCallback);

  @override
  Widget build(BuildContext context) {
    final Widget page;
    if (!_isProductFilledEnough()) {
      page = InitProductPage(_initialProduct,
          key: Key("init_product_page"),
          productUpdatedCallback: _productUpdatedCallback);
    } else {
      page = DisplayProductPage(_initialProduct,
          key: Key("display_product_page"),
          productUpdatedCallback: _productUpdatedCallback);
    }
    return Container(child: page);
  }

  bool _isProductFilledEnough() =>
      _initialProduct.name != null &&
      _initialProduct.name!.trim().isNotEmpty &&
      _initialProduct.vegetarianStatus != null &&
      _initialProduct.veganStatus != null &&
      _initialProduct.imageFront != null &&
      _initialProduct.imageIngredients != null &&
      _initialProduct.ingredientsText != null &&
      _initialProduct.ingredientsText!.isNotEmpty;
}
