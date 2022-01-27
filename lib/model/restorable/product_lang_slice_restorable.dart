import 'package:flutter/widgets.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product_lang_slice.dart';

class ProductLangSliceRestorable extends RestorableValue<ProductLangSlice> {
  final ProductLangSlice _defaultValue;

  ProductLangSliceRestorable(this._defaultValue);

  @override
  ProductLangSlice createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(ProductLangSlice? oldValue) {
    notifyListeners();
  }

  @override
  ProductLangSlice fromPrimitives(Object? data) {
    if (data != null && data is Map<dynamic, dynamic>) {
      return ProductLangSlice.fromJson(data)!;
    }
    Log.w('ProductRestorable could not restore from $data');
    return createDefaultValue();
  }

  @override
  Object toPrimitives() {
    return value.toJson();
  }
}
