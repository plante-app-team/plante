import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';

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
  final _packageInfo = Completer<PackageInfo>();

  OpenStreetMap(this._http) {
    () async {
      _packageInfo.complete(await PackageInfo.fromPlatform());
    }.call();
  }

  Future<String> _userAgent() async {
    final packageInfo = await _packageInfo.future;
    return 'User-Agent: ${packageInfo.appName} / ${packageInfo.version} '
        '${Platform.operatingSystem}';
  }

  Future<Result<List<OsmShop>, OpenStreetMapError>> fetchShops(
      Point<double> northeast, Point<double> southwest) async {
    final val1 = southwest.x;
    final val2 = southwest.y;
    final val3 = northeast.x;
    final val4 = northeast.y;
    final typesStr = ShopType.values.map((type) => type.osmName).join('|');
    final cmd = '[out:json];('
        'node[shop~"$typesStr"]($val1,$val2,$val3,$val4);'
        'relation[shop~"$typesStr"]($val1,$val2,$val3,$val4);'
        'way[shop~"$typesStr"]($val1,$val2,$val3,$val4);'
        ');out center;';

    final Response r;
    try {
      r = await _http.get(
          Uri.https('lz4.overpass-api.de', 'api/interpreter', {'data': cmd}),
          headers: {'User-Agent': await _userAgent()});
    } on IOException catch (e) {
      Log.w('OSM overpass network error', ex: e);
      return Err(OpenStreetMapError.NETWORK);
    }

    if (r.statusCode != 200) {
      Log.w('OSM.fetchShops: ${r.statusCode}, body: ${r.body}');
      return Err(OpenStreetMapError.OTHER);
    }

    final shopsJson = _jsonDecodeSafe(utf8.decode(r.bodyBytes));
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

  Map<String, dynamic>? _jsonDecodeSafe(String str) {
    try {
      return jsonDecode(str) as Map<String, dynamic>?;
    } on FormatException catch (e) {
      Log.w("OpenStreetMap: couldn't decode safe: %str", ex: e);
      return null;
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
          headers: {'User-Agent': await _userAgent()});
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

    final result = OsmAddress((e) => e
      ..cityDistrict = district
      ..neighbourhood = neighbourhood
      ..road = road
      ..houseNumber = houseNumber);
    return Ok(result);
  }
}
