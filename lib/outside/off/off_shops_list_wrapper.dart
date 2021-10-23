import 'dart:collection';

import 'package:plante/base/background/background_log_msg.dart';
import 'package:plante/base/background/background_worker.dart';
import 'package:plante/outside/off/off_shop.dart';

/// Wraps a list of [OffShop], executes operations with it in
/// a background isolate.
class OffShopsListWrapper extends BackgroundWorker<_BackgroundIsolateState> {
  final List<OffShop> _shops;

  List<OffShop> get shops => UnmodifiableListView(_shops);

  OffShopsListWrapper._(this._shops)
      : super('OffShopsListWrapper', _handleBackgroundWorkMessage);

  static Future<OffShopsListWrapper> create(List<OffShop> shops) async {
    final result = OffShopsListWrapper._(shops);
    final backgroundState = _BackgroundIsolateState(shops);
    await result.init(backgroundState);
    return result;
  }

  static dynamic _handleBackgroundWorkMessage(
      dynamic payload, _BackgroundIsolateState state, BackgroundLog log) {
    final payloadTyped = payload as _TaskPayload;
    switch (payloadTyped.type) {
      case _TaskType.FIND_APPROPRIATE_SHOPS:
        return _backgroundFindAppropriateShop(
            payloadTyped.data as Iterable<String>, state);
    }
  }

  Future<Map<String, OffShop>> findAppropriateShopsFor(
      Iterable<String> names) async {
    final stream =
        communicate(_TaskPayload(_TaskType.FIND_APPROPRIATE_SHOPS, names));
    return await stream.first as Map<String, OffShop>;
  }

  static Map<String, OffShop> _backgroundFindAppropriateShop(
      Iterable<String> names, _BackgroundIsolateState state) {
    final result = <String, OffShop>{};
    for (final name in names) {
      final possibleShopId = OffShop.shopNameToPossibleOffShopID(name);
      final found = state.shops.firstWhere((e) => e.id == possibleShopId,
          orElse: () => OffShop.empty);
      if (found != OffShop.empty) {
        result[name] = found;
      }
    }
    return result;
  }
}

class _BackgroundIsolateState {
  final List<OffShop> shops;
  _BackgroundIsolateState(this.shops);
}

enum _TaskType {
  FIND_APPROPRIATE_SHOPS,
}

class _TaskPayload {
  final _TaskType type;
  final dynamic data;
  _TaskPayload(this.type, this.data);
}
