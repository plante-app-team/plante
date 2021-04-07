import 'package:flutter/material.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/ui/product/display_product_page.dart';
import 'package:untitled_vegan_app/ui/product/init_product_page.dart';

class ProductPageWrapper extends StatefulWidget {
  final Product initialProduct;

  ProductPageWrapper(this.initialProduct);

  @override
  _ProductPageWrapperState createState() => _ProductPageWrapperState(this.initialProduct);
}

class _ProductPageWrapperState extends State<ProductPageWrapper> {
  final Product _initialProduct;

  _ProductPageWrapperState(this._initialProduct);

  @override
  Widget build(BuildContext context) {
    final Widget page;
    if (!_isProductFilledEnough()) {
      page = InitProductPage(_initialProduct, key: Key("init_product_page"));
    } else {
      page = DisplayProductPage(_initialProduct, key: Key("display_product_page"));
    }
    return Container(child: page);
  }

  bool _isProductFilledEnough() => InitProductPage.hasEnoughDataAlready(_initialProduct);
}
