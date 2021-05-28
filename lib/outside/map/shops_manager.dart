import 'dart:math';

import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/open_street_map.dart';

enum ShopsManagerError { NETWORK_ERROR, OTHER }

class ShopsManager {
  final OpenStreetMap _openStreetMap;
  final Backend _backend;

  ShopsManager(this._openStreetMap, this._backend);

  Future<Result<List<Shop>, ShopsManagerError>> fetchProductsAtShops(
      Point<double> northeast, Point<double> southwest) async {
    final osmShopsResult =
        await _openStreetMap.fetchShops(northeast, southwest);
    if (osmShopsResult.isErr) {
      return Err(_convertOsmErr(osmShopsResult.unwrapErr()));
    }
    final osmShops = osmShopsResult.unwrap();
    final backendShopsResult =
        await _backend.requestProductsAtShops(osmShops.map((e) => e.osmId));
    if (backendShopsResult.isErr) {
      return Err(_convertBackendErr(backendShopsResult.unwrapErr()));
    }
    final backendShops = backendShopsResult.unwrap();

    final backendShopsMap = {
      for (final backendShop in backendShops) backendShop.osmId: backendShop
    };
    final shops = <Shop>[];
    for (final osmShop in osmShops) {
      final backendShopNullable = backendShopsMap[osmShop.osmId];
      var shop = Shop((e) => e.osmShop.replace(osmShop));
      if (backendShopNullable != null) {
        shop = shop.rebuild((e) => e.backendShop.replace(backendShopNullable));
      }
      shops.add(shop);
    }
    return Ok(shops);
  }
}

ShopsManagerError _convertOsmErr(OpenStreetMapError err) {
  switch (err) {
    case OpenStreetMapError.NETWORK:
      return ShopsManagerError.NETWORK_ERROR;
    case OpenStreetMapError.OTHER:
      return ShopsManagerError.OTHER;
  }
}

ShopsManagerError _convertBackendErr(BackendError err) {
  switch (err.errorKind) {
    case BackendErrorKind.NETWORK_ERROR:
      return ShopsManagerError.NETWORK_ERROR;
    default:
      return ShopsManagerError.OTHER;
  }
}
