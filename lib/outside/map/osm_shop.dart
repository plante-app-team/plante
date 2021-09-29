import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/map/osm_uid.dart';

part 'osm_shop.g.dart';

abstract class OsmShop implements Built<OsmShop, OsmShopBuilder> {
  OsmUID get osmUID;
  String get name;
  String? get type;

  double get latitude;
  double get longitude;

  String? get city;
  String? get road;
  String? get houseNumber;

  Coord get coord => Coord(lat: latitude, lon: longitude);

  static OsmShop? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(OsmShop.serializer, json);
  }

  factory OsmShop([void Function(OsmShopBuilder) updates]) = _$OsmShop;
  OsmShop._();
  static Serializer<OsmShop> get serializer => _$osmShopSerializer;
}
