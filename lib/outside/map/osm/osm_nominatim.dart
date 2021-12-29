import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_element_type.dart';
import 'package:plante/outside/map/osm/osm_interactions_queue.dart';
import 'package:plante/outside/map/osm/osm_road.dart';
import 'package:plante/outside/map/osm/osm_search_result.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

/// A wrapper around Open Street Map Nominatim APIs.
///
/// PLEASE NOTE that this class shouldn't be used directly by app's logic,
/// because all of the OSM APIs have rate limits and will ban the device
/// (or the app) if it sends too many requests.
/// Instead, wrappers for certain purposes should be created.
class OsmNominatim {
  final HttpClient _http;
  final OsmInteractionsQueue _interactionsQueue;

  OsmNominatim(this._http, this._interactionsQueue);

  Future<Result<OsmAddress, OpenStreetMapError>> fetchAddress(
      double lat, double lon,
      {String? langCode}) async {
    if (!_interactionsQueue.isInteracting(OsmInteractionService.NOMINATIM)) {
      Log.e('OSM.fetchAddress called outside of the queue');
    }
    final Response r;
    try {
      final params = {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
      };
      if (langCode != null) {
        params['accept-language'] = langCode;
      }
      r = await _http.get(
          Uri.https('nominatim.openstreetmap.org', 'reverse', params),
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
    if (!_interactionsQueue.isInteracting(OsmInteractionService.NOMINATIM)) {
      Log.e('OSM.search called outside of the queue');
    }
    final Response r;
    try {
      r = await _http.get(
          Uri.https('nominatim.openstreetmap.org', 'search', {
            'q': '$country $city $query',
            'namedetails': '1',
            'addressdetails': '1',
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
    final foundRoadsLocations = <String>{};
    for (final entry in json) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final type = entry['type']?.toString();
      final osmClass = entry['class']?.toString();
      final osmElementType = _osmTypeFrom(entry['osm_type']?.toString());
      final osmId = entry['osm_id']?.toString();
      final double? lat = _extractPosPiece('lat', entry);
      final double? lon = _extractPosPiece('lon', entry);
      final name = entry['namedetails']?['name']?.toString();
      if (type == null ||
          osmId == null ||
          osmElementType == null ||
          lat == null ||
          lon == null ||
          name == null) {
        continue;
      }
      if (typesOfShops.contains(type)) {
        final city = entry['address']?['city'] as String?;
        final road = entry['address']?['road'] as String?;
        final houseNumber = entry['address']?['house_number'] as String?;
        foundShops.add(OsmShop((e) => e
          ..osmUID = OsmUID.parse('${osmElementType.persistentCode}:$osmId')
          ..name = name
          ..type = type
          ..latitude = lat
          ..longitude = lon
          ..city = city
          ..road = road
          ..houseNumber = houseNumber));
      } else if (osmClass == 'highway') {
        final city = entry['address']?['city']?.toString();
        final district = entry['address']?['city_district']?.toString();
        final roadLocation = '$name $district $city';
        if (foundRoadsLocations.contains(roadLocation)) {
          // Long roads often contain multiple parts.
          // We want only 1 of the road parts to be found, so we attempt to
          // ignore roads similar to which are already found.
          // NOTE: not tested extensively, can be buggy.
          continue;
        }
        foundRoadsLocations.add(roadLocation);
        foundRoads.add(OsmRoad((e) => e
          ..osmId = osmId
          ..name = name
          ..latitude = lat
          ..longitude = lon));
      }
    }
    return Ok(OsmSearchResult((e) => e
      ..shops.addAll(foundShops)
      ..roads.addAll(foundRoads)));
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

OsmElementType? _osmTypeFrom(String? str) {
  if (str == null) {
    return null;
  }
  return osmElementTypeFromStr(str);
}
