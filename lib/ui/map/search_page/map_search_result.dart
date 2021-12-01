import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_road.dart';

part 'map_search_result.g.dart';

/// All results found by the search mechanism.
abstract class MapSearchResult
    implements Built<MapSearchResult, MapSearchResultBuilder> {
  /// When null then search is still in progress
  BuiltList<Shop>? get shops;

  /// When null then search is still in progress
  BuiltList<OsmRoad>? get roads;

  /// See comments to the fields with same names
  static MapSearchResult create(
      Iterable<Shop>? shops, Iterable<OsmRoad>? roads) {
    return MapSearchResult((e) {
      if (shops != null) {
        e.shops.addAll(shops);
      }
      if (roads != null) {
        e.roads.addAll(roads);
      }
    });
  }

  static MapSearchResult? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(MapSearchResult.serializer, json);
  }

  factory MapSearchResult([void Function(MapSearchResultBuilder) updates]) =
      _$MapSearchResult;
  MapSearchResult._();
  static Serializer<MapSearchResult> get serializer =>
      _$mapSearchResultSerializer;
}
