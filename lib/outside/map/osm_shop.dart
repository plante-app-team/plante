import 'package:built_value/built_value.dart';

part 'osm_shop.g.dart';

abstract class OsmShop implements Built<OsmShop, OsmShopBuilder> {
  String get osmId;
  String get name;
  String? get type;
  double get latitude;
  double get longitude;

  factory OsmShop([void Function(OsmShopBuilder) updates]) = _$OsmShop;
  OsmShop._();
}
