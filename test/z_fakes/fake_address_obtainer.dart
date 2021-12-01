import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';

class FakeAddressObtainer implements AddressObtainer {
  OsmAddress? _addressForAllRequests;

  void setResponse(OsmAddress? response) {
    _addressForAllRequests = response;
  }

  @override
  FutureAddress addressOfCoords(Coord coords) async {
    if (_addressForAllRequests != null) {
      return Ok(_addressForAllRequests!);
    } else {
      return Err(OpenStreetMapError.OTHER);
    }
  }

  @override
  FutureShortAddress shortAddressOfCoords(Coord coords) async {
    if (_addressForAllRequests != null) {
      return Ok(_addressForAllRequests!.toShort());
    } else {
      return Err(OpenStreetMapError.OTHER);
    }
  }

  @override
  FutureShortAddress addressOfShop(Shop shop) async {
    return await shortAddressOfCoords(shop.coord);
  }
}
