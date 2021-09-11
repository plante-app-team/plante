import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/fuzzy_search.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/osm_search_result.dart';
import 'package:plante/outside/map/osm_shop.dart';

// We use LinkedHashMap because order is important, so:
// ignore_for_file: prefer_collection_literals

enum OpenStreetMapError { NETWORK, OTHER }

/// A class designed to be put into DI to protect [OpenStreetMap] from
/// being obtained directly.
/// [OpenStreetMap] should never be used directly, but through instances of
/// [OpenStreetMapReceiver], because they know how to .
class OpenStreetMapHolder {
  final OpenStreetMap _osm;
  OpenStreetMapHolder(
      HttpClient http, Analytics analytics, OsmInteractionsQueue queue)
      : _osm = OpenStreetMap(http, analytics, queue);
  OpenStreetMap getOsm({required OpenStreetMapReceiver whoAsks}) => _osm;
}

abstract class OpenStreetMapReceiver {}

/// A wrapper around Open Street Map APIs.
///
/// PLEASE NOTE that this class shouldn't be used directly by app's logic,
/// because all of the OSM APIs have rate limits and will ban the device
/// (or the app) if it sends too many requests.
/// Instead, wrappers for certain purposes should be created.
class OpenStreetMap {
  final HttpClient _http;
  final Analytics _analytics;
  final OsmInteractionsQueue _interactionsQueue;

  /// We use LinkedHashMap because order is important
  final _osmOverpassUrls = LinkedHashMap<String, String>();

  Map<String, String> get osmOverpassUrls => MapView(_osmOverpassUrls);

  OpenStreetMap(this._http, this._analytics, this._interactionsQueue) {
    _osmOverpassUrls['lz4'] = 'lz4.overpass-api.de';
    _osmOverpassUrls['z'] = 'z.overpass-api.de';
    _osmOverpassUrls['kumi'] = 'overpass.kumi.systems';
    _osmOverpassUrls['taiwan'] = 'overpass.nchc.org.tw';
  }

  Future<Result<List<OsmShop>, OpenStreetMapError>> fetchShops(
      CoordsBounds bounds) async {
    if (!_interactionsQueue
        .isInteracting(OsmInteractionsGoal.FETCH_SHOPS.service)) {
      Log.e('OSM.fetchShops called outside of the queue');
    }
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
    if (!_interactionsQueue
        .isInteracting(OsmInteractionsGoal.FETCH_ROADS.service)) {
      Log.e('OSM.fetchRoads called outside of the queue');
    }
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
    if (!_interactionsQueue
        .isInteracting(OsmInteractionsGoal.FETCH_ADDRESS.service)) {
      Log.e('OSM.fetchAddress called outside of the queue');
    }
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

    final country = json['address']['country']?.toString();
    final city = json['address']['city']?.toString();
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
      ..city = city
      ..country = country
      ..countryCode = countryCode);
    return Ok(result);
  }

  Future<Result<OsmSearchResult, OpenStreetMapError>> search(
      String country, String city, String query) async {
    if (!_interactionsQueue.isInteracting(OsmInteractionsGoal.SEARCH.service)) {
      Log.e('OSM.search called outside of the queue');
    }
    final Response r;
    try {
      r = await _http.get(
          Uri.https('nominatim.openstreetmap.org', 'search', {
            'q': '$country $city $query',
            'format': 'json',
          }),
          headers: {'User-Agent': await userAgent()});
    } on IOException catch (e) {
      Log.w('OSM nominatim network error', ex: e);
      return Err(OpenStreetMapError.NETWORK);
    }

    if (r.statusCode != 200) {
      Log.w('OSM.search: ${r.statusCode}, body: ${r.body}');
      return Err(OpenStreetMapError.OTHER);
    }

    final json = _jsonDecodeSafeList(utf8.decode(r.bodyBytes));
    if (json == null) {
      return Err(OpenStreetMapError.OTHER);
    }

    final foundShops = <OsmShop>[];
    final foundRoads = <OsmRoad>[];
    final typesOfShops = ShopType.values.map((e) => e.osmName);
    final foundRoadsFullNames = <String>{};
    for (final entry in json) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final type = entry['type']?.toString();
      final osmClass = entry['class']?.toString();
      final osmId = entry['osm_id']?.toString();
      final double? lat = _extractPosPiece('lat', entry);
      final double? lon = _extractPosPiece('lon', entry);
      final fullName = entry['display_name']?.toString();
      final name = fullName?.substringBefore(',');
      if (type == null ||
          osmId == null ||
          lat == null ||
          lon == null ||
          name == null ||
          fullName == null) {
        continue;
      }
      if (typesOfShops.contains(type)) {
        foundShops.add(OsmShop((e) => e
          ..osmId = osmId
          ..name = name
          ..type = type
          ..latitude = lat
          ..longitude = lon));
      } else if (osmClass == 'highway') {
        if (_wasNameSeenBefore(foundRoadsFullNames, fullName)) {
          continue;
        }
        foundRoadsFullNames.add(fullName);
        foundRoads.add(OsmRoad((e) => e
          ..osmId = osmId
          ..name = name
          ..latitude = lat
          ..longitude = lon));
      }
    }
    return Ok(OsmSearchResult(
        (e) => e..shops.addAll(foundShops)..roads.addAll(foundRoads)));
  }

  bool _wasNameSeenBefore(Set<String> foundRoadsFullNames, String fullName) {
    for (final existingFullName in foundRoadsFullNames) {
      if (FuzzySearch.areSimilar(existingFullName, fullName)) {
        // Long roads often contain multiple parts, because a single
        // road can span through multiple zipcodes, districts, etc.
        // We want only 1 of the road parts to be found, so we attempt to
        // ignore roads similar to which are already found.
        // NOTE: not tested extensively, can be buggy.
        return true;
      }
    }
    return false;
  }

  double? _extractPosPiece(String name, Map<String, dynamic> source) {
    if (source[name] is double) {
      return source[name] as double;
    } else {
      return double.tryParse(source[name]?.toString() ?? '');
    }
  }
}

Map<String, dynamic>? _jsonDecodeSafe(String str) {
  return _jsonDecodeSafeImpl<Map<String, dynamic>>(str);
}

List<dynamic>? _jsonDecodeSafeList(String str) {
  return _jsonDecodeSafeImpl<List<dynamic>>(str);
}

T? _jsonDecodeSafeImpl<T>(String str) {
  try {
    return jsonDecode(str) as T?;
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

extension _StringExt on String {
  String? substringBefore(String target) {
    final targetIndex = indexOf(target);
    if (targetIndex > 0) {
      return substring(0, targetIndex);
    }
    return null;
  }
}
