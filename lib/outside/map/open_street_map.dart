import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';

// We use LinkedHashMap because order is important, so:
// ignore_for_file: prefer_collection_literals

enum OpenStreetMapError { NETWORK, OTHER }

/// A wrapper around Open Street Map APIs.
///
/// PLEASE NOTE that this class shouldn't be used directly by app's logic,
/// because all of the OSM APIs have rate limits and will ban the device
/// (or the app) if it sends too many requests.
/// Instead, wrappers for certain purposes should be created.
///
/// Also see [ShopsManager] as a good example a wrapper - not only does it
/// limit requests to 1 per 3 seconds, it also caches requests results.
class OpenStreetMap {
  final HttpClient _http;
  final Analytics _analytics;

  /// We use LinkedHashMap because order is important
  final _osmOverpassUrls = LinkedHashMap<String, String>();

  Map<String, String> get osmOverpassUrls => MapView(_osmOverpassUrls);

  OpenStreetMap(this._http, this._analytics) {
    _osmOverpassUrls['lz4'] = 'lz4.overpass-api.de';
    _osmOverpassUrls['z'] = 'z.overpass-api.de';
    _osmOverpassUrls['kumi'] = 'overpass.kumi.systems';
    _osmOverpassUrls['taiwan'] = 'overpass.nchc.org.tw';
  }

  Future<Result<List<OsmShop>, OpenStreetMapError>> fetchShops(
      CoordsBounds bounds) async {
    final val1 = bounds.southwest.lat;
    final val2 = bounds.southwest.lon;
    final val3 = bounds.northeast.lat;
    final val4 = bounds.northeast.lon;
    final typesStr = ShopType.values.map((type) => type.osmName).join('|');
    final cmd = '[out:json];('
        'node[shop~"$typesStr"]($val1,$val2,$val3,$val4);'
        'relation[shop~"$typesStr"]($val1,$val2,$val3,$val4);'
        'way[shop~"$typesStr"]($val1,$val2,$val3,$val4);'
        ');out center;';

    final response = await _sendCmd(cmd);
    if (response.isErr) {
      return Err(response.unwrapErr());
    }

    final shopsJson = _jsonDecodeSafe(response.unwrap());
    if (shopsJson == null) {
      return Err(OpenStreetMapError.OTHER);
    }
    if (!shopsJson.containsKey('elements')) {
      Log.w("OSM.fetchShops: doesn't have 'elements'. JSON: $shopsJson");
      return Err(OpenStreetMapError.OTHER);
    }

    final result = <OsmShop>[];
    for (final shopJson in shopsJson['elements']) {
      final shopType = shopJson['tags']?['shop'] as String?;
      final shopName = shopJson['tags']?['name'] as String?;
      if (shopName == null) {
        continue;
      }

      final id = shopJson['id']?.toString();
      final double? lat;
      final double? lon;
      final center = shopJson['center'] as Map<dynamic, dynamic>?;
      if (center != null) {
        lat = center['lat'] as double?;
        lon = center['lon'] as double?;
      } else {
        lat = shopJson['lat'] as double?;
        lon = shopJson['lon'] as double?;
      }

      if (id == null || lat == null || lon == null) {
        continue;
      }

      result.add(OsmShop((e) => e
        ..osmId = id
        ..name = shopName
        ..type = shopType
        ..latitude = lat
        ..longitude = lon));
    }
    return Ok(result);
  }

  Future<Result<String, OpenStreetMapError>> _sendCmd(String cmd) async {
    for (final nameAndUrl in _osmOverpassUrls.entries) {
      final urlName = nameAndUrl.key;
      final url = nameAndUrl.value;
      final Response r;
      try {
        r = await _http.get(Uri.https(url, 'api/interpreter', {'data': cmd}),
            headers: {'User-Agent': await userAgent()});
      } on IOException catch (e) {
        Log.w('OSM overpass network error', ex: e);
        return Err(OpenStreetMapError.NETWORK);
      }

      if (r.statusCode != 200) {
        Log.w('OSM._sendCmd: $cmd, status: ${r.statusCode}, body: ${r.body}');
        if (r.statusCode == 403) {
          _analytics.sendEvent('osm_${urlName}_failure_403');
        } else if (r.statusCode == 429) {
          _analytics.sendEvent('osm_${urlName}_failure_429');
        }
        continue;
      }

      Log.i('OSM._sendCmd success: $cmd');
      return Ok(utf8.decode(r.bodyBytes));
    }

    return Err(OpenStreetMapError.OTHER);
  }

