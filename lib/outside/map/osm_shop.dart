import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter/foundation.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/map/osm_element_type.dart';

part 'osm_shop.g.dart';

abstract class OsmShop implements Built<OsmShop, OsmShopBuilder> {
  /// PLEASE NOTE: this ID is not the same thing as the ID in Open Street Map.
  /// [osmUID] is a combination of multiple OSM elements fields to make
  /// the ID of an [OsmShop] unique even among multiple OSM elements types.
  String get osmUID;
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
  OsmShop._() {
    // Slow check, will do only in debug mode
    if (kDebugMode) {
      if (osmUID[1] != ':') {
        throw ArgumentError('OSM UID must include OSM element type');
      }
      // The call to [osmElementTypeFromCode] will throw if the code is invalid
      final typeCode = osmElementTypeFromCode(int.parse(osmUID[0]));
      // random check to ensure [typeCode] is used
      assert(typeCode.persistentCode > 0);
      final actualOsmId = osmUID.substring(2);
      if (actualOsmId.isEmpty) {
        throw ArgumentError('OSM UID must include actual OSM id');
      }
    }
  }
  static Serializer<OsmShop> get serializer => _$osmShopSerializer;
}
