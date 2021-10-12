import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';

part 'off_shop.g.dart';

abstract class OffShop implements Built<OffShop, OffShopBuilder> {
  @BuiltValueField(wireName: 'id')
  String get id;
  @BuiltValueField(wireName: 'name')
  String? get name;
  @BuiltValueField(wireName: 'products')
  int? get products;

  static OffShop? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(OffShop.serializer, json);
  }

  factory OffShop([void Function(OffShopBuilder) updates]) =
  _$OffShop;
  OffShop._();
  static Serializer<OffShop> get serializer => _$offShopSerializer;

}

