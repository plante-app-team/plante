import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/outside/backend/backend_shop.dart';

part 'shops_in_bounds_response.g.dart';

abstract class ShopsInBoundsResponse
    implements Built<ShopsInBoundsResponse, ShopsInBoundsResponseBuilder> {
  @BuiltValueField(wireName: 'results')
  BuiltMap<String, BackendShop> get shops;
  @BuiltValueField(wireName: 'barcodes')
  BuiltMap<String, BuiltList<String>> get barcodes;

  static ShopsInBoundsResponse? fromJson(dynamic json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(ShopsInBoundsResponse.serializer, json);
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers.serializeWith(serializer, this)!
        as Map<String, dynamic>;
  }

  factory ShopsInBoundsResponse(
          [void Function(ShopsInBoundsResponseBuilder) updates]) =
      _$ShopsInBoundsResponse;
  ShopsInBoundsResponse._();
  static Serializer<ShopsInBoundsResponse> get serializer =>
      _$shopsInBoundsResponseSerializer;
}
