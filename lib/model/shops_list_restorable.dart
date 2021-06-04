import 'package:flutter/widgets.dart';
import 'package:plante/base/log.dart';
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
    if (data != null && data is List<Map<String, dynamic>>) {
      final shops = <Shop>[];
      for (final item in data) {
        final shop = Shop.fromJson(item);
        if (shop == null) {
          Log.w('Could not deserialize a shop in ShopsListRestorable: $item');
          continue;
        }
        shops.add(shop);
      }
      return shops;
    }
    return createDefaultValue();
  }

  @override
  Object toPrimitives() {
    return value.map((e) => e.toJson());
  }
}
