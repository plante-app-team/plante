import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_large_local_cache.dart';

class ShopsLargeLocalCacheImpl with ShopsLargeLocalCache {
  final shops = <OsmUID, Shop>{};
  final barcodes = <OsmUID, List<String>>{};

  @override
  Future<void> addBarcodes(Map<OsmUID, List<String>> barcodes) async {
    for (final entry in barcodes.entries) {
      final uid = entry.key;
      final newBarcodes = entry.value;
      this.barcodes[uid] ??= <String>[];
      newBarcodes
          .removeWhere((barcode) => this.barcodes[uid]!.contains(barcode));
      this.barcodes[uid]!.addAll(newBarcodes);
    }
  }

  @override
  Future<void> addShops(Iterable<Shop> shops) async {
    final shopsMap = {for (final shop in shops) shop.osmUID: shop};
    this.shops.addAll(shopsMap);
  }

  @override
  Future<void> clear() async {
    barcodes.clear();
    shops.clear();
  }

  @override
  void dispose() {
    clear();
  }

  @override
  Future<Map<OsmUID, List<String>>> getBarcodes(Iterable<OsmUID> uids) async {
    final result = <OsmUID, List<String>>{};
    for (final uid in uids) {
      final barcodes = this.barcodes[uid];
      if (barcodes != null && barcodes.isNotEmpty) {
        result[uid] = barcodes;
      }
    }
    return result;
  }

  @override
  Future<Map<OsmUID, List<String>>> getBarcodesWithin(
      CoordsBounds bounds) async {
    final result = <OsmUID, List<String>>{};
    for (final entry in barcodes.entries) {
      final uid = entry.key;
      final barcodes = entry.value;
      final shop = shops[uid];
      if (shop != null && bounds.contains(shop.coord) && barcodes.isNotEmpty) {
        result[uid] = barcodes;
      }
    }
    return result;
  }

  @override
  Future<Map<OsmUID, Shop>> getShops(Iterable<OsmUID> uids) async {
    final result = <OsmUID, Shop>{};
    for (final uid in uids) {
      final shop = shops[uid];
      if (shop != null) {
        result[uid] = shop;
      }
    }
    return result;
  }

  @override
  Future<void> removeBarcodes(Map<OsmUID, List<String>> barcodes) async {
    for (final entry in barcodes.entries) {
      final uid = entry.key;
      final barcodes = entry.value;
      this.barcodes[uid]?.removeWhere(barcodes.contains);
    }
  }
}
