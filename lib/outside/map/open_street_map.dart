import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:plante/base/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/osm_shop.dart';

enum OpenStreetMapError { NETWORK, OTHER }

class OpenStreetMap {
  final HttpClient _http;
  OpenStreetMap(this._http);

  Future<Result<List<OsmShop>, OpenStreetMapError>> fetchShops(
      Point<double> northeast, Point<double> southwest) async {
    final val1 = southwest.x;
    final val2 = southwest.y;
    final val3 = northeast.x;
    final val4 = northeast.y;
    final typesStr = ShopType.values.map((type) => type.osmName).join('|');
    final cmd =
        '[out:json];('
        'node[shop~"$typesStr"]($val1,$val2,$val3,$val4);'
        'relation[shop~"$typesStr"]($val1,$val2,$val3,$val4);'
        ');out center;';

    final Response r;
    try {
      r = await _http.get(
          Uri.https('lz4.overpass-api.de', 'api/interpreter', {'data': cmd}));
    } on IOException {
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
}
