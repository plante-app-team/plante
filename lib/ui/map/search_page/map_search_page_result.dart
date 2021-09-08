import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm_road.dart';

part 'map_search_page_result.g.dart';

abstract class MapSearchPageResult
    implements Built<MapSearchPageResult, MapSearchPageResultBuilder> {
  Shop? get shop;
  OsmRoad? get road;

  static MapSearchPageResult create(Shop? shop, OsmRoad? road) {
    return MapSearchPageResult((e) {
      if (shop != null) {
        e.shop.replace(shop);
      }
      if (road != null) {
        e.road.replace(road);
      }
    });
  }

  static MapSearchPageResult? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(MapSearchPageResult.serializer, json);
  }

  factory MapSearchPageResult(
          [void Function(MapSearchPageResultBuilder) updates]) =
      _$MapSearchPageResult;
  MapSearchPageResult._();
  static Serializer<MapSearchPageResult> get serializer =>
      _$mapSearchPageResultSerializer;
}
