import 'package:flutter/widgets.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shop.dart';

class ShopsListRestorable extends RestorableValue<List<Shop>> {
  final List<Shop> _defaultValue;

  ShopsListRestorable(this._defaultValue);

  @override
  List<Shop> createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(List<Shop>? oldValue) {
    notifyListeners();
  }

  @override
  List<Shop> fromPrimitives(Object? data) {
    if (data != null && data is List<dynamic>) {
      final shops = <Shop>[];
      for (final item in data) {
        if (item is! Map<dynamic, dynamic>) {
          Log.w(
              'Could not deserialize a shop in ShopsListRestorable (1): $item');
          continue;
        }
        final shop = Shop.fromJson(item);
        if (shop == null) {
          Log.w(
              'Could not deserialize a shop in ShopsListRestorable (2): $item');
          continue;
        }
        shops.add(shop);
      }
      return shops;
    }
    Log.w('ShopsListRestorable could not restore from $data');
    return createDefaultValue();
  }

  @override
  Object toPrimitives() {
    return value.map((e) => e.toJson()).toList();
  }
}
