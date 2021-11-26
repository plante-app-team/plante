import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/country.dart';

part 'off_shop.g.dart';

abstract class OffShop implements Built<OffShop, OffShopBuilder> {
  static OffShop empty = OffShop((e) => e.id = '');

  @BuiltValueField(wireName: 'id')
  String get id;
  @BuiltValueField(wireName: 'name')
  String? get name;
  @BuiltValueField(wireName: 'products')
  int get productsCount;
  Country? get country;

  @BuiltValueHook(initializeBuilder: true)
  static void _setDefaults(OffShopBuilder b) => b.productsCount = 0;

  static OffShop? fromJson(dynamic json, String? isoCountryCode) {
    OffShop? offShop = BuildValueHelper.jsonSerializers
        .deserializeWith(OffShop.serializer, json);
    if (offShop != null && isoCountryCode != null) {
      offShop = offShop
          .rebuild((p0) => p0..country = Country.valueOf(isoCountryCode));
    }
    return offShop;
  }

  static String shopNameToPossibleOffShopID(String shopName) =>
      shopName.toLowerCase().trim();

  factory OffShop([void Function(OffShopBuilder) updates]) = _$OffShop;
  OffShop._();
  static Serializer<OffShop> get serializer => _$offShopSerializer;
}
