import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/ui/map/search_page/map_search_page.dart';
import 'package:plante/ui/map/search_page/map_search_result.dart';

part 'map_search_page_result.g.dart';

/// The final state of [MapSearchPage].
abstract class MapSearchPageResult
    implements Built<MapSearchPageResult, MapSearchPageResultBuilder> {
  Shop? get chosenShop;
  OsmRoad? get chosenRoad;
  BuiltList<Shop> get foundShops;
  BuiltList<OsmRoad> get foundRoads;
  String? get query;
  double? get scrollOffset;

  static MapSearchPageResult create(
      {Shop? chosenShop,
      OsmRoad? chosenRoad,
      MapSearchResult? allFound,
      String? query,
      double? scrollOffset}) {
    return MapSearchPageResult((e) {
      if (chosenShop != null) {
        e.chosenShop.replace(chosenShop);
      }
      if (chosenRoad != null) {
        e.chosenRoad.replace(chosenRoad);
      }
      if (allFound != null) {
        e.foundShops.addAll(allFound.shops ?? []);
        e.foundRoads.addAll(allFound.roads ?? []);
      }
      e.scrollOffset = scrollOffset;
      e.query = query;
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
