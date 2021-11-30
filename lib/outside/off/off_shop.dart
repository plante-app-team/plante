import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/logging/log.dart';

part 'off_shop.g.dart';

abstract class OffShop implements Built<OffShop, OffShopBuilder> {
  static OffShop empty = OffShop((e) => e
    ..id = ''
    ..country = '');

  @BuiltValueField(wireName: 'id')
  String get id;
  @BuiltValueField(wireName: 'name')
  String? get name;
  @BuiltValueField(wireName: 'products')
  int get productsCount;
  @BuiltValueField(wireName: 'country')
  String get country;

  @BuiltValueHook(initializeBuilder: true)
  static void _setDefaults(OffShopBuilder b) => b.productsCount = 0;

  static OffShop? fromJson(dynamic json, String isoCountryCode) {
    if (json['country'] == null) {
      json['country'] = isoCountryCode;
    } else {
      if (json['country'] != isoCountryCode) {
        Log.e('$isoCountryCode differs from country in json: $json');
      }
    }
    return BuildValueHelper.jsonSerializers
        .deserializeWith(OffShop.serializer, json);
  }

  static String shopNameToPossibleOffShopID(String shopName) =>
      shopName.toLowerCase().trim();

  factory OffShop([void Function(OffShopBuilder) updates]) = _$OffShop;
  OffShop._();
  static Serializer<OffShop> get serializer => _$offShopSerializer;
}
