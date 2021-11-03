import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/http_client.dart';

class IpLocationProvider {
  final HttpClient _httpClient;

  IpLocationProvider(this._httpClient);

  Future<Coord?> positionByIP() async {
    final Response resp;
    try {
      resp = await _httpClient.get(Uri.parse(
          'https://api.freegeoip.app/json/?apikey=d9f18ea0-3a1a-11ec-b009-e13008b76841'));
    } on IOException catch (e) {
      Log.w('Location from IP caused IOException', ex: e);
      return null;
    }
    if (resp.statusCode != 200) {
      return null;
    }

    final dynamic json;
    try {
      json = jsonDecode(resp.body);
    } on FormatException catch (e) {
      Log.w('Location from IP response is not a JSON: ${resp.body}', ex: e);
      return null;
    }

    if (json is! Map<String, dynamic>) {
      Log.w('IP response is not a JSON object: ${resp.body}');
      return null;
    }

    final lon = json['longitude'];
    final lat = json['latitude'];
    if (lon is! num || lat is! num) {
      Log.w('Location from IP response is not applicable: ${resp.body}');
      return null;
    }

    return Coord(lat: lat.toDouble(), lon: lon.toDouble());
  }
}
