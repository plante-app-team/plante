import 'dart:async';

import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';

typedef AddressResult = Result<OsmAddress, OpenStreetMapError>;
typedef FutureAddress = Future<AddressResult>;

class AddressObtainer implements OpenStreetMapReceiver {
  late final OpenStreetMap _osm;
  final OsmInteractionsQueue _osmQueue;
  final _cache = <String, OsmAddress>{};

  AddressObtainer(OpenStreetMapHolder osmHolder, this._osmQueue) {
    _osm = osmHolder.getOsm(whoAsks: this);
  }

  FutureAddress addressOfShop(Shop shop) async {
    if (_cache.containsKey(shop.osmId)) {
      return Ok(_cache[shop.osmId]!);
    }
    return await _osmQueue.enqueue(
        () => _fetchAddress(shop.latitude, shop.longitude, shop.osmId));
  }

  FutureAddress _fetchAddress(double lat, double lon, String? osmId) async {
    if (osmId != null && _cache.containsKey(osmId)) {
      return Ok(_cache[osmId]!);
    }
    final result = await _osm.fetchAddress(lat, lon);
    if (result.isOk && osmId != null) {
      _cache[osmId] = result.unwrap();
    }
    return result;
  }

  FutureAddress addressOfCoords(Coord coords) async {
    return await _osmQueue
        .enqueue(() => _fetchAddress(coords.lat, coords.lon, null));
  }
}
