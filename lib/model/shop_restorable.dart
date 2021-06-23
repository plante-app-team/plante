import 'package:flutter/widgets.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shop.dart';

class ShopRestorable extends RestorableValue<Shop> {
  final Shop _defaultValue;

  ShopRestorable(this._defaultValue);

  @override
  Shop createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(Shop? oldValue) {
    notifyListeners();
  }

  @override
  Shop fromPrimitives(Object? data) {
    if (data != null && data is Map<dynamic, dynamic>) {
      return Shop.fromJson(data)!;
    }
    Log.w('ShopRestorable could not restore from $data');
    return createDefaultValue();
  }

  @override
  Object toPrimitives() {
    return value.toJson();
  }
}
