import 'package:plante/base/background/background_log_msg.dart';
import 'package:plante/base/background/background_worker.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_large_local_cache.dart';
import 'package:plante/outside/map/shops_large_local_cache_impl.dart';

/// Isolated, because it does the heavy work in a background isolate.
class ShopsLargeLocalCacheIsolated
    extends BackgroundWorker<_BackgroundIsolateState>
    with ShopsLargeLocalCache {
  ShopsLargeLocalCacheIsolated._()
      : super('ShopsLargeLocalCacheWrapper', _handleBackgroundWorkMessage);

  static Future<ShopsLargeLocalCacheIsolated> create() async {
    final instance = ShopsLargeLocalCacheIsolated._();
    await instance.init(_BackgroundIsolateState());
    return instance;
  }

  @override
  Future<Map<OsmUID, List<String>>> getBarcodes(Iterable<OsmUID> uids) async {
    final stream =
        communicate(_TaskPayload(_TaskType.GET_BARCODES, uids.toList()));
    return await stream.first as Map<OsmUID, List<String>>;
  }

  @override
  Future<Map<OsmUID, List<String>>> getBarcodesWithin(
      CoordsBounds bounds) async {
    final stream =
        communicate(_TaskPayload(_TaskType.GET_BARCODES_IN_BOUNDS, bounds));
    return await stream.first as Map<OsmUID, List<String>>;
  }

  @override
  Future<Map<String, List<OsmUID>>> getShopsContainingBarcodes(
      CoordsBounds bounds, Set<String> barcodes) async {
    final stream = communicate(_TaskPayload(
        _TaskType.GET_SHOPS_CONTAINING_BARCODES, Pair(bounds, barcodes)));
    return await stream.first as Map<String, List<OsmUID>>;
  }

  @override
  Future<Map<OsmUID, Shop>> getShops(Iterable<OsmUID> uids) async {
    final stream =
        communicate(_TaskPayload(_TaskType.GET_SHOPS, uids.toList()));
    return await stream.first as Map<OsmUID, Shop>;
  }

  @override
  Future<void> addBarcodes(Map<OsmUID, List<String>> barcodes) async {
    final barcodesCopy =
        barcodes.map((key, value) => MapEntry(key, value.toList()));
    final stream =
        communicate(_TaskPayload(_TaskType.ADD_BARCODES, barcodesCopy));
    await stream.first;
  }

  @override
  Future<void> removeBarcodes(Map<OsmUID, List<String>> barcodes) async {
    final barcodesCopy =
        barcodes.map((key, value) => MapEntry(key, value.toList()));
    final stream =
        communicate(_TaskPayload(_TaskType.REMOVE_BARCODES, barcodesCopy));
    await stream.first;
  }

  @override
  Future<void> addShops(Iterable<Shop> shops) async {
    final stream =
        communicate(_TaskPayload(_TaskType.ADD_SHOPS, shops.toList()));
    await stream.first;
  }

  @override
  Future<void> clear() async {
    final stream = communicate(_TaskPayload(_TaskType.CLEAR, null));
    await stream.first;
  }

  static dynamic _handleBackgroundWorkMessage(
      dynamic payload, _BackgroundIsolateState state, BackgroundLog log) async {
    final payloadTyped = payload as _TaskPayload;
    switch (payloadTyped.type) {
      case _TaskType.GET_BARCODES:
        return await state.impl
            .getBarcodes(payloadTyped.data as Iterable<OsmUID>);
      case _TaskType.GET_BARCODES_IN_BOUNDS:
        return await state.impl
            .getBarcodesWithin(payloadTyped.data as CoordsBounds);
      case _TaskType.GET_SHOPS_CONTAINING_BARCODES:
        final data = payloadTyped.data as Pair<CoordsBounds, Set<String>>;
        return await state.impl
            .getShopsContainingBarcodes(data.first, data.second);
      case _TaskType.GET_SHOPS:
        return await state.impl.getShops(payloadTyped.data as Iterable<OsmUID>);
      case _TaskType.ADD_BARCODES:
        return await state.impl
            .addBarcodes(payloadTyped.data as Map<OsmUID, List<String>>);
      case _TaskType.REMOVE_BARCODES:
        return await state.impl
            .removeBarcodes(payloadTyped.data as Map<OsmUID, List<String>>);
      case _TaskType.ADD_SHOPS:
        return await state.impl.addShops(payloadTyped.data as Iterable<Shop>);
      case _TaskType.CLEAR:
        return await state.impl.clear();
    }
  }
}

class _BackgroundIsolateState {
  final impl = ShopsLargeLocalCacheImpl();
  _BackgroundIsolateState();
}

enum _TaskType {
  GET_BARCODES,
  GET_BARCODES_IN_BOUNDS,
  GET_SHOPS_CONTAINING_BARCODES,
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
