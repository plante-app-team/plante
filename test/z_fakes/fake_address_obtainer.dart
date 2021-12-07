import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';

class FakeAddressObtainer implements AddressObtainer {
  OsmAddress? _defaultResponse;
  final Map<Coord, OsmAddress> _responses = {};

  void setDefaultResponse(OsmAddress? response) {
    _defaultResponse = response;
  }

  void setResponse(Coord coord, OsmAddress address) {
    _responses[coord] = address;
  }

  @override
  FutureAddress addressOfCoords(Coord coords) async {
    final response = _responses[coords] ?? _defaultResponse;
    if (response != null) {
      return Ok(response);
    } else {
      return Err(OpenStreetMapError.OTHER);
    }
  }

  @override
  FutureShortAddress shortAddressOfCoords(Coord coords) async {
    final response = _responses[coords] ?? _defaultResponse;
    if (response != null) {
      return Ok(response.toShort());
    } else {
      return Err(OpenStreetMapError.OTHER);
    }
  }

  @override
  FutureShortAddress addressOfShop(Shop shop) async {
    return await shortAddressOfCoords(shop.coord);
  }
}
