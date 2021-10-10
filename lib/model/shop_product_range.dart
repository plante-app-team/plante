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

  bool hasProductWith(String barcode) =>
      products.any((e) => e.barcode == barcode);

  ShopProductRange rebuildWithoutProduct(String barcode) {
    final productsUpdated = products.where((e) => e.barcode != barcode);
    final lastSeenUpdated = productsLastSeenSecsUtc.toMap();
    lastSeenUpdated.remove(barcode);
    return rebuild((e) => e
      ..products = ListBuilder(productsUpdated)
      ..productsLastSeenSecsUtc = MapBuilder(lastSeenUpdated));
  }

  ShopProductRange rebuildWithProduct(Product product, int lastSeenSecsUtc) {
    // At first let's remove the product so that
    // we would be able to update the last seen time.
    final withoutProduct = rebuildWithoutProduct(product.barcode);

    final productsUpdated = withoutProduct.products.toList();
    final lastSeenUpdated = withoutProduct.productsLastSeenSecsUtc.toMap();
    productsUpdated.add(product);
    lastSeenUpdated[product.barcode] = lastSeenSecsUtc;
    return withoutProduct.rebuild((e) => e
      ..products = ListBuilder(productsUpdated)
      ..productsLastSeenSecsUtc = MapBuilder(lastSeenUpdated));
  }

  factory ShopProductRange([void Function(ShopProductRangeBuilder) updates]) =
      _$ShopProductRange;
  ShopProductRange._();
}
