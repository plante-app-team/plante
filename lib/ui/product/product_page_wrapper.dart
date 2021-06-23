import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';

typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class ProductPageWrapper {
  static int lastShowRequestId = 0;
  static Map<int, ProductUpdatedCallback> updateCallbacks = {};

  @visibleForTesting
  static Widget createForTesting(Product product) {
    if (!isInTests()) {
      throw Exception('!isInTests()');
    }
    return _createPageFor(product, null, null);
  }

  /// If [shopToAddTo] is used, ENSURE [isProductFilledEnoughForDisplay] == false
  static void show(BuildContext context, Product initialProduct,
      {ProductUpdatedCallback? productUpdatedCallback, Shop? shopToAddTo}) {
    final requestId = ++lastShowRequestId;
    final args = [
      requestId,
      initialProduct.toJson(),
      if (shopToAddTo != null) shopToAddTo.toJson()
    ];
    if (productUpdatedCallback != null) {
      updateCallbacks[requestId] = productUpdatedCallback;
    }
    Navigator.restorablePush(context, _routeBuilder, arguments: args);
  }

  static Route<void> _routeBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute<void>(builder: (BuildContext context) {
      final Product product;
      Shop? shopToAddTo;
      final int requestId;
      final ProductUpdatedCallback? callback;
      if (arguments != null) {
        final args = arguments as List<dynamic>;
        requestId = args[0] as int;
        product =
            Product.fromJson(args[1] as Map<dynamic, dynamic>) ?? Product.empty;
        if (args.length > 2) {
          shopToAddTo = Shop.fromJson(args[2] as Map<dynamic, dynamic>);
        }
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

      return _createPageFor(product, shopToAddTo, callback);
    });
  }

  static Widget _createPageFor(
      Product product, Shop? shopToAddTo, ProductUpdatedCallback? callback) {
    if (!isProductFilledEnoughForDisplay(product)) {
      return InitProductPage(product,
          initialShops: [if (shopToAddTo != null) shopToAddTo],
          key: const Key('init_product_page'),
          productUpdatedCallback: callback);
    } else {
      if (shopToAddTo != null) {
        Log.e('_createPageFor, shopToAddTo != null but product '
            'display is selected. Did you forget to call '
            'isProductFilledEnoughForDisplay before '
            'ProductPageWrapper.show?');
      }
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
      product.imageIngredients != null;
}
