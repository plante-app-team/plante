import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/search_page/map_search_page_result.dart';

class MapPageTestingStorage {
  ArgResCallback<dynamic, dynamic>? finishCallback;
  ArgCallback<Pair<Coord, double>>? onMapMoveCallback;
  VoidCallback? onMapIdleCallback;
  ArgCallback<Iterable<Shop>>? onMarkerClickCallback;
  ArgCallback<Coord>? onMapClickCallback;
  ResCallback<MapPageMode>? modeCallback;
  ArgCallback<MapSearchPageResult>? onSearchResultCallback;
  final Set<Shop> displayedShops = {};

  GoogleMapController? mapControllerForTesting;
  bool createMapWidgetForTesting = false;

  void finishForTesting<T>(T result) {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (finishForTesting)');
    }
    finishCallback?.call(result);
  }

  void onMapIdleForTesting() {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (onMapIdleForTesting)');
    }
    onMapIdleCallback?.call();
  }

  void onMapMoveForTesting(Coord coord, double zoom) {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (onMamMoveForTesting)');
    }
    onMapMoveCallback?.call(Pair(coord, zoom));
  }

  void onMarkerClickForTesting(Iterable<Shop> markerShops) {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (onMarkerClickForTesting)');
    }
    onMarkerClickCallback?.call(markerShops);
  }

  void onMapClickForTesting(Coord coords) {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (onMapClickForTesting)');
    }
    onMapClickCallback?.call(coords);
  }

  MapPageMode getModeForTesting() {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (getModeForTesting)');
    }
    return modeCallback!.call();
  }

  Set<Shop> getDisplayedShopsForTesting() {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (getDisplayedShopsForTesting)');
    }
    return displayedShops;
  }

  void onSearchResultsForTesting(MapSearchPageResult searchResult) {
    if (!isInTests()) {
      throw Exception('MapPage: not in tests (onSearchResultsForTesting)');
    }
    return onSearchResultCallback?.call(searchResult);
  }
}

extension MapPageTestingExtensions on MapPage {
  void finishForTesting<T>(T res) => testingStorage.finishForTesting(res);
  void onMapIdleForTesting() => testingStorage.onMapIdleForTesting();
  void onMapMoveForTesting(Coord coord, double zoom) =>
      testingStorage.onMapMoveForTesting(coord, zoom);
  void onMarkerClickForTesting(Iterable<Shop> markerShops) =>
      testingStorage.onMarkerClickForTesting(markerShops);
  void onMapClickForTesting(Coord coords) =>
      testingStorage.onMapClickForTesting(coords);
  MapPageMode getModeForTesting() => testingStorage.getModeForTesting();
  Set<Shop> getDisplayedShopsForTesting() =>
      testingStorage.getDisplayedShopsForTesting();
  void onSearchResultsForTesting(MapSearchPageResult searchResult) =>
      testingStorage.onSearchResultsForTesting(searchResult);
}
