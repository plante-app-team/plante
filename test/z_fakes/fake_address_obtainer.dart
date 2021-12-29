import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';

class FakeAddressObtainer implements AddressObtainer {
  final _requests = <RecordedAddressRequest>[];
  Result<OsmAddress, OpenStreetMapError>? _defaultResponse;
  final Map<Coord, Result<OsmAddress, OpenStreetMapError>> _responses = {};

  List<RecordedAddressRequest> recordedRequests() =>
      UnmodifiableListView(_requests);
  int recordedRequestsCount() => _requests.length;
  void resetRecordedRequests() => _requests.clear();

  void setDefaultResponse(OsmAddress? response) {
    _defaultResponse = response != null ? Ok(response) : null;
  }

  void setDefaultResponseFull(Result<OsmAddress, OpenStreetMapError>? resp) {
    _defaultResponse = resp;
  }

  void setResponse(Coord coord, OsmAddress address) {
    _responses[coord] = Ok(address);
  }

  void setResponseFull(
      Coord coord, Result<OsmAddress, OpenStreetMapError> resp) {
    _responses[coord] = resp;
  }

  @override
  FutureAddress addressOfCoords(Coord coords, {String? langCode}) async {
    _requests.add(RecordedAddressRequest(coords, langCode));

    final response = _responses[coords] ?? _defaultResponse;
    if (response != null) {
      return response;
    } else {
      return Err(OpenStreetMapError.OTHER);
    }
  }

  @override
  FutureShortAddress shortAddressOfCoords(Coord coords) async {
    _requests.add(RecordedAddressRequest(coords, null));

    final response = _responses[coords] ?? _defaultResponse;
    if (response != null) {
      if (response.isOk) {
        return Ok(response.unwrap().toShort());
      } else {
        return Err(response.unwrapErr());
      }
    } else {
      return Err(OpenStreetMapError.OTHER);
    }
  }

  @override
  FutureShortAddress addressOfShop(Shop shop, {String? langCode}) async {
    return await shortAddressOfCoords(shop.coord);
  }
}

@immutable
class RecordedAddressRequest {
  final Coord coord;
  final String? langCode;
  const RecordedAddressRequest(this.coord, this.langCode);

  @override
  bool operator ==(Object other) {
    if (other is! RecordedAddressRequest) {
      return false;
    }
    return coord == other.coord && langCode == other.langCode;
  }

  @override
  int get hashCode => coord.hashCode;

  @override
  String toString() {
    return jsonEncode({
      'coord': coord,
      'langCode': langCode,
    });
  }
}
