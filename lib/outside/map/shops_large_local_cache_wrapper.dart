import 'package:plante/base/background/background_log_msg.dart';
import 'package:plante/base/background/background_worker.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

class ShopsLargeLocalCacheWrapper
    extends BackgroundWorker<_BackgroundIsolateState> {
  ShopsLargeLocalCacheWrapper._()
      : super('ShopsLargeLocalCacheWrapper', _handleBackgroundWorkMessage);

  static Future<ShopsLargeLocalCacheWrapper> create() async {
    final instance = ShopsLargeLocalCacheWrapper._();
    await instance.init(_BackgroundIsolateState());
    return instance;
  }

  Future<Map<OsmUID, List<String>>> getBarcodes(Iterable<OsmUID> uids) async {
    final stream =
        communicate(_TaskPayload(_TaskType.GET_BARCODES, uids.toList()));
    return await stream.first as Map<OsmUID, List<String>>;
  }

  static Map<OsmUID, List<String>> _backgroundGetBarcodes(
      Iterable<OsmUID> uids, _BackgroundIsolateState state) {
    final result = <OsmUID, List<String>>{};
    for (final uid in uids) {
      final barcodes = state.barcodes[uid];
      if (barcodes != null && barcodes.isNotEmpty) {
        result[uid] = barcodes;
      }
    }
    return result;
  }

  Future<Map<OsmUID, List<String>>> getBarcodesWithin(
      CoordsBounds bounds) async {
    final stream =
        communicate(_TaskPayload(_TaskType.GET_BARCODES_IN_BOUNDS, bounds));
    return await stream.first as Map<OsmUID, List<String>>;
  }

  static Map<OsmUID, List<String>> _backgroundGetBarcodesInBounds(
      CoordsBounds bounds, _BackgroundIsolateState state) {
    final result = <OsmUID, List<String>>{};
    for (final entry in state.barcodes.entries) {
      final uid = entry.key;
      final barcodes = entry.value;
      final shop = state.shops[uid];
      if (shop != null && bounds.contains(shop.coord) && barcodes.isNotEmpty) {
        result[uid] = barcodes;
      }
    }
    return result;
  }

  Future<Shop?> getShop(OsmUID uid) async {
    final map = await getShops([uid]);
    return map[uid];
  }

  Future<Map<OsmUID, Shop>> getShops(Iterable<OsmUID> uids) async {
    final stream =
        communicate(_TaskPayload(_TaskType.GET_SHOPS, uids.toList()));
    return await stream.first as Map<OsmUID, Shop>;
  }

  static Map<OsmUID, Shop> _backgroundGetShops(
      Iterable<OsmUID> uids, _BackgroundIsolateState state) {
    final result = <OsmUID, Shop>{};
    for (final uid in uids) {
      final shop = state.shops[uid];
      if (shop != null) {
        result[uid] = shop;
      }
    }
    return result;
  }

  Future<void> addBarcode(OsmUID uid, String barcode) async {
    await addBarcodes({
      uid: [barcode]
    });
  }

  Future<void> addBarcodes(Map<OsmUID, List<String>> barcodes) async {
    final barcodesCopy =
        barcodes.map((key, value) => MapEntry(key, value.toList()));
    final stream =
        communicate(_TaskPayload(_TaskType.ADD_BARCODES, barcodesCopy));
    await stream.first as None;
  }

  static None _backgroundAddBarcodes(
      Map<OsmUID, List<String>> barcodes, _BackgroundIsolateState state) {
    for (final entry in barcodes.entries) {
      final uid = entry.key;
      final barcodes = entry.value;
      state.barcodes[uid] ??= <String>[];
      barcodes.removeWhere((barcode) => state.barcodes[uid]!.contains(barcode));
      state.barcodes[uid]!.addAll(barcodes);
    }
    return None();
  }

  Future<void> removeBarcode(OsmUID uid, String barcode) async {
    await removeBarcodes({
      uid: [barcode]
    });
  }

  Future<void> removeBarcodes(Map<OsmUID, List<String>> barcodes) async {
    final barcodesCopy =
        barcodes.map((key, value) => MapEntry(key, value.toList()));
    final stream =
        communicate(_TaskPayload(_TaskType.REMOVE_BARCODES, barcodesCopy));
    await stream.first as None;
  }

  static None _backgroundRemoveBarcodes(
      Map<OsmUID, List<String>> barcodes, _BackgroundIsolateState state) {
    for (final entry in barcodes.entries) {
      final uid = entry.key;
      final barcodes = entry.value;
      state.barcodes[uid]?.removeWhere(barcodes.contains);
    }
    return None();
  }

  /// Will replace existing shop with same uid.
  Future<void> addShop(Shop shop) async {
    await addShops([shop]);
  }

  /// Will replace existing shops with same uids.
  Future<void> addShops(Iterable<Shop> shops) async {
    final stream =
        communicate(_TaskPayload(_TaskType.ADD_SHOPS, shops.toList()));
    await stream.first as None;
  }

  static None _backgroundAddShops(
      Iterable<Shop> shops, _BackgroundIsolateState state) {
    final shopsMap = {for (final shop in shops) shop.osmUID: shop};
    state.shops.addAll(shopsMap);
    return None();
  }

  Future<void> clear() async {
    final stream = communicate(_TaskPayload(_TaskType.CLEAR, null));
    await stream.first as None;
  }

  static None _backgroundClear(_BackgroundIsolateState state) {
    state.barcodes.clear();
    state.shops.clear();
    return None();
  }

  static dynamic _handleBackgroundWorkMessage(
      dynamic payload, _BackgroundIsolateState state, BackgroundLog log) {
    final payloadTyped = payload as _TaskPayload;
    switch (payloadTyped.type) {
      case _TaskType.GET_BARCODES:
        return _backgroundGetBarcodes(
            payloadTyped.data as Iterable<OsmUID>, state);
      case _TaskType.GET_BARCODES_IN_BOUNDS:
        return _backgroundGetBarcodesInBounds(
            payloadTyped.data as CoordsBounds, state);
      case _TaskType.GET_SHOPS:
        return _backgroundGetShops(
            payloadTyped.data as Iterable<OsmUID>, state);
      case _TaskType.ADD_BARCODES:
        return _backgroundAddBarcodes(
            payloadTyped.data as Map<OsmUID, List<String>>, state);
      case _TaskType.REMOVE_BARCODES:
        return _backgroundRemoveBarcodes(
            payloadTyped.data as Map<OsmUID, List<String>>, state);
      case _TaskType.ADD_SHOPS:
        return _backgroundAddShops(payloadTyped.data as Iterable<Shop>, state);
      case _TaskType.CLEAR:
        return _backgroundClear(state);
    }
  }
}

class _BackgroundIsolateState {
  final shops = <OsmUID, Shop>{};
  final barcodes = <OsmUID, List<String>>{};
  _BackgroundIsolateState();
}

enum _TaskType {
  GET_BARCODES,
  GET_BARCODES_IN_BOUNDS,
  GET_SHOPS,
  ADD_BARCODES,
  REMOVE_BARCODES,
  ADD_SHOPS,
  CLEAR,
}

class _TaskPayload {
  final _TaskType type;
  final dynamic data;
  _TaskPayload(this.type, this.data);
}
