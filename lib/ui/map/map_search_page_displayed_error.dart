import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';

enum MapSearchPageDisplayedError {
  NETWORK,
}

extension OsmErrorExtForMapSearchPage on OpenStreetMapError {
  MapSearchPageDisplayedError? convert() {
    switch (this) {
      case OpenStreetMapError.NETWORK:
        return MapSearchPageDisplayedError.NETWORK;
      case OpenStreetMapError.OTHER:
        return null;
    }
  }
}

extension RoadsErrorExtForMapSearchPage on RoadsManagerError {
  MapSearchPageDisplayedError? convert() {
    switch (this) {
      case RoadsManagerError.NETWORK:
        return MapSearchPageDisplayedError.NETWORK;
      case RoadsManagerError.OTHER:
        return null;
    }
  }
}

extension ShopsErrorExtForMapSearchPage on ShopsManagerError {
  MapSearchPageDisplayedError? convert() {
    switch (this) {
      case ShopsManagerError.NETWORK_ERROR:
        return MapSearchPageDisplayedError.NETWORK;
      case ShopsManagerError.OSM_SERVERS_ERROR:
        return null;
      case ShopsManagerError.OTHER:
        return null;
    }
  }
}