  Future<Result<List<OsmRoad>, OpenStreetMapError>> fetchRoads(
      CoordsBounds bounds) async {
    final val1 = bounds.southwest.lat;
    final val2 = bounds.southwest.lon;
    final val3 = bounds.northeast.lat;
    final val4 = bounds.northeast.lon;
    final cmd =
        '[out:json];(way($val1,$val2,$val3,$val4)[highway][name];);out center;';

    final response = await _sendCmd(cmd);
    if (response.isErr) {
      return Err(response.unwrapErr());
    }

    final result = await compute(_parseRoads, response.unwrap());
    if (result.isOk) {
      return Ok(result.unwrap());
    } else {
      Log.w('OSM.fetchRoads: parse roads isolate error: $result');
      return Err(OpenStreetMapError.OTHER);
    }
  }

  Future<Result<OsmAddress, OpenStreetMapError>> fetchAddress(
      double lat, double lon) async {
    final Response r;
    try {
      r = await _http.get(
          Uri.https('nominatim.openstreetmap.org', 'reverse', {
            'lat': lat.toString(),
            'lon': lon.toString(),
            'format': 'json',
          }),
          headers: {'User-Agent': await userAgent()});
    } on IOException catch (e) {
      Log.w('OSM nominatim network error', ex: e);
      return Err(OpenStreetMapError.NETWORK);
    }

    if (r.statusCode != 200) {
      Log.w('OSM.fetchAddress: ${r.statusCode}, body: ${r.body}');
      return Err(OpenStreetMapError.OTHER);
    }

    final json = _jsonDecodeSafe(utf8.decode(r.bodyBytes));
    if (json == null) {
      return Err(OpenStreetMapError.OTHER);
    }
    if (!json.containsKey('address')) {
      Log.w("OSM.fetchAddress: doesn't have 'address'. JSON: $json");
      return Err(OpenStreetMapError.OTHER);
    }

    final district = json['address']['city_district']?.toString();
    final neighbourhood = json['address']['neighbourhood']?.toString();
    final road = json['address']['road']?.toString();
    final houseNumber = json['address']['house_number']?.toString();
    final countryCode = json['address']['country_code']?.toString();

    final result = OsmAddress((e) => e
      ..cityDistrict = district
      ..neighbourhood = neighbourhood
      ..road = road
      ..houseNumber = houseNumber
      ..countryCode = countryCode);
    return Ok(result);
  }
}

Map<String, dynamic>? _jsonDecodeSafe(String str) {
  try {
    return jsonDecode(str) as Map<String, dynamic>?;
  } on FormatException catch (e) {
    Log.w("OpenStreetMap: couldn't decode safe: %str", ex: e);
    return null;
  }
}

enum _ParseRoadsErr {
  INVALID_JSON,
  NO_ELEMENTS,
}

Result<List<OsmRoad>, _ParseRoadsErr> _parseRoads(String text) {
  final roadsJson = _jsonDecodeSafe(text);
  if (roadsJson == null) {
    return Err(_ParseRoadsErr.INVALID_JSON);
  }
  if (!roadsJson.containsKey('elements')) {
    return Err(_ParseRoadsErr.NO_ELEMENTS);
  }

  final result = <OsmRoad>[];
  for (final roadJson in roadsJson['elements']) {
    final roadName = roadJson['tags']?['name'] as String?;
    if (roadName == null) {
      continue;
    }

    final id = roadJson['id']?.toString();
    final double? lat;
    final double? lon;
    final center = roadJson['center'] as Map<dynamic, dynamic>?;
    if (center != null) {
      lat = center['lat'] as double?;
      lon = center['lon'] as double?;
    } else {
      lat = roadJson['lat'] as double?;
      lon = roadJson['lon'] as double?;
    }

    if (id == null || lat == null || lon == null) {
      continue;
    }

    result.add(OsmRoad((e) => e
      ..osmId = id
      ..name = roadName
      ..latitude = lat
      ..longitude = lon));
  }
  return Ok(result);
}
