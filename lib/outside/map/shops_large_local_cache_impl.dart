import 'package:plante/logging/log.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_large_local_cache.dart';

class ShopsLargeLocalCacheImpl with ShopsLargeLocalCache {
  final _shops = <OsmUID, Shop>{};
  final _barcodes = <OsmUID, Set<String>>{};
  final _barcodesAtShops = <String, Set<OsmUID>>{};

  @override
  Future<void> addBarcodes(Map<OsmUID, List<String>> barcodes) async {
    for (final entry in barcodes.entries) {
      final uid = entry.key;
      final newBarcodes = entry.value;
      _barcodes[uid] ??= <String>{};
      _barcodes[uid]!.addAll(newBarcodes);

      for (final barcode in entry.value) {
        _barcodesAtShops[barcode] ??= {};
        _barcodesAtShops[barcode]!.add(uid);
      }
    }
  }

  @override
  Future<void> addShops(Iterable<Shop> shops) async {
    final shopsMap = {for (final shop in shops) shop.osmUID: shop};
    _shops.addAll(shopsMap);
  }

  @override
  Future<void> clear() async {
    _barcodes.clear();
    _shops.clear();
    _barcodesAtShops.clear();
  }

  @override
  void dispose() {
    clear();
  }

  @override
  Future<Map<OsmUID, List<String>>> getBarcodes(Iterable<OsmUID> uids) async {
    final result = <OsmUID, List<String>>{};
    for (final uid in uids) {
      final barcodes = _barcodes[uid];
      if (barcodes != null && barcodes.isNotEmpty) {
        result[uid] = barcodes.toList();
      }
    }
    return result;
  }

  @override
  Future<Map<OsmUID, List<String>>> getBarcodesWithin(
      CoordsBounds bounds) async {
    final result = <OsmUID, List<String>>{};
    for (final entry in _barcodes.entries) {
      final uid = entry.key;
      final barcodes = entry.value;
      final shop = _shops[uid];
      if (shop != null && bounds.contains(shop.coord) && barcodes.isNotEmpty) {
        result[uid] = barcodes.toList();
      }
    }
    return result;
  }

  @override
  Future<Map<String, List<OsmUID>>> getShopsContainingBarcodes(
      CoordsBounds bounds, Set<String> barcodes) async {
    final result = <String, List<OsmUID>>{};
    for (final barcode in barcodes) {
      final shopsUIDsOfBarcode = _barcodesAtShops[barcode];
      if (shopsUIDsOfBarcode == null) {
        continue;
      }
      for (final uid in shopsUIDsOfBarcode) {
        final shop = _shops[uid];
        if (shop == null) {
          Log.w('UID $uid is known, but its shops is not');
          continue;
        }
        if (bounds.contains(shop.coord)) {
          result[barcode] ??= [];
          result[barcode]!.add(uid);
        }
      }
    }
    return result;
  }

  @override
  Future<Map<OsmUID, Shop>> getShops(Iterable<OsmUID> uids) async {
    final result = <OsmUID, Shop>{};
    for (final uid in uids) {
      final shop = _shops[uid];
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
      _barcodes[uid]?.removeWhere(barcodes.contains);
      for (final barcode in barcodes) {
        _barcodesAtShops[barcode]?.remove(uid);
      }
    }
  }
}
