import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/osm_shop.dart';

part 'osm_search_result.g.dart';

abstract class OsmSearchResult
    implements Built<OsmSearchResult, OsmSearchResultBuilder> {
  BuiltList<OsmShop> get shops;
  BuiltList<OsmRoad> get roads;

  static OsmSearchResult? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(OsmSearchResult.serializer, json);
  }

  factory OsmSearchResult([void Function(OsmSearchResultBuilder) updates]) =
      _$OsmSearchResult;
  OsmSearchResult._();
  static Serializer<OsmSearchResult> get serializer =>
      _$osmSearchResultSerializer;
}
