import 'dart:async';

import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_nominatim.dart';

typedef AddressResult = Result<OsmAddress, OpenStreetMapError>;
typedef FutureAddress = Future<AddressResult>;

class AddressObtainer {
  late final OpenStreetMap _osm;
  final _cache = <String, OsmAddress>{};

  AddressObtainer(this._osm);

  FutureAddress addressOfShop(Shop shop) async {
    if (_cache.containsKey(shop.osmId)) {
      return Ok(_cache[shop.osmId]!);
    }
    return await _osm.withNominatim((nominatim) async => await _fetchAddress(
        nominatim, shop.latitude, shop.longitude, shop.osmId));
  }

  FutureAddress _fetchAddress(
      OsmNominatim nominatim, double lat, double lon, String? osmId) async {
    if (osmId != null && _cache.containsKey(osmId)) {
      return Ok(_cache[osmId]!);
    }
    final result = await nominatim.fetchAddress(lat, lon);
    if (result.isOk && osmId != null) {
      _cache[osmId] = result.unwrap();
    }
    return result;
  }

  FutureAddress addressOfCoords(Coord coords) async {
    return await _osm.withNominatim((nominatim) async =>
        await _fetchAddress(nominatim, coords.lat, coords.lon, null));
  }
}
