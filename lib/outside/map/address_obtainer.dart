import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';

typedef AddressResult = Result<OsmAddress, OpenStreetMapError>;
typedef FutureAddress = Future<AddressResult>;

class AddressObtainer {
  static final _shopsLoadsAttemptsCooldown = isInTests()
      ? const Duration(milliseconds: 50)
      : const Duration(milliseconds: 1500);
  DateTime _lastRequestTime = DateTime(2000);
  final _delayedRequests = <VoidCallback>[];

  final OpenStreetMap _osm;
  final _cache = <String, OsmAddress>{};

  AddressObtainer(this._osm);

  FutureAddress addressOfShop(Shop shop) async {
    if (_cache.containsKey(shop.osmId)) {
      return Ok(_cache[shop.osmId]!);
    }
    final completer = Completer<AddressResult>();
    VoidCallback? callback;
    callback = () async {
      final AddressResult result;
      if (_cache.containsKey(shop.osmId)) {
        result = Ok(_cache[shop.osmId]!);
      } else {
        result = await _fetchAddress(shop.latitude, shop.longitude);
        if (result.isOk) {
          _cache[shop.osmId] = result.unwrap();
        }
      }
      completer.complete(result);
      _delayedRequests.remove(callback);
      if (_delayedRequests.isNotEmpty) {
        _delayedRequests.first.call();
      }
    };
    _delayedRequests.add(callback);
    if (_delayedRequests.length == 1) {
      _delayedRequests.first.call();
    }
    return completer.future;
  }

  FutureAddress _fetchAddress(double lat, double lon) async {
    final timeSinceLastLoad = DateTime.now().difference(_lastRequestTime);
    if (timeSinceLastLoad < _shopsLoadsAttemptsCooldown) {
      await Future.delayed(_shopsLoadsAttemptsCooldown - timeSinceLastLoad);
    }
    _lastRequestTime = DateTime.now();
    return await _osm.fetchAddress(lat, lon);
  }

  FutureAddress addressOfCoords(Point<double> coords) async {
    return await _fetchAddress(coords.y, coords.x);
  }
}
