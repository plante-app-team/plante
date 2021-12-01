import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

part 'backend_products_at_shop.g.dart';

abstract class BackendProductsAtShop
    implements Built<BackendProductsAtShop, BackendProductsAtShopBuilder> {
  @BuiltValueField(wireName: 'shop_osm_uid')
  OsmUID get osmUID;
  @BuiltValueField(wireName: 'products')
  BuiltList<BackendProduct> get products;
  @BuiltValueField(wireName: 'products_last_seen_utc')
  BuiltMap<String, int> get productsLastSeenUtc;

  static BackendProductsAtShop? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(BackendProductsAtShop.serializer, json);
  }

  factory BackendProductsAtShop(
          [void Function(BackendProductsAtShopBuilder) updates]) =
      _$BackendProductsAtShop;
  BackendProductsAtShop._();
  static Serializer<BackendProductsAtShop> get serializer =>
      _$backendProductsAtShopSerializer;
}
