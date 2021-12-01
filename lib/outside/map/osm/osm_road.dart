import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/coord.dart';

part 'osm_road.g.dart';

abstract class OsmRoad implements Built<OsmRoad, OsmRoadBuilder> {
  String get osmId;
  String get name;

  /// Center latitude
  double get latitude;

  /// Center longitude
  double get longitude;

  Coord get coord => Coord(lat: latitude, lon: longitude);

  static OsmRoad? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(OsmRoad.serializer, json);
  }

  factory OsmRoad([void Function(OsmRoadBuilder) updates]) = _$OsmRoad;
  OsmRoad._();
  static Serializer<OsmRoad> get serializer => _$osmRoadSerializer;
}
