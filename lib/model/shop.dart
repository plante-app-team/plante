import 'package:built_value/built_value.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';

part 'shop.g.dart';

abstract class Shop implements Built<Shop, ShopBuilder> {
  OsmShop get osmShop;
  BackendShop? get backendShop;

  String get osmId => osmShop.osmId;
  String get name => osmShop.name;
  String? get typeStr => osmShop.type;
  ShopType? get type => typeStr != null ? ShopType.safeValueOf(typeStr!) : null;
  double get latitude => osmShop.latitude;
  double get longitude => osmShop.longitude;
  int get productsCount => backendShop?.productsCount ?? 0;

  factory Shop([void Function(ShopBuilder) updates]) = _$Shop;
  Shop._();
}
