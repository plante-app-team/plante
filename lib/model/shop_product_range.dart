import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';

part 'shop_product_range.g.dart';

abstract class ShopProductRange
    implements Built<ShopProductRange, ShopProductRangeBuilder> {
  Shop get shop;
  BuiltList<Product> get products;
  BuiltMap<String, int> get productsLastSeenSecsUtc;

  int lastSeenSecs(Product product) {
    return productsLastSeenSecsUtc[product.barcode] ?? 0;
  }

  factory ShopProductRange([void Function(ShopProductRangeBuilder) updates]) =
      _$ShopProductRange;
  ShopProductRange._();
}
