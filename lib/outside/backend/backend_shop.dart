import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/outside/backend/backend_product.dart';

part 'backend_shop.g.dart';

abstract class BackendShop implements Built<BackendShop, BackendShopBuilder> {
  @BuiltValueField(wireName: 'shop_osm_id')
  String get osmId;
  @BuiltValueField(wireName: 'products')
  BuiltList<BackendProduct> get products;
  @BuiltValueField(wireName: 'products_last_seen_utc')
  BuiltMap<String, int> get productsLastSeenUtc;

  static BackendShop? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(BackendShop.serializer, json);
  }

  factory BackendShop([void Function(BackendShopBuilder) updates]) =
      _$BackendShop;
  BackendShop._();
  static Serializer<BackendShop> get serializer => _$backendShopSerializer;
}
