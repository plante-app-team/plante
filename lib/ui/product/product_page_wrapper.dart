import 'package:flutter/material.dart';
import 'package:plante/model/product.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';

typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class ProductPageWrapper extends StatefulWidget {
  final Product initialProduct;
  final ProductUpdatedCallback? productUpdatedCallback;

  const ProductPageWrapper(this.initialProduct, {this.productUpdatedCallback});

  @override
  _ProductPageWrapperState createState() =>
      _ProductPageWrapperState(initialProduct, productUpdatedCallback);

  static bool isProductFilledEnoughForDisplay(Product product) =>
      product.name != null &&
      product.name!.trim().isNotEmpty &&
      product.vegetarianStatus != null &&
      product.veganStatus != null &&
      product.imageFront != null &&
      product.imageIngredients != null &&
      product.ingredientsText != null &&
      product.ingredientsText!.isNotEmpty;
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
          key: const Key('init_product_page'),
          productUpdatedCallback: _productUpdatedCallback);
    } else {
      page = DisplayProductPage(_initialProduct,
          key: const Key('display_product_page'),
          productUpdatedCallback: _productUpdatedCallback);
    }
    return Container(child: page);
  }

  bool _isProductFilledEnough() =>
      ProductPageWrapper.isProductFilledEnoughForDisplay(_initialProduct);
}
