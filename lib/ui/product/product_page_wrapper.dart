import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';

typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class ProductPageWrapper {
  static int lastShowRequestId = 0;
  static Map<int, ProductUpdatedCallback> updateCallbacks = {};

  static Widget createForTesting(Product product) {
    return _createPageFor(product, null);
  }

  static void show(BuildContext context, Product initialProduct,
      {ProductUpdatedCallback? productUpdatedCallback}) {
    final requestId = ++lastShowRequestId;
    final args = [requestId, initialProduct.toJson()];
    if (productUpdatedCallback != null) {
      updateCallbacks[requestId] = productUpdatedCallback;
    }
    Navigator.restorablePush(context, _routeBuilder, arguments: args);
  }

  static Route<void> _routeBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute<void>(builder: (BuildContext context) {
      final Product product;
      final int requestId;
      final ProductUpdatedCallback? callback;
      if (arguments != null) {
        final args = arguments as List<dynamic>;
        requestId = args[0] as int;
        product =
            Product.fromJson(args[1] as Map<dynamic, dynamic>) ?? Product.empty;
        callback = updateCallbacks.remove(requestId);
        if (callback == null) {
          Log.w('product page is created without a callback, '
              'probably restored');
        }
      } else {
        Log.e('product page is created without arguments');
        requestId = -1;
        product = Product.empty;
        callback = null;
      }

      return _createPageFor(product, callback);
    });
  }

  static Widget _createPageFor(
      Product product, ProductUpdatedCallback? callback) {
    if (!isProductFilledEnoughForDisplay(product)) {
      return InitProductPage(product,
          key: const Key('init_product_page'),
          productUpdatedCallback: callback);
    } else {
      return DisplayProductPage(product,
          key: const Key('display_product_page'),
          productUpdatedCallback: callback);
    }
  }

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
