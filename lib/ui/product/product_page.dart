import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;

class ProductPage extends StatefulWidget {
  final off.Product _product;

  ProductPage(this._product);

  @override
  _ProductPageState createState() => _ProductPageState(_product);
}

class _ProductPageState extends State<ProductPage> {
  final off.Product _product;

  _ProductPageState(this._product);

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
          appBar: AppBar(title: Text('Продукт')),
          body: Container(
            padding: EdgeInsets.only(left: 10, top: 20, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    _product.productName ?? 'No name',
                    style: Theme.of(context).textTheme.headline5),
                if (_product.imgSmallUrl != null) Image.network(_product.imgSmallUrl!),

                SizedBox(height: 20),
                Row(children: [
                  Text('Бренд: ', style: Theme.of(context).textTheme.headline6),
                  Text(_product.brands ?? 'No data'),
                ]),

                Row(children: [
                  Text('Категории: ', style: Theme.of(context).textTheme.headline6),
                  Text(_product.categories ?? 'No data'),
                ]),

                Row(children: [
                  Text('Вегетарианское ли:', style: Theme.of(context).textTheme.headline6),
                  Text(_product.ingredientsAnalysisTags?.vegetarianStatus?.toString() ?? 'No data'),
                ]),
                Row(children: [
                  Text('Веганское ли:', style: Theme.of(context).textTheme.headline6),
                  Text(_product.ingredientsAnalysisTags?.veganStatus?.toString() ?? 'No data'),
                ]),

                SizedBox(height: 20),
                Text('Состав:', style: Theme.of(context).textTheme.headline6),
                Text(_product.ingredientsText ?? 'No ingredients'),
                if (_ingredientsImage() != null) Image.network(_ingredientsImage()!)
              ]),
            )
          );
  }

  String? _ingredientsImage() {
    if (_product.images == null) {
      return null;
    }
    for (final image in _product.images!) {
      if (image.field == off.ImageField.INGREDIENTS
          && image.size == off.ImageSize.DISPLAY) {
        return image.url;
      }
    }
    return null;
  }
}
