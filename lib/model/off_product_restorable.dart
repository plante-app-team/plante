import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:openfoodfacts/openfoodfacts.dart' as off;

class OffProductRestorable extends RestorableValue<off.Product> {
  final off.Product _defaultValue;

  OffProductRestorable(this._defaultValue);

  @override
  off.Product createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(off.Product? oldValue) {
    notifyListeners();
  }

  @override
  off.Product fromPrimitives(Object? data) {
    if (data != null && data is Map<String, dynamic>) {
      return off.Product.fromJson(data);
    }
    return createDefaultValue();
  }

  @override
  Object toPrimitives() {
    return value.toJson();
  }
}
