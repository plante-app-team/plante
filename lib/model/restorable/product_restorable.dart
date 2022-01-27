import 'package:flutter/widgets.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';

class ProductRestorable extends RestorableValue<Product> {
  final Product _defaultValue;

  ProductRestorable(this._defaultValue);

  @override
  Product createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(Product? oldValue) {
    notifyListeners();
  }

  @override
  Product fromPrimitives(Object? data) {
    if (data != null && data is Map<dynamic, dynamic>) {
      return Product.fromJson(data)!;
    }
    Log.w('ProductRestorable could not restore from $data');
    return createDefaultValue();
  }

  @override
  Object toPrimitives() {
    return value.toJson();
  }
}
