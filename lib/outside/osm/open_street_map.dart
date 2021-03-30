import 'dart:convert';
import 'dart:math';

import 'package:get_it/get_it.dart';
import 'package:untitled_vegan_app/outside/http_client.dart';
import 'package:untitled_vegan_app/model/shop.dart';

class OpenStreetMap {
  Future<List<Shop>> fetchShops(
      Point<double> northeast,
      Point<double> southwest,
      { String shopType = 'supermarket' }) async {
    final http = GetIt.I.get<HttpClient>();

    final val1 = southwest.x;
    final val2 = southwest.y;
    final val3 = northeast.x;
    final val4 = northeast.y;
    final cmd = '[out:json];node[shop=$shopType]($val1,$val2,$val3,$val4);out;';

    // TODO(https://trello.com/c/3Byaz2fk/): ru-domen is ok only for Russia
    final r = await http.get(Uri.https(
        'overpass.openstreetmap.ru',
        'api/interpreter',
        {'data': cmd}));

    if (r.statusCode != 200) {
      // TODO(https://trello.com/c/XWAE5UVB/): log warning
      return [];
    }

    final shopsJson = json.decode(utf8.decode(r.bodyBytes));
    if (!shopsJson.containsKey('elements')) {
      // TODO(https://trello.com/c/XWAE5UVB/): log warning
      return [];
    }

    final result = <Shop>[];
    for (var shopJson in shopsJson['elements']) {
      final shopType = shopJson['tags']?['shop'] as String?;
      final shopName = shopJson['tags']?['name'] as String?;
      if (shopName == null) {
        continue;
      }

      final id = shopJson['id']?.toString();
      final lat = shopJson['lat'] as double?;
      final lon = shopJson['lon'] as double?;
      if (id == null || lat == null || lon == null) {
        continue;
      }

      result.add(Shop(
        id, shopName, shopType, lat, lon));
    }
    return result;
  }
}
