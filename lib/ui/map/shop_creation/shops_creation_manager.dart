import 'package:flutter/material.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/map/shop_creation/create_shop_page.dart';
import 'package:plante/ui/map/shop_creation/pick_existing_shop_page.dart';

class ShopsCreationManager {
  static const EXISTING_SHOPS_SEARCH_RADIUS_KMS = 0.5;
  final ShopsManager _shopsManager;

  ShopsCreationManager(this._shopsManager);

  /// Starts shop creation process.
  /// NOTE: user can both cancel shop creation and select an already existing
  /// shop instead of creating a new one.
  Future<Result<Shop?, GeneralError>> startShopCreation(
      Coord coord, BuildContext context) async {
    final existingShopsRes = await _shopsManager.fetchShops(
        coord.makeSquare(kmToGrad(EXISTING_SHOPS_SEARCH_RADIUS_KMS)));
    if (existingShopsRes.isErr) {
      existingShopsRes.unwrapErr().toGeneral();
    }

    final existingShops = existingShopsRes.unwrap().values.toList()
      ..sort((lhs, rhs) =>
          metersBetween(lhs.coord, coord).round() -
          metersBetween(rhs.coord, coord).round());
    if (existingShops.isNotEmpty) {
      final existingShopResult = await Navigator.push<PickExistingShopResult>(
        context,
        MaterialPageRoute(
            builder: (context) => PickExistingShopPage(existingShops)),
      );
      if (existingShopResult == null) {
        // Cancelled
        return Ok(null);
      }
      if (existingShopResult is PickExistingShopResultShopPicked) {
        return Ok(existingShopResult.shop);
      }
      if (existingShopResult is! PickExistingShopResultNewShopWanted) {
        Log.e(
            'Unhandled pick shop result type: ${existingShopResult.runtimeType}');
      }
      // Seems user _really_ wants to create a new shop!
    }

    final newShop = await Navigator.push<Shop>(
      context,
      MaterialPageRoute(builder: (context) => CreateShopPage(shopCoord: coord)),
    );
    return Ok(newShop);
  }
}
