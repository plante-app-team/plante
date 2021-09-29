import 'dart:async';

import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_nominatim.dart';
import 'package:plante/outside/map/osm_short_address.dart';
import 'package:plante/outside/map/osm_uid.dart';

typedef AddressResult = Result<OsmAddress, OpenStreetMapError>;
typedef FutureAddress = Future<AddressResult>;

typedef ShortAddressResult = Result<OsmShortAddress, OpenStreetMapError>;
typedef FutureShortAddress = Future<ShortAddressResult>;

class AddressObtainer {
  late final OpenStreetMap _osm;
  final _cache = <OsmUID, OsmAddress>{};

  AddressObtainer(this._osm);

  FutureShortAddress addressOfShop(Shop shop) async {
    if (shop.road != null && shop.houseNumber != null) {
      return Ok(OsmShortAddress((e) => e
        ..city = shop.city
        ..road = shop.road
        ..houseNumber = shop.houseNumber));
    }
    final cache = _cache[shop.osmUID];
    if (cache != null) {
      return Ok(cache.toShort());
    }
    final result = await _osm.withNominatim((nominatim) async =>
        await _fetchAddress(
            nominatim, shop.latitude, shop.longitude, shop.osmUID));
    if (result.isOk) {
      return Ok(result.unwrap().toShort());
    } else {
      return Err(result.unwrapErr());
    }
  }

  FutureAddress _fetchAddress(
      OsmNominatim nominatim, double lat, double lon, OsmUID? osmUID) async {
    if (osmUID != null && _cache.containsKey(osmUID)) {
      return Ok(_cache[osmUID]!);
    }
    final result = await nominatim.fetchAddress(lat, lon);
    if (result.isOk && osmUID != null) {
      _cache[osmUID] = result.unwrap();
    }
    return result;
  }

  FutureAddress addressOfCoords(Coord coords) async {
    return await _osm.withNominatim((nominatim) async =>
        await _fetchAddress(nominatim, coords.lat, coords.lon, null));
  }

  FutureShortAddress shortAddressOfCoords(Coord coords) async {
    final result = await addressOfCoords(coords);
    if (result.isOk) {
      return Ok(result.unwrap().toShort());
    } else {
      return Err(result.unwrapErr());
    }
  }
}
