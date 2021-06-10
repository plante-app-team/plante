import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:plante/base/log.dart';
import 'package:plante/outside/http_client.dart';

class IpLocationProvider {
  final HttpClient _httpClient;

  IpLocationProvider(this._httpClient);

  Future<Point<double>?> positionByIP() async {
    final Response resp;
    try {
      resp = await _httpClient
          .get(Uri.parse('https://api.ipregistry.co/?key=tryout'));
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

    if (json is! Map<String, dynamic> ||
        json['location'] is! Map<String, dynamic>) {
      Log.w('Location from IP response is not a JSON object: ${resp.body}',
          ex: e);
      return null;
    }

    final lon = json['location']['longitude'];
    final lat = json['location']['latitude'];
    if (lon is! num || lat is! num) {
      Log.w('Location from IP response is not applicable: ${resp.body}', ex: e);
      return null;
    }

    return Point<double>(lon.toDouble(), lat.toDouble());
  }
}
