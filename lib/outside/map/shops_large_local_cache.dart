import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

abstract class ShopsLargeLocalCache {
  Future<void> addBarcodes(Map<OsmUID, List<String>> barcodes);

  Future<void> addBarcode(OsmUID uid, String barcode) async {
    await addBarcodes({
      uid: [barcode]
    });
  }

  Future<Map<OsmUID, List<String>>> getBarcodes(Iterable<OsmUID> uids);

  Future<Map<OsmUID, List<String>>> getBarcodesWithin(CoordsBounds bounds);

  Future<void> removeBarcodes(Map<OsmUID, List<String>> barcodes);

  Future<void> removeBarcode(OsmUID uid, String barcode) async {
    await removeBarcodes({
      uid: [barcode]
    });
  }

  /// Will replace existing shops with same uids.
  Future<void> addShops(Iterable<Shop> shops);

  /// Will replace existing shops with same uids.
  Future<void> addShop(Shop shop) async {
    await addShops([shop]);
  }

  Future<Map<OsmUID, Shop>> getShops(Iterable<OsmUID> uids);

  Future<Shop?> getShop(OsmUID uid) async {
    final map = await getShops([uid]);
    return map[uid];
  }

  Future<void> clear();

  void dispose();
}
