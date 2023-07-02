import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/news/news_feed_manager.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

class ShopsWhereProductSoldObtainer {
  static const PRODUCT_SHOPS_SIZE_KMS = NewsFeedManager.REQUESTED_AREA_SIZE_KMS;
  final ShopsManager _shopsManager;
  final LatestCameraPosStorage _latestCameraPosStorage;

  ShopsWhereProductSoldObtainer(
      this._shopsManager, this._latestCameraPosStorage);

  Future<Result<Map<OsmUID, Shop>, ShopsManagerError>> fetchShopsWhereSold(
      String barcode) async {
    final cameraPos = await _latestCameraPosStorage.get();
    if (cameraPos == null) {
      return Ok(const {});
    }

    final productsSquare =
        cameraPos.makeSquare(kmToGrad(PRODUCT_SHOPS_SIZE_KMS));
    if (await _shopsManager.osmShopsCacheExistFor(productsSquare) == false) {
      final fetchShopsResult = await _shopsManager.fetchShops(productsSquare);
      if (fetchShopsResult.isErr) {
        return Err(fetchShopsResult.unwrapErr());
      }
    }

    final shopsMap = await _shopsManager
        .getShopsContainingBarcodes(productsSquare, {barcode});
    final uids = shopsMap[barcode] ?? const [];
    return await _shopsManager.fetchShopsByUIDs(uids);
  }
}
