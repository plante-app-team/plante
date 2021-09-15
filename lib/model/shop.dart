import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';

part 'shop.g.dart';

abstract class Shop implements Built<Shop, ShopBuilder> {
  static final Shop empty = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmId = ''
      ..name = ''
      ..latitude = 0
      ..longitude = 0)));

  OsmShop get osmShop;
  BackendShop? get backendShop;

  String get osmId => osmShop.osmId;
  String get name => osmShop.name;
  String? get typeStr => osmShop.type;
  ShopType? get type => typeStr != null ? ShopType.safeValueOf(typeStr!) : null;
  double get latitude => osmShop.latitude;
  double get longitude => osmShop.longitude;
  int get productsCount => backendShop?.productsCount ?? 0;

  Coord get coord => Coord(lat: latitude, lon: longitude);

  String? get city => osmShop.city;
  String? get road => osmShop.road;
  String? get houseNumber => osmShop.houseNumber;

  static Shop? fromJson(Map<dynamic, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(Shop.serializer, json);
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers.serializeWith(serializer, this)!
        as Map<String, dynamic>;
  }

  factory Shop([void Function(ShopBuilder) updates]) = _$Shop;
  Shop._();
  static Serializer<Shop> get serializer => _$shopSerializer;
}
